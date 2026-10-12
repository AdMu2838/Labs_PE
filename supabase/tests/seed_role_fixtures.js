// Oferta persistente, claramente identificada como pruebas LAB04.
async (page) => {
  const s = page.__roleTests;
  if (!s?.fixtures.groupA) throw new Error('Primero crea el periodo, ambiente y grupo desde la UI');
  const create = async (table, body) => {
    const result = await s.api('admin', table, 'POST', body);
    if (!result.ok) throw new Error(`Crear ${table}: ${JSON.stringify(result.data)}`);
    return result.data[0].id;
  };
  const courses = (await s.api('admin', 'courses?select=id,code')).data;
  s.fixtures.webCourse = courses.find(c => c.code === '2501210').id;
  s.fixtures.databaseCourse = courses.find(c => c.code === '2503242').id;
  s.fixtures.room2 = await create('rooms', { name: 'LAB04 - LAB 2', location: 'Ambiente de pruebas LAB04', capacity: 30, equipment: 'PCs y red de prueba' });
  const group = async (name, course, room, capacity, teacher = true) => create('groups', {
    name, course_id: course, room_id: room, period_id: s.fixtures.period,
    teacher_id: teacher ? s.users.teacher.id : null, capacity,
  });
  s.fixtures.groupB = await group('LAB04-SOFT-B', s.fixtures.course, s.fixtures.room, 1);
  s.fixtures.groupWeb = await group('LAB04-WEB-A', s.fixtures.webCourse, s.fixtures.room, 30);
  s.fixtures.groupDB = await group('LAB04-BD-A', s.fixtures.databaseCourse, s.fixtures.room, 30);
  s.fixtures.groupCross = await group('LAB04-WEB-CRUCE', s.fixtures.webCourse, s.fixtures.room2, 30, false);
  const sessions = [
    [s.fixtures.groupA, 4, '08:00', '10:00'],
    [s.fixtures.groupB, 3, '08:00', '10:00'], [s.fixtures.groupB, 5, '08:00', '10:00'],
    [s.fixtures.groupWeb, 2, '10:00', '12:00'], [s.fixtures.groupWeb, 5, '10:00', '12:00'],
    [s.fixtures.groupDB, 3, '14:00', '16:00'],
    [s.fixtures.groupCross, 1, '09:00', '11:00'], [s.fixtures.groupCross, 4, '09:00', '11:00'],
  ];
  for (const [group_id, day, start_time, end_time] of sessions) await create('sessions', { group_id, day, start_time, end_time });
  s.check(true, 'Oferta de pruebas: cinco grupos y nueve sesiones, con horas oficiales de laboratorio');
  return { fixturePeriod: 'LAB04 - PRUEBAS', groups: 5, sessions: 9, persistent: true };
}
