import '../../../core/domain/form_field_spec.dart';

class AdminSection {
  const AdminSection(this.table, this.label, this.titleKey, this.fields);
  final String table, label, titleKey;
  final List<FormFieldSpec> fields;
}

const adminSections = [
  AdminSection('periods', 'Periodos', 'name', [FormFieldSpec('name', 'Periodo (ej. 2026-B)'),
    FormFieldSpec('status', 'Estado', options: ['draft', 'open', 'closed']),
    FormFieldSpec('enrollment_start', 'Inicio de matrícula', kind: 'date'), FormFieldSpec('enrollment_end', 'Fin de matrícula', kind: 'date'),
    FormFieldSpec('withdrawal_end', 'Fin de cambios y retiros', kind: 'date'), FormFieldSpec('require_eligibility', 'Exigir habilitación y prerrequisitos', kind: 'bool')]),
  AdminSection('rooms', 'Ambientes', 'name', [FormFieldSpec('name', 'Nombre del laboratorio'), FormFieldSpec('capacity', 'Capacidad física', kind: 'int'),
    FormFieldSpec('location', 'Ubicación'), FormFieldSpec('equipment', 'Equipamiento', kind: 'long', required: false), FormFieldSpec('active', 'Disponible', kind: 'bool')]),
  AdminSection('groups', 'Grupos', 'name', [FormFieldSpec('name', 'Nombre del grupo'), FormFieldSpec('course_id', 'Asignatura', table: 'courses'),
    FormFieldSpec('period_id', 'Periodo', table: 'periods'), FormFieldSpec('room_id', 'Laboratorio', table: 'rooms'),
    FormFieldSpec('teacher_id', 'Docente (solo perfiles con rol docente)', table: 'profiles', optionLabel: 'full_name', required: false),
    FormFieldSpec('capacity', 'Vacantes', kind: 'int'), FormFieldSpec('active', 'Publicado', kind: 'bool')]),
  AdminSection('sessions', 'Horarios', 'start_time', [FormFieldSpec('group_id', 'Grupo', table: 'groups'), FormFieldSpec('day', 'Día: 1 lunes … 7 domingo', kind: 'int'),
    FormFieldSpec('start_time', 'Hora de inicio', kind: 'time'), FormFieldSpec('end_time', 'Hora de fin', kind: 'time')]),
  AdminSection('plans', 'Planes', 'name', [FormFieldSpec('name', 'Nombre del plan'), FormFieldSpec('year', 'Año', kind: 'int'), FormFieldSpec('source_url', 'Fuente oficial', required: false)]),
  AdminSection('courses', 'Asignaturas', 'name', [FormFieldSpec('plan_id', 'Plan', table: 'plans'), FormFieldSpec('code', 'Código'), FormFieldSpec('name', 'Nombre'),
    FormFieldSpec('semester', 'Semestre 1–10', kind: 'int'), FormFieldSpec('credits', 'Créditos', kind: 'number'), FormFieldSpec('lab_hours', 'Horas de laboratorio', kind: 'number'),
    FormFieldSpec('theory_hours', 'Horas de teoría', kind: 'number', required: false), FormFieldSpec('practice_hours', 'Horas de práctica', kind: 'number', required: false),
    FormFieldSpec('required_credits', 'Créditos mínimos aprobados', kind: 'int', required: false), FormFieldSpec('elective', 'Asignatura electiva', kind: 'bool')]),
  AdminSection('prerequisites', 'Prerrequisitos', 'id', [FormFieldSpec('course_id', 'Asignatura', table: 'courses'), FormFieldSpec('required_course_id', 'Requisito', table: 'courses')]),
  AdminSection('announcements', 'Avisos', 'title', [FormFieldSpec('title', 'Título'), FormFieldSpec('body', 'Contenido', kind: 'long')]),
  AdminSection('eligibilities', 'Habilitaciones', 'student_id', [FormFieldSpec('student_id', 'Estudiante', table: 'profiles', optionLabel: 'full_name'),
    FormFieldSpec('course_id', 'Asignatura', table: 'courses'), FormFieldSpec('period_id', 'Periodo', table: 'periods'), FormFieldSpec('enabled', 'Habilitado', kind: 'bool')]),
  AdminSection('academic_records', 'Historial', 'student_id', [FormFieldSpec('student_id', 'Estudiante', table: 'profiles', optionLabel: 'full_name'),
    FormFieldSpec('course_id', 'Asignatura', table: 'courses'), FormFieldSpec('grade', 'Nota (0–20)', kind: 'number'), FormFieldSpec('passed', 'Aprobado', kind: 'bool')]),
];
