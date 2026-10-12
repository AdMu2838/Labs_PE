import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduce valores del dominio sin alterar los códigos enviados al servidor.
String presentationLabel(dynamic value) => switch (value) {
  null => 'Sin asignar',
  true => 'Sí',
  false => 'No',
  'student' => 'Estudiante',
  'teacher' => 'Docente',
  'coordinator' => 'Coordinación',
  'admin' => 'Administrador',
  'draft' => 'Borrador',
  'open' => 'Abierto',
  'closed' => 'Cerrado',
  'active' => 'Activo',
  'withdrawn' => 'Retirado',
  'waiting' => 'En espera',
  'promoted' => 'Vacante asignada',
  'skipped' => 'Omitido',
  'cancelled' => 'Cancelado',
  'pending' => 'Pendiente',
  'approved' => 'Aprobada',
  'rejected' => 'Rechazada',
  'resolved' => 'Atendida',
  'schedule' => 'Horario',
  'capacity' => 'Vacantes',
  'exception' => 'Excepción',
  'other' => 'Otro',
  'INSERT' => 'Creación',
  'UPDATE' => 'Actualización',
  'DELETE' => 'Eliminación',
  'profiles' => 'Usuarios',
  'periods' => 'Periodos',
  'groups' => 'Grupos',
  'sessions' => 'Horarios',
  'rooms' => 'Ambientes',
  'courses' => 'Asignaturas',
  'plans' => 'Planes',
  'prerequisites' => 'Prerrequisitos',
  'enrollments' => 'Matrículas',
  'waitlist' => 'Lista de espera',
  'requests' => 'Solicitudes',
  'announcements' => 'Avisos',
  'eligibilities' => 'Habilitaciones',
  'academic_records' => 'Historial académico',
  'notifications' => 'Notificaciones',
  _ => '$value',
};

String errorLabel(Object error) {
  final message = error is AuthException ? error.message : error is PostgrestException ? error.message : '$error';
  final text = message.toLowerCase();
  if (text.contains('invalid login credentials')) return 'Correo o contraseña incorrectos.';
  if (text.contains('email not confirmed')) return 'Confirma tu correo antes de ingresar.';
  if (text.contains('already registered')) return 'Este correo ya tiene una cuenta registrada.';
  if (text.contains('rate limit') || text.contains('too many requests')) return 'Demasiados intentos. Espera unos minutos y vuelve a intentar.';
  if (text.contains('password') && (text.contains('short') || text.contains('least'))) return 'La contraseña no cumple la longitud mínima requerida.';
  if (text.contains('network') || text.contains('failed to fetch') || text.contains('socketexception') || text.contains('clientexception')) return 'No se pudo conectar. Revisa tu conexión e inténtalo nuevamente.';
  if (text.contains('duplicate key')) return 'Ya existe un registro con esos datos.';
  if (text.contains('foreign key')) return 'El registro está vinculado a otros datos. Revisa las dependencias.';
  if (text.contains('row-level security') || text.contains('permission denied')) return 'No tienes permisos para realizar esta operación.';
  // Conserva las validaciones de negocio que el servidor ya devuelve en español.
  if (RegExp(r'[áéíóúñ¿]|\b(no tienes|no hay|no se |no puedes|no es |ya |debes |ingresa |el grupo|la cuenta|campo |sin |solo |fuera )').hasMatch(text)) {
    return message.replaceFirst(RegExp(r'^Exception: '), '');
  }
  return 'No se pudo completar la operación. Inténtalo nuevamente.';
}
