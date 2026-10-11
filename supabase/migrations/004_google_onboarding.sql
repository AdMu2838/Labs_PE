-- Permite a usuarios nuevos (por ejemplo Google OAuth) asignar su CUI una sola vez.
begin;
create or replace function public.new_user_profile() returns trigger language plpgsql security definer set search_path = '' as $$
declare student_name text;
begin
  student_name := coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'),''),nullif(trim(new.raw_user_meta_data->>'name'),''),'Estudiante UNSA');
  if length(student_name) < 3 then student_name := 'Estudiante UNSA'; end if;
  insert into public.profiles(id,full_name,email,cui,plan_id)
  values(new.id,student_name,new.email,nullif(new.raw_user_meta_data->>'cui',''),(select id from public.plans where year = 2025));
  return new;
end $$;

create or replace function public.protect_profile() returns trigger language plpgsql security definer set search_path = '' as $$
declare first_cui boolean;
begin
  if auth.uid() is not null then
    first_cui := old.id = auth.uid() and old.role = 'student' and old.cui is null and coalesce(new.cui ~ '^[0-9]{8}$',false);
    if new.id <> old.id or new.email <> old.email or new.created_at <> old.created_at then raise exception 'Datos de identidad protegidos'; end if;
    if new.role <> old.role and not public.is_admin() then raise exception 'Solo un administrador puede asignar roles'; end if;
    if old.role in ('admin','coordinator') and not public.is_admin() and new is distinct from old then raise exception 'Solo un administrador puede editar cuentas administrativas'; end if;
    if new.role <> 'teacher' and exists(select 1 from public.groups where teacher_id = old.id and active) then raise exception 'Reasigna los grupos antes de cambiar el rol docente'; end if;
    if not public.is_manager() and ((new.cui is distinct from old.cui and not first_cui) or new.plan_id is distinct from old.plan_id or new.active <> old.active or new.approved_credits <> old.approved_credits) then
      raise exception 'Los datos académicos requieren coordinación';
    end if;
    if old.id = auth.uid() and old.role = 'admin' and (new.role <> 'admin' or not new.active) then raise exception 'No puedes quitarte tus propios permisos administrativos'; end if;
  end if;
  return new;
end $$;

create or replace function public.validate_enrollment(p_student uuid,p_group uuid,p_replacing uuid default null) returns void
language plpgsql security definer set search_path = '' as $$
declare g public.groups; p public.periods; s public.profiles; c public.courses;
begin
  select * into g from public.groups where id = p_group;
  select * into p from public.periods where id = g.period_id;
  select * into s from public.profiles where id = p_student;
  select * into c from public.courses where id = g.course_id;
  if g.id is null or not g.active then raise exception 'Grupo no disponible'; end if;
  if s.id is null or not s.active or s.role <> 'student' then raise exception 'Solo estudiantes activos pueden matricularse'; end if;
  if s.cui is null then raise exception 'Completa tu CUI antes de matricularte'; end if;
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
revoke execute on function public.new_user_profile(),public.protect_profile(),public.validate_enrollment(uuid,uuid,uuid) from public,anon,authenticated;
commit;
