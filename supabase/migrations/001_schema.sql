-- Ejecutar primero en Supabase SQL Editor. Todos los horarios son America/Lima.
begin;
create extension if not exists pgcrypto;

create table public.plans (
  id uuid primary key default gen_random_uuid(), name text not null, year integer not null unique,
  source_url text, created_at timestamptz not null default now()
);
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null check(length(full_name) >= 3), email text not null,
  cui text unique check(cui is null or cui ~ '^[0-9]{8}$'), phone text,
  role text not null default 'student' check(role in ('student','teacher','coordinator','admin')),
  plan_id uuid references public.plans(id), active boolean not null default true,
  approved_credits numeric not null default 0 check(approved_credits >= 0),
  created_at timestamptz not null default now()
);
create table public.courses (
  id uuid primary key default gen_random_uuid(), plan_id uuid not null references public.plans(id),
  code text not null, name text not null, semester integer not null check(semester between 1 and 10),
  credits numeric not null check(credits > 0), lab_hours numeric not null default 0 check(lab_hours >= 0),
  theory_hours numeric default 0 check(theory_hours >= 0), practice_hours numeric default 0 check(practice_hours >= 0),
  required_credits integer default 0 check(required_credits >= 0), elective boolean not null default false,
  component text, unique(plan_id,code)
);
create table public.prerequisites (
  id uuid primary key default gen_random_uuid(), course_id uuid not null references public.courses(id),
  required_course_id uuid not null references public.courses(id),
  check(course_id <> required_course_id), unique(course_id, required_course_id)
);
create table public.periods (
  id uuid primary key default gen_random_uuid(), name text not null unique,
  status text not null default 'draft' check(status in ('draft','open','closed')),
  enrollment_start timestamptz not null, enrollment_end timestamptz not null, withdrawal_end timestamptz not null,
  require_eligibility boolean not null default true,
  check(enrollment_start < enrollment_end), check(withdrawal_end >= enrollment_end)
);
create table public.rooms (
  id uuid primary key default gen_random_uuid(), name text not null unique,
  location text not null, equipment text, capacity integer not null check(capacity > 0), active boolean not null default true
);
create table public.groups (
  id uuid primary key default gen_random_uuid(), name text not null,
  course_id uuid not null references public.courses(id), period_id uuid not null references public.periods(id),
  room_id uuid not null references public.rooms(id), teacher_id uuid references public.profiles(id),
  capacity integer not null check(capacity > 0), active boolean not null default true,
  updated_at timestamptz not null default now(), unique(course_id,period_id,name)
);
create table public.sessions (
  id uuid primary key default gen_random_uuid(), group_id uuid not null references public.groups(id) on delete cascade,
  day integer not null check(day between 1 and 7), start_time time not null, end_time time not null,
  check(start_time < end_time), unique(group_id,day,start_time)
);
create table public.academic_records (
  id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id),
  course_id uuid not null references public.courses(id), grade numeric not null check(grade between 0 and 20),
  passed boolean not null default false, unique(student_id,course_id), check(passed = (grade >= 11))
);
create table public.eligibilities (
  id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id),
  course_id uuid not null references public.courses(id), period_id uuid not null references public.periods(id),
  enabled boolean not null default true, unique(student_id,course_id,period_id)
);
create table public.enrollments (
  id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id),
  group_id uuid not null references public.groups(id), course_id uuid not null references public.courses(id),
  period_id uuid not null references public.periods(id), status text not null default 'active' check(status in ('active','withdrawn')),
  created_at timestamptz not null default now(), withdrawn_at timestamptz
);
create unique index one_active_course on public.enrollments(student_id,course_id,period_id) where status = 'active';
create index enrollments_group_status on public.enrollments(group_id,status);
create table public.waitlist (
  id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id),
  group_id uuid not null references public.groups(id),
  status text not null default 'waiting' check(status in ('waiting','promoted','cancelled','skipped')),
  created_at timestamptz not null default now()
);
create unique index one_waiting_group on public.waitlist(student_id,group_id) where status = 'waiting';
create index waitlist_queue on public.waitlist(group_id,created_at,id) where status = 'waiting';
create table public.requests (
  id uuid primary key default gen_random_uuid(), student_id uuid not null default auth.uid() references public.profiles(id),
  type text not null check(type in ('schedule','capacity','exception','other')), subject text not null, body text not null,
  status text not null default 'pending' check(status in ('pending','approved','rejected','resolved')),
  response text, resolved_by uuid references public.profiles(id), created_at timestamptz not null default now(), resolved_at timestamptz
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(), student_id uuid not null references public.profiles(id),
  title text not null, body text not null, is_read boolean not null default false, created_at timestamptz not null default now()
);
create table public.announcements (
  id uuid primary key default gen_random_uuid(), title text not null, body text not null,
  group_id uuid references public.groups(id),
  created_by uuid default auth.uid() references public.profiles(id), created_at timestamptz not null default now()
);
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(), actor_id uuid, action text not null, table_name text not null,
  record_id uuid, old_data jsonb, new_data jsonb, created_at timestamptz not null default now()
);

create function public.is_active() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles where id = auth.uid() and active)
$$;
create function public.is_manager() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles where id = auth.uid() and active and role in ('admin','coordinator'))
$$;
create function public.is_admin() returns boolean language sql stable security definer set search_path = '' as $$
  select exists(select 1 from public.profiles where id = auth.uid() and active and role = 'admin')
$$;
create function public.teaches(p_group uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select public.is_active() and exists(select 1 from public.groups where id = p_group and teacher_id = auth.uid())
$$;

create function public.new_user_profile() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles(id,full_name,email,cui,plan_id)
  values(new.id, coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'),''),'Estudiante UNSA'), new.email,
    nullif(new.raw_user_meta_data->>'cui',''), (select id from public.plans where year = 2025));
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users for each row execute function public.new_user_profile();

create function public.protect_profile() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- SQL Editor (sin JWT) se utiliza únicamente para crear el primer administrador.
  if auth.uid() is not null then
    if new.id <> old.id or new.email <> old.email or new.created_at <> old.created_at then raise exception 'Datos de identidad protegidos'; end if;
    if new.role <> old.role and not public.is_admin() then raise exception 'Solo un administrador puede asignar roles'; end if;
    if old.role in ('admin','coordinator') and not public.is_admin() and new is distinct from old then raise exception 'Solo un administrador puede editar cuentas administrativas'; end if;
    if new.role <> 'teacher' and exists(select 1 from public.groups where teacher_id = old.id and active) then raise exception 'Reasigna los grupos antes de cambiar el rol docente'; end if;
    if not public.is_manager() and (new.cui is distinct from old.cui or new.plan_id is distinct from old.plan_id or new.active <> old.active or new.approved_credits <> old.approved_credits) then
      raise exception 'Los datos académicos requieren coordinación';
    end if;
    if old.id = auth.uid() and old.role = 'admin' and (new.role <> 'admin' or not new.active) then raise exception 'No puedes quitarte tus propios permisos administrativos'; end if;
  end if;
  return new;
end $$;
create trigger protect_profile_update before update on public.profiles for each row execute function public.protect_profile();

create function public.audit_change() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.audit_logs(actor_id,action,table_name,record_id,old_data,new_data)
  values(auth.uid(),tg_op,tg_table_name,coalesce(new.id,old.id),case when tg_op <> 'INSERT' then to_jsonb(old) end,case when tg_op <> 'DELETE' then to_jsonb(new) end);
  return coalesce(new,old);
end $$;

-- Serializa cambios de oferta y matrícula de cada periodo; evita carreras de vacantes y horarios.
create function public.lock_period(p_id uuid) returns void language sql set search_path = '' as $$
  select pg_advisory_xact_lock(hashtextextended(p_id::text,0))
$$;
create function public.guard_group() returns trigger language plpgsql security definer set search_path = '' as $$
declare r public.rooms; n integer;
begin
  perform public.lock_period(new.period_id);
  select * into r from public.rooms where id = new.room_id for share;
  if new.capacity > r.capacity or (new.active and not r.active) then raise exception 'La capacidad o disponibilidad del ambiente no permite publicar este grupo'; end if;
  if not exists(select 1 from public.courses where id = new.course_id and lab_hours > 0) then raise exception 'La asignatura no tiene horas de laboratorio'; end if;
  if new.teacher_id is not null and not exists(select 1 from public.profiles where id = new.teacher_id and role = 'teacher' and active) then raise exception 'Selecciona un docente activo'; end if;
  select count(*) into n from public.enrollments where group_id = new.id and status = 'active';
  if new.capacity < n then raise exception 'Las vacantes no pueden ser menores a la matrícula actual'; end if;
  if tg_op = 'UPDATE' and n > 0 and (new.course_id <> old.course_id or new.period_id <> old.period_id or new.room_id <> old.room_id or new.teacher_id is distinct from old.teacher_id or new.active <> old.active) then
    raise exception 'Retira o reubica las matrículas antes de modificar este grupo';
  end if;
  if new.active and exists (
    select 1 from public.sessions a join public.sessions b on a.day = b.day and a.start_time < b.end_time and a.end_time > b.start_time
    join public.groups g on g.id = b.group_id
    where a.group_id = new.id and g.id <> new.id and g.active and g.period_id = new.period_id
      and (g.room_id = new.room_id or (new.teacher_id is not null and g.teacher_id = new.teacher_id))
  ) then raise exception 'El ambiente o docente tiene un cruce de horario'; end if;
  return new;
end $$;
create trigger validate_group before insert or update on public.groups for each row execute function public.guard_group();

create function public.guard_session() returns trigger language plpgsql security definer set search_path = '' as $$
declare g public.groups; old_group public.groups;
begin
  if tg_op = 'DELETE' then select * into g from public.groups where id = old.group_id;
  else select * into g from public.groups where id = new.group_id; end if;
  if g.id is null then return coalesce(new,old); end if;
  perform public.lock_period(g.period_id);
  if tg_op = 'UPDATE' and new.group_id <> old.group_id then raise exception 'Elimina y recrea la sesión para cambiar de grupo'; end if;
  if exists(select 1 from public.enrollments where group_id = g.id and status = 'active') then raise exception 'No se puede cambiar el horario de un grupo con matrículas activas'; end if;
  if tg_op <> 'DELETE' then
    if exists(select 1 from public.sessions s join public.groups other on s.group_id = other.id
      where s.id <> new.id and other.period_id = g.period_id and s.day = new.day
        and s.start_time < new.end_time and s.end_time > new.start_time
        and (other.id = g.id or (g.active and other.active and (other.room_id = g.room_id or (g.teacher_id is not null and other.teacher_id = g.teacher_id)))))
    then raise exception 'Existe un cruce de horario de grupo, ambiente o docente'; end if;
  end if;
  return coalesce(new,old);
end $$;
create trigger validate_session before insert or update or delete on public.sessions for each row execute function public.guard_session();

create function public.guard_room() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if exists(select 1 from public.groups where room_id = new.id and active and (capacity > new.capacity or not new.active)) then
    raise exception 'Hay grupos publicados que dependen de la capacidad y disponibilidad de este ambiente';
  end if;
  return new;
end $$;
create trigger validate_room before update on public.rooms for each row execute function public.guard_room();

create function public.recompute_credits() returns trigger language plpgsql security definer set search_path = '' as $$
declare target uuid;
begin
  if tg_op = 'UPDATE' and new.student_id <> old.student_id then raise exception 'El estudiante de un registro no puede modificarse'; end if;
  target := coalesce(new.student_id, old.student_id);
  update public.profiles set approved_credits = coalesce((select sum(c.credits) from public.academic_records a join public.courses c on c.id = a.course_id where a.student_id = target and a.passed),0) where id = target;
  return coalesce(new,old);
end $$;
create trigger academic_credits after insert or update or delete on public.academic_records for each row execute function public.recompute_credits();

-- RLS: ninguna matrícula ni cola se escribe directamente desde el navegador.
do $$ declare t text; begin
  foreach t in array array['plans','profiles','courses','prerequisites','periods','rooms','groups','sessions','academic_records','eligibilities','enrollments','waitlist','requests','notifications','announcements','audit_logs'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
    execute format('grant select on public.%I to authenticated', t);
  end loop;
  foreach t in array array['plans','courses','prerequisites','periods','rooms','groups','sessions','announcements','academic_records','eligibilities'] loop
    execute format('grant insert,update,delete on public.%I to authenticated',t);
    execute format('create policy manager_write on public.%I for all to authenticated using(public.is_manager()) with check(public.is_manager())',t);
  end loop;
  foreach t in array array['plans','courses','prerequisites','periods','rooms'] loop
    execute format('create policy authenticated_read on public.%I for select to authenticated using(public.is_active())', t);
  end loop;
end $$;
create policy profile_read on public.profiles for select to authenticated using(id = auth.uid() or public.is_manager() or (public.is_active() and exists(select 1 from public.enrollments e where e.student_id = profiles.id and public.teaches(e.group_id))));
grant update(full_name,phone,cui,plan_id,active) on public.profiles to authenticated;
create policy profile_update on public.profiles for update to authenticated using(id = auth.uid() or public.is_manager()) with check(id = auth.uid() or public.is_manager());
create policy group_read on public.groups for select to authenticated using(public.is_active() and (active or public.is_manager() or teacher_id = auth.uid()));
create policy session_read on public.sessions for select to authenticated using(public.is_active());
create policy academic_read on public.academic_records for select to authenticated using(public.is_active() and student_id = auth.uid());
create policy eligibility_read on public.eligibilities for select to authenticated using(public.is_active() and student_id = auth.uid());
create policy enrollment_read on public.enrollments for select to authenticated using(public.is_active() and (student_id = auth.uid() or public.is_manager() or public.teaches(group_id)));
create policy waitlist_read on public.waitlist for select to authenticated using(public.is_active() and (student_id = auth.uid() or public.is_manager() or public.teaches(group_id)));
create policy request_read on public.requests for select to authenticated using(public.is_active() and (student_id = auth.uid() or public.is_manager()));
grant insert on public.requests to authenticated;
create policy request_insert on public.requests for insert to authenticated with check(public.is_active() and student_id = auth.uid() and status = 'pending' and response is null and resolved_by is null and resolved_at is null);
create policy notification_read on public.notifications for select to authenticated using(public.is_active() and student_id = auth.uid());
grant update(is_read) on public.notifications to authenticated;
create policy notification_update on public.notifications for update to authenticated using(public.is_active() and student_id = auth.uid()) with check(student_id = auth.uid());
create policy audit_read on public.audit_logs for select to authenticated using(public.is_manager());
create policy announcement_read on public.announcements for select to authenticated using(public.is_active() and (group_id is null or public.is_manager() or public.teaches(group_id) or exists(select 1 from public.enrollments e where e.group_id = announcements.group_id and e.student_id = auth.uid() and e.status = 'active')));
create policy teacher_announcement_insert on public.announcements for insert to authenticated with check(public.teaches(group_id) and created_by = auth.uid());
create policy teacher_announcement_update on public.announcements for update to authenticated using(public.teaches(group_id) and created_by = auth.uid()) with check(public.teaches(group_id) and created_by = auth.uid());
create policy teacher_announcement_delete on public.announcements for delete to authenticated using(public.teaches(group_id) and created_by = auth.uid());

do $$ declare t text; begin
  foreach t in array array['profiles','plans','courses','prerequisites','periods','rooms','groups','sessions','academic_records','eligibilities','enrollments','waitlist','requests','announcements'] loop
    execute format('create trigger audit_%I after insert or update or delete on public.%I for each row execute function public.audit_change()',t,t);
  end loop;
end $$;

-- Revocar EXECUTE por defecto; solo se exponen las funciones públicas necesarias.
revoke execute on all functions in schema public from public, anon, authenticated;
grant execute on function public.is_active(),public.is_manager(),public.is_admin(),public.teaches(uuid) to authenticated;
commit;
