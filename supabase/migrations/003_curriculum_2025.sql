-- Fuente: PDF oficial EPIS, plan vigente 2025 (exportación SAA 08/07/2026).
-- https://fips.unsa.edu.pe/ingenieriadesistemas/wp-content/uploads/sites/2/2026/08/epis-plan-de-estudios-2025.pdf
-- 87 códigos; 302 créditos codificados, 238 curriculares para egresar y 4 extracurriculares.
-- Los créditos codificados incluyen todas las alternativas electivas; no son la carga del estudiante.
begin;
insert into public.plans(id,name,year,source_url) values
 ('20250000-0000-4000-8000-000000000001','Plan de estudios 2025',2025,'https://fips.unsa.edu.pe/ingenieriadesistemas/wp-content/uploads/sites/2/2026/08/epis-plan-de-estudios-2025.pdf');

create temporary table curriculum_seed (
 code text, name text, semester int, credits int, theory_hours int, practice_hours int,
 lab_hours int, required_credits int, component text, prerequisites text
) on commit drop;
insert into curriculum_seed values
('2501101','Álgebra Lineal',1,4,3,2,0,0,'D',''),
('2501102','Estructuras Discretas I',1,4,2,4,0,0,'F',''),
('2501103','Introducción al Desarrollo de Software',1,5,2,2,4,0,'F',''),
('2501104','Introducción a la Ingeniería',1,3,2,2,0,0,'D',''),
('2501105','Relaciones Humanas en Empresas de Desarrollo de Software y Base Tecnológica',1,2,1,2,0,0,'E',''),
('2501106','Metodología del Trabajo Académico',1,2,0,4,0,0,'D',''),
('2501107','Matemática Básica',1,4,3,2,0,0,'D',''),
('2501208','Cálculo en una Variable',2,5,3,4,0,0,'D','2501101,2501107'),
('2501209','Estructuras Discretas II',2,3,2,2,0,0,'F','2501102'),
('2501210','Introducción al Desarrollo Web',2,4,2,0,4,0,'F','2501103'),
('2501211','Desarrollo de Software Orientado a Objetos',2,4,2,2,2,0,'F','2501103'),
('2501212','Lingüística, Comprensión y Redacción Académica',2,3,1,4,0,0,'D',''),
('2501213','Realidad Nacional',2,2,1,2,0,0,'E',''),
('2501214','Taller de Narrativa Digital',2,3,1,2,2,0,'G',''),
('2502115','Cálculo en Varias Variables',3,5,3,4,0,0,'D','2501208'),
('2502116','Estructura de Datos y Algoritmos',3,4,2,2,2,0,'F','2501209,2501211'),
('2502117','Desarrollo de Aplicaciones Web',3,4,2,0,4,0,'F','2501211,2501210'),
('2502118','Enfoque Empresarial',3,3,2,2,0,0,'F','2501105'),
('2502119','Desarrollo Emocional, Gestión de Conflictos y Liderazgo',3,2,2,0,0,0,'E','2501105'),
('2502120','Inglés',3,2,1,2,0,0,'D',''),
('2502121','Ciudadanía e Interculturalidad',3,2,1,2,0,0,'E',''),
('2502122','Taller de Internet de las Cosas',3,2,1,0,2,0,'G',''),
('2502223','Estadística Matemática, Probabilidades y Métodos Empíricos',4,4,2,2,2,0,'D','2502115'),
('2502224','Arquitectura de Computadoras',4,3,1,2,2,0,'F','2502116'),
('2502225','Análisis y Diseño de Algoritmos',4,4,2,2,2,0,'F','2502116'),
('2502226','Interacción Humano Computador',4,3,1,2,2,0,'F','2502117'),
('2502227','Organización y Métodos',4,3,2,2,0,0,'F','2502118'),
('2502228','Ecología y Conservación Ambiental',4,3,2,2,0,0,'E',''),
('2502229','Políticas Públicas y Anticorrupción',4,2,1,2,0,0,'E',''),
('2503130','Investigación de Operaciones',5,3,1,2,2,0,'F','2502115'),
('2503131','Redes y Comunicación de Datos',5,4,2,2,2,0,'F','2502224'),
('2503132','Tópicos Avanzados de la Interacción Humano Computador',5,3,1,2,2,0,'F','2502226'),
('2503133','Procesos de Desarrollo e Ingeniería de Software',5,4,2,4,0,0,'F','2502225'),
('2503134','Sistemas de Información',5,3,2,2,0,0,'F','2502227'),
('2503135','Taller de Innovación, Creatividad y Emprendimiento',5,2,1,2,0,0,'E','2502119'),
('2503136','Metodología de la Investigación Científica en Sistemas',5,2,1,2,0,0,'F',''),
('2503137','Taller de Simulación en Lego',5,3,1,2,2,0,'G',''),
('2503238','Métodos Numéricos',6,4,2,2,2,0,'F','2503130'),
('2503239','Sistemas Operativos',6,4,2,2,2,0,'F','2502224'),
('2503240','Tecnologías de Objetos',6,4,2,2,2,0,'F','2503133'),
('2503241','Ingeniería de Requerimientos',6,3,2,2,0,0,'F','2503133'),
('2503242','Base de Datos',6,4,2,2,2,0,'F','2503134'),
('2503243','Taller de Business Analytics',6,3,1,2,2,0,'G',''),
('2503244','Redacción de Artículos e Informes de Investigación',6,2,1,2,0,0,'F','2501212'),
('2504145','Física Computacional',7,3,2,0,2,0,'G','2503238'),
('2504146','Inteligencia Artificial',7,4,2,2,2,0,'F','2502223'),
('2504147','Seguridad Informática',7,3,1,2,2,0,'F','2503131'),
('2504148','Sistemas Distribuidos y Paralelos',7,4,2,2,2,0,'F','2503239'),
('2504149','Diseño y Arquitectura de Software',7,3,2,2,0,0,'F','2503241'),
('2504150','Calidad y Pruebas de Software',7,3,2,0,2,0,'F','2503241'),
('2504151','Taller de Blockchain',7,4,2,2,2,0,'G',''),
('2504252','Gestión de Proyectos',8,3,2,2,0,0,'F','2504149'),
('2504253','Mantenimiento, Configuración, Despliegue y Evolución de Software',8,5,2,2,4,0,'G','2504149'),
('2504254','Tecnologías de Información',8,4,2,2,2,0,'F','2503242'),
('2504255','Introducción al Desarrollo de Software Ágil (E)',8,4,2,2,2,0,'G','2503240'),
('2504256','Introducción al Desarrollo Móvil (E)',8,4,2,0,4,0,'G','2504148'),
('2504257','Introducción al Desarrollo de Videojuegos (E)',8,4,2,0,4,0,'G','2504146'),
('2504258','Introducción a la Ciberseguridad (E)',8,4,2,2,2,0,'G','2503131'),
('2504259','Criptografía y Autenticación (E)',8,4,2,2,2,0,'G','2504147'),
('2504260','Seguridad de Software y Hacking Ético (E)',8,4,3,2,0,0,'G','2503131'),
('2504261','Machine Learning I (E)',8,4,2,2,2,0,'G','2504146'),
('2504262','Visualización de Datos (E)',8,4,2,0,4,0,'G','2503132'),
('2504263','Base de Datos NoSQL (E)',8,4,2,2,2,0,'G','2503242'),
('2505164','Proyecto Integrador I',9,3,2,0,2,190,'F','2504252'),
('2505165','Gestión de Emprendimiento de Software',9,3,2,2,0,193,'G','2503135'),
('2505166','Fundamentos de Trabajo de Investigación',9,4,2,4,0,188,'F','2504252,2503136'),
('2505167','Ética General y Deontología',9,2,1,2,0,191,'E',''),
('2505168','Fundamentos de Desarrollo de Software en la Nube (E)',9,4,2,2,2,193,'G','2504148'),
('2505169','Tópicos Avanzados de Desarrollo Móvil (E)',9,4,2,0,4,197,'G','2504256'),
('2505170','Tópicos y Técnicas Avanzadas de Desarrollo de Software Ágil (E)',9,4,2,2,2,201,'G','2504255'),
('2505171','Tópicos Avanzados en Ciberseguridad (E)',9,4,2,2,2,0,'G','2504258,2504259'),
('2505172','Gobierno de la Seguridad de Información (E)',9,4,3,2,0,0,'G','2504260'),
('2505173','Seguridad Basada en Inteligencia Artificial (E)',9,4,2,2,2,0,'G','2504260'),
('2505174','Machine Learning II (E)',9,4,2,2,2,0,'G','2504261,2504262'),
('2505175','Gestión de Datos (E)',9,4,2,2,2,0,'G','2504263'),
('2505176','Big Data y Cloud Computing (E)',9,4,2,2,2,0,'G','2504263'),
('2505277','Proyecto Integrador II',10,4,2,0,4,205,'F','2505164'),
('2505278','Prácticas Preprofesionales',10,3,2,2,0,209,'G','2505164'),
('2505279','Trabajo de Investigación',10,4,2,4,0,212,'F','2505166'),
('2505280','Arquitectura Empresarial',10,2,1,2,0,215,'F','2504254'),
('2505281','Tópicos Avanzados de Desarrollo de Videojuegos (E)',10,4,2,0,4,220,'G','2504257'),
('2505282','Desarrollo de Aplicaciones en la Nube Full Stack (E)',10,4,2,0,4,0,'G','2505168'),
('2505283','Auditoria Digital Forense (E)',10,4,3,2,0,0,'G','2505172'),
('2505284','Aspectos Legales de Seguridad y Continuidad de la Organización (E)',10,4,3,2,0,0,'G','2505172'),
('2505285','Deep Learning (E)',10,4,2,2,2,0,'G','2505174'),
('2505286','Minería de Datos (E)',10,4,2,2,2,0,'G','2505175'),
('2505287','Taller de DevOps',10,3,1,2,2,0,'G','');

insert into public.courses(plan_id,code,name,semester,credits,theory_hours,practice_hours,lab_hours,required_credits,component,elective)
select '20250000-0000-4000-8000-000000000001',code,name,semester,credits,theory_hours,practice_hours,lab_hours,required_credits,component,name like '%(E)' from curriculum_seed;
insert into public.prerequisites(course_id,required_course_id)
select c.id,r.id from curriculum_seed s join public.courses c on c.code = s.code and c.plan_id = '20250000-0000-4000-8000-000000000001'
cross join lateral unnest(string_to_array(s.prerequisites,',')) required(code)
join public.courses r on r.code = required.code and r.plan_id = c.plan_id;

do $$ begin
  if (select count(*) from curriculum_seed) <> 87 or (select sum(credits) from curriculum_seed) <> 302 then raise exception 'La carga no coincide con los totales del documento oficial'; end if;
end $$;
update public.profiles set plan_id = '20250000-0000-4000-8000-000000000001' where plan_id is null and role = 'student';
commit;
