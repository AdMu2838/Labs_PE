insert into auth.users(id,email,raw_user_meta_data) values
('10000000-0000-4000-8000-000000000001','admin@example.test','{"full_name":"Admin Prueba","cui":"20250001"}'),
('10000000-0000-4000-8000-000000000002','uno@example.test','{"full_name":"Estudiante Uno","cui":"20250002"}'),
('10000000-0000-4000-8000-000000000003','dos@example.test','{"full_name":"Estudiante Dos","cui":"20250003"}');
update public.profiles set role = 'admin' where cui = '20250001';
insert into public.periods(id,name,status,enrollment_start,enrollment_end,withdrawal_end,require_eligibility)
values('20000000-0000-4000-8000-000000000001','TEST','open',now()-interval '1 day',now()+interval '1 day',now()+interval '2 days',false);
insert into public.rooms(id,name,location,capacity) values
('30000000-0000-4000-8000-000000000001','Prueba 1','Prueba',3),
('30000000-0000-4000-8000-000000000002','Prueba 2','Prueba',3);
insert into public.groups(id,name,course_id,period_id,room_id,capacity)
select '40000000-0000-4000-8000-000000000001','A',id,'20000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001',1 from public.courses where code = '2501103';
insert into public.groups(id,name,course_id,period_id,room_id,capacity)
select '40000000-0000-4000-8000-000000000002','B',id,'20000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000002',1 from public.courses where code = '2501103';
insert into public.sessions(group_id,day,start_time,end_time) values
('40000000-0000-4000-8000-000000000001',1,'08:00','10:00'),
('40000000-0000-4000-8000-000000000002',2,'08:00','10:00');
insert into public.groups(id,name,course_id,period_id,room_id,capacity)
select '40000000-0000-4000-8000-000000000003','Cruce',id,'20000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000002',2 from public.courses where code = '2501210';
insert into public.sessions(group_id,day,start_time,end_time) values('40000000-0000-4000-8000-000000000003',1,'09:00','11:00');
