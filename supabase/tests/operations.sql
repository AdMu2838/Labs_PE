-- Pruebas con rol authenticated y JWT simulado. Se revierte todo al terminar.
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
do $$ declare n int; begin
  select count(*) into n from public.profiles;
  if n <> 1 then raise exception 'RLS expone perfiles ajenos'; end if;
  begin
    update public.profiles set active = false where id = auth.uid();
    raise exception 'TEST_FAIL: estudiante modificó su situación';
  exception when raise_exception then
    if sqlerrm like 'TEST_FAIL:%' then raise; end if;
  end;
  begin
    perform public.set_user_role(auth.uid(),'admin');
    raise exception 'TEST_FAIL: escalamiento de rol';
  exception when raise_exception then
    if sqlerrm like 'TEST_FAIL:%' then raise; end if;
  end;
  begin
    insert into public.enrollments(student_id,group_id,course_id,period_id)
    select auth.uid(),'40000000-0000-4000-8000-000000000001',id,'20000000-0000-4000-8000-000000000001' from public.courses where code = '2501103';
    raise exception 'TEST_FAIL: escritura directa permitida';
  exception when insufficient_privilege then null;
  end;
end $$;
select public.enroll_lab('40000000-0000-4000-8000-000000000001');
do $$ begin
  begin
    perform public.enroll_lab('40000000-0000-4000-8000-000000000003');
    raise exception 'TEST_FAIL: cruce permitido';
  exception when raise_exception then
    if sqlerrm not like '%se cruza%' then raise; end if;
  end;
end $$;
do $$ begin
  begin
    perform public.enroll_lab('40000000-0000-4000-8000-000000000001');
    raise exception 'TEST_FAIL: duplicado permitido';
  exception when raise_exception then
    if sqlerrm like 'TEST_FAIL:%' then raise; end if;
  end;
end $$;

select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',true);
select public.enroll_lab('40000000-0000-4000-8000-000000000002');
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
do $$ declare origin uuid; begin
  select id into origin from public.enrollments where student_id = auth.uid() and status = 'active';
  begin
    perform public.enroll_lab('40000000-0000-4000-8000-000000000002',false,origin);
    raise exception 'TEST_FAIL: cambio a grupo lleno permitido';
  exception when raise_exception then
    if sqlerrm like 'TEST_FAIL:%' then raise; end if;
  end;
  if not exists(select 1 from public.enrollments where id = origin and status = 'active') then raise exception 'Cambio fallido eliminó matrícula original'; end if;
end $$;
-- Liberar B, cambiar A -> B; después estudiante dos entra en cola de B.
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',true);
select public.withdraw_lab(id) from public.enrollments where student_id = auth.uid() and status = 'active';
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
select public.enroll_lab('40000000-0000-4000-8000-000000000002',false,id) from public.enrollments where status = 'active' and student_id = auth.uid();
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',true);
select public.enroll_lab('40000000-0000-4000-8000-000000000002',true);
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
select public.withdraw_lab(id) from public.enrollments where student_id = auth.uid() and status = 'active';
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000003',true);
do $$ begin
  if not exists(select 1 from public.enrollments where student_id = auth.uid() and status = 'active' and group_id = '40000000-0000-4000-8000-000000000002') then raise exception 'La cola no promovió al estudiante'; end if;
end $$;
reset role;
rollback;

-- Requisitos y periodo cerrado, antes de tener matrículas.
begin;
update public.periods set require_eligibility = true where name = 'TEST';
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
do $$ begin
  begin
    perform public.enroll_lab('40000000-0000-4000-8000-000000000001');
    raise exception 'TEST_FAIL: habilitación ignorada';
  exception when raise_exception then
    if sqlerrm not like '%habilitado%' then raise; end if;
  end;
end $$;
reset role;
insert into public.eligibilities(student_id,course_id,period_id)
select '10000000-0000-4000-8000-000000000002',id,'20000000-0000-4000-8000-000000000001' from public.courses where code = '2501210';
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
do $$ begin
  begin
    perform public.enroll_lab('40000000-0000-4000-8000-000000000003');
    raise exception 'TEST_FAIL: prerrequisito ignorado';
  exception when raise_exception then
    if sqlerrm not like '%prerrequisitos%' then raise; end if;
  end;
end $$;
reset role;
-- El administrador importa una aprobación; el total de créditos se recalcula.
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
select public.import_academic('[{"cui":"20250002","course_code":"2501103","grade":"16"}]','academic_records');
do $$ begin
  if (select approved_credits from public.profiles where cui = '20250002') <> 5 then raise exception 'Créditos incorrectos'; end if;
end $$;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000002',true);
select public.enroll_lab('40000000-0000-4000-8000-000000000003');
reset role;
rollback;
