// Elimina exclusivamente los registros creados por live_cloud.js.
async (page) => {
  const state = page.__labTest;
  if (!state) return { cleaned: false, reason: 'No hay sesión temporal' };
  const users = Object.values(state.users).map(u => u.id);
  const ids = state.ids;
  const q = state.q;
  if (!users.length) return { cleaned: false, reason: 'No hay usuarios temporales' };
  const inUsers = users.map(q).join(',');
  const groups = [ids.groupA, ids.groupB, ids.groupCross].filter(Boolean).map(q).join(',') || 'null';
  const records = [...users, ...Object.values(ids)].filter(v => /^[0-9a-f-]{36}$/i.test(String(v))).map(q).join(',');
  await state.sql(`begin;
    select set_config('request.jwt.claim.sub','',true);
    delete from public.announcements where created_by in (${inUsers}) or group_id in (${groups});
    delete from public.requests where student_id in (${inUsers});
    delete from public.notifications where student_id in (${inUsers});
    delete from public.waitlist where student_id in (${inUsers});
    delete from public.enrollments where student_id in (${inUsers});
    delete from public.eligibilities where student_id in (${inUsers});
    delete from public.academic_records where student_id in (${inUsers});
    delete from public.sessions where group_id in (${groups});
    delete from public.groups where id in (${groups});
    delete from public.rooms where name in (${q(state.prefix + '-A')},${q(state.prefix + '-B')});
    delete from public.periods where name=${q(state.prefix)};
    commit;`);
  const headers = { apikey: page.__labServiceKey, authorization: `Bearer ${page.__labServiceKey}` };
  for (const id of users) {
    const response = await page.request.delete(`https://spduupvhofygzkcmqmiz.supabase.co/auth/v1/admin/users/${id}`, { headers });
    if (!response.ok()) throw new Error(`No se pudo eliminar el usuario temporal ${id}`);
  }
  await state.sql(`delete from public.audit_logs where actor_id in (${inUsers}) or record_id in (${records})
    or new_data->>'student_id' in (${inUsers}) or old_data->>'student_id' in (${inUsers})
    or new_data->>'group_id' in (${groups}) or old_data->>'group_id' in (${groups})
    or new_data::text like ${q('%' + state.prefix + '%')} or old_data::text like ${q('%' + state.prefix + '%')};`);
  page.__labLastChecks = state.checks;
  delete page.__labTest;
  return { cleaned: true, deletedUsers: users.length, removedPrefix: state.prefix };
}
