begin;
create function public.validate_enrollment(p_student uuid,p_group uuid,p_replacing uuid default null) returns void
language plpgsql security definer set search_path = '' as $$
declare g public.groups; p public.periods; s public.profiles; c public.courses;
begin
  select * into g from public.groups where id = p_group;
  select * into p from public.periods where id = g.period_id;
  select * into s from public.profiles where id = p_student;
  select * into c from public.courses where id = g.course_id;
  if g.id is null or not g.active then raise exception 'Grupo no disponible'; end if;
  if s.id is null or not s.active or s.role <> 'student' then raise exception 'Solo estudiantes activos pueden matricularse'; end if;
  if p.status <> 'open' or now() < p.enrollment_start or now() > p.enrollment_end then raise exception 'El periodo de matrícula está cerrado'; end if;
  if not exists(select 1 from public.sessions where group_id = g.id) then raise exception 'El grupo aún no tiene horario'; end if;
  if c.plan_id is distinct from s.plan_id then raise exception 'El curso no pertenece a tu plan de estudios'; end if;
  if p_replacing is not null and not exists(select 1 from public.enrollments where id = p_replacing and student_id = p_student and status = 'active' and course_id = g.course_id and period_id = g.period_id and group_id <> g.id) then raise exception 'Matrícula de origen inválida'; end if;
  if p_replacing is not null and now() > p.withdrawal_end then raise exception 'El plazo de cambios terminó'; end if;
  if exists(select 1 from public.enrollments where student_id = p_student and course_id = g.course_id and period_id = g.period_id and status = 'active' and (p_replacing is null or id <> p_replacing)) then raise exception 'Ya tienes una matrícula activa en este curso'; end if;
  if p.require_eligibility then
    if not exists(select 1 from public.eligibilities where student_id = p_student and course_id = g.course_id and period_id = g.period_id and enabled) then raise exception 'Coordinación no ha habilitado tu matrícula teórica en este curso'; end if;
    if exists(select 1 from public.prerequisites pr where pr.course_id = g.course_id and not exists(select 1 from public.academic_records a where a.student_id = p_student and a.course_id = pr.required_course_id and a.passed)) then raise exception 'No cumples los prerrequisitos verificados'; end if;
    if s.approved_credits < coalesce(c.required_credits,0) then raise exception 'No cumples el mínimo de créditos aprobados'; end if;
  end if;
  if exists(select 1 from public.enrollments e join public.sessions a on a.group_id = e.group_id join public.sessions b on b.group_id = g.id
    where e.student_id = p_student and e.status = 'active' and e.period_id = g.period_id and (p_replacing is null or e.id <> p_replacing)
      and a.day = b.day and a.start_time < b.end_time and a.end_time > b.start_time) then raise exception 'El laboratorio se cruza con tu horario actual'; end if;
end $$;

create function public.promote_queue(p_group uuid) returns void language plpgsql security definer set search_path = '' as $$
declare g public.groups; w public.waitlist; reason text;
begin
  select * into g from public.groups where id = p_group;
  perform public.lock_period(g.period_id);
  if not exists(select 1 from public.periods where id = g.period_id and status = 'open' and now() between enrollment_start and enrollment_end) then return; end if;
  for w in select * from public.waitlist where group_id = p_group and status = 'waiting' order by created_at,id loop
    exit when (select count(*) from public.enrollments where group_id = p_group and status = 'active') >= g.capacity;
    begin
      perform public.validate_enrollment(w.student_id,p_group);
      insert into public.enrollments(student_id,group_id,course_id,period_id) values(w.student_id,g.id,g.course_id,g.period_id);
      update public.waitlist set status = 'promoted' where id = w.id;
      insert into public.notifications(student_id,title,body) values(w.student_id,'Vacante asignada','Tu matrícula fue confirmada desde la lista de espera. Consulta tu horario.');
    exception when raise_exception then
      get stacked diagnostics reason = message_text;
      update public.waitlist set status = 'skipped' where id = w.id;
      insert into public.notifications(student_id,title,body) values(w.student_id,'Lista de espera: atención requerida',reason || '. Vuelve a solicitar un grupo después de regularizar tu situación.');
    end;
  end loop;
  update public.groups set updated_at = now() where id = p_group;
end $$;

create function public.enroll_lab(p_group uuid,p_waitlist boolean default false,p_replacing uuid default null) returns text
language plpgsql security definer set search_path = '' as $$
declare g public.groups; old_group uuid; student uuid := auth.uid();
begin
  if student is null then raise exception 'Inicia sesión'; end if;
  select * into g from public.groups where id = p_group;
  if g.id is null then raise exception 'Grupo no encontrado'; end if;
  perform public.lock_period(g.period_id);
  select * into g from public.groups where id = p_group;
  perform public.validate_enrollment(student,p_group,p_replacing);
  -- No permite adelantarse a estudiantes que ya están en cola.
  perform public.promote_queue(p_group);
  if p_replacing is null and exists(select 1 from public.enrollments where student_id = student and group_id = p_group and status = 'active') then return 'enrolled'; end if;
  perform public.validate_enrollment(student,p_group,p_replacing);
  if (select count(*) from public.enrollments where group_id = p_group and status = 'active') >= g.capacity then
    if not p_waitlist or p_replacing is not null then raise exception 'El grupo no tiene vacantes'; end if;
    if exists(select 1 from public.waitlist where student_id = student and group_id = p_group and status = 'waiting') then raise exception 'Ya estás en esta lista de espera'; end if;
    insert into public.waitlist(student_id,group_id) values(student,p_group);
    insert into public.notifications(student_id,title,body) values(student,'Lista de espera registrada','Te avisaremos si se libera una vacante y cumples los requisitos.');
    return 'waiting';
  end if;
  if p_replacing is not null then
    update public.enrollments set status = 'withdrawn',withdrawn_at = now() where id = p_replacing returning group_id into old_group;
  end if;
  insert into public.enrollments(student_id,group_id,course_id,period_id) values(student,g.id,g.course_id,g.period_id);
  update public.waitlist set status = 'cancelled' where student_id = student and status = 'waiting' and group_id in(select id from public.groups where course_id = g.course_id and period_id = g.period_id);
  update public.groups set updated_at = now() where id = g.id;
  if old_group is not null then perform public.promote_queue(old_group); end if;
  insert into public.notifications(student_id,title,body) values(student,'Matrícula confirmada','Se confirmó tu matrícula en ' || g.name || '. Consulta tus matrículas y descarga tu constancia.');
  return 'enrolled';
end $$;

create function public.withdraw_lab(p_enrollment uuid) returns void language plpgsql security definer set search_path = '' as $$
declare e public.enrollments; p public.periods;
begin
  select * into e from public.enrollments where id = p_enrollment;
  if e.id is null or e.student_id <> auth.uid() or not public.is_active() then raise exception 'No tienes permiso para retirar esta matrícula'; end if;
  perform public.lock_period(e.period_id);
  select * into e from public.enrollments where id = p_enrollment;
  select * into p from public.periods where id = e.period_id;
  if e.status <> 'active' then raise exception 'La matrícula ya está retirada'; end if;
  if p.status <> 'open' or now() < p.enrollment_start or now() > p.withdrawal_end then raise exception 'El plazo de retiros está cerrado'; end if;
  update public.enrollments set status = 'withdrawn',withdrawn_at = now() where id = e.id;
  perform public.promote_queue(e.group_id);
  insert into public.notifications(student_id,title,body) values(e.student_id,'Retiro registrado','Tu retiro de laboratorio se registró correctamente.');
end $$;

create function public.leave_waitlist(p_id uuid) returns void language plpgsql security definer set search_path = '' as $$
declare w public.waitlist; period uuid;
begin
  select * into w from public.waitlist where id = p_id;
  if w.id is null or w.student_id <> auth.uid() or not public.is_active() then raise exception 'No tienes permiso'; end if;
  select period_id into period from public.groups where id = w.group_id;
  perform public.lock_period(period);
  update public.waitlist set status = 'cancelled' where id = p_id and status = 'waiting';
end $$;

create function public.resolve_request(p_id uuid,p_status text,p_response text) returns void language plpgsql security definer set search_path = '' as $$
declare student uuid;
begin
  if not public.is_manager() then raise exception 'Requiere coordinación'; end if;
  if p_status not in ('approved','rejected','resolved') or length(trim(p_response)) < 1 then raise exception 'Respuesta inválida'; end if;
  update public.requests set status = p_status,response = p_response,resolved_by = auth.uid(),resolved_at = now() where id = p_id and status = 'pending' returning student_id into student;
  if student is null then raise exception 'Solicitud no encontrada o ya atendida'; end if;
  insert into public.notifications(student_id,title,body) values(student,'Tu solicitud fue atendida',p_response);
end $$;

create function public.set_user_role(p_user uuid,p_role text) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_admin() then raise exception 'Solo un administrador puede cambiar roles'; end if;
  if p_role not in ('student','teacher','coordinator','admin') then raise exception 'Rol inválido'; end if;
  update public.profiles set role = p_role where id = p_user;
  if not found then raise exception 'Usuario no encontrado'; end if;
end $$;

create function public.list_groups() returns jsonb language plpgsql stable security definer set search_path = '' as $$
begin
  if not public.is_active() then raise exception 'Se requiere una cuenta activa'; end if;
  return coalesce((select jsonb_agg(result order by result->>'course_code',result->>'name') from (
    select jsonb_build_object('id',g.id,'name',g.name,'course_id',g.course_id,'period_id',g.period_id,'capacity',g.capacity,
      'course_name',c.name,'course_code',c.code,'semester',c.semester,'period_name',p.name,'room_name',r.name,'teacher_name',t.full_name,'teacher_id',g.teacher_id,
      'occupied',(select count(*) from public.enrollments e where e.group_id = g.id and e.status = 'active'),
      'sessions',coalesce((select jsonb_agg(jsonb_build_object('day',s.day,'start_time',s.start_time,'end_time',s.end_time) order by s.day,s.start_time) from public.sessions s where s.group_id = g.id),'[]'::jsonb)) result
    from public.groups g join public.courses c on c.id = g.course_id join public.periods p on p.id = g.period_id join public.rooms r on r.id = g.room_id left join public.profiles t on t.id = g.teacher_id
    where public.is_manager() or (g.active and p.status <> 'draft') or g.teacher_id = auth.uid()
      or exists(select 1 from public.enrollments e where e.group_id = g.id and e.student_id = auth.uid())
  ) items),'[]'::jsonb);
end $$;

create function public.import_academic(p_rows jsonb,p_kind text) returns void language plpgsql security definer set search_path = '' as $$
declare item jsonb; student public.profiles; course public.courses; period uuid; grade numeric;
begin
  if not public.is_manager() then raise exception 'Requiere coordinación'; end if;
  if jsonb_typeof(p_rows) <> 'array' or jsonb_array_length(p_rows) > 500 or p_kind not in ('eligibilities','academic_records') then raise exception 'Lote inválido'; end if;
  for item in select * from jsonb_array_elements(p_rows) loop
    select * into student from public.profiles where cui = item->>'cui' and role = 'student';
    if student.id is null then raise exception 'CUI no encontrado: %',item->>'cui'; end if;
    select * into course from public.courses where code = item->>'course_code' and plan_id = student.plan_id;
    if course.id is null then raise exception 'Código no encontrado en el plan del estudiante: %',item->>'course_code'; end if;
    if p_kind = 'eligibilities' then
      select id into period from public.periods where name = item->>'period_name';
      if period is null then raise exception 'Periodo no encontrado: %',item->>'period_name'; end if;
      insert into public.eligibilities(student_id,course_id,period_id,enabled) values(student.id,course.id,period,true)
        on conflict(student_id,course_id,period_id) do update set enabled = true;
    else
      grade := (item->>'grade')::numeric;
      insert into public.academic_records(student_id,course_id,grade,passed) values(student.id,course.id,grade,grade >= 11)
        on conflict(student_id,course_id) do update set grade = excluded.grade,passed = excluded.passed;
    end if;
  end loop;
end $$;

create function public.capacity_queue() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.capacity > old.capacity then perform public.promote_queue(new.id); end if;
  return new;
end $$;
create trigger capacity_promotions after update of capacity on public.groups for each row execute function public.capacity_queue();

revoke execute on all functions in schema public from public,anon,authenticated;
grant execute on function public.is_active(),public.is_manager(),public.is_admin(),public.teaches(uuid),
  public.list_groups(),public.enroll_lab(uuid,boolean,uuid),public.withdraw_lab(uuid),public.leave_waitlist(uuid),
  public.resolve_request(uuid,text,text),public.set_user_role(uuid,text),public.import_academic(jsonb,text) to authenticated;

-- Solo eventos visibles según RLS. El recuento agregado se consulta con list_groups().
alter publication supabase_realtime add table public.groups,public.enrollments,public.notifications;
commit;
