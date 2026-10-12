import 'package:flutter/material.dart';
import '../../features/auth/domain/session.dart';

typedef WorkspaceLink = (String, String, IconData);

class RoleWorkspace {
  const RoleWorkspace(this.title, this.description, this.color, this.links);
  final String title, description;
  final Color color;
  final List<WorkspaceLink> links;

  static RoleWorkspace forRole(AppRole role) => switch (role) {
    AppRole.student => const RoleWorkspace('Mi espacio académico',
      'Organiza tu matrícula y tu semana de laboratorios.', Color(0xFF7B1835), [
      ('/catalog', 'Laboratorios', Icons.science_outlined),
      ('/enrollments', 'Mis matrículas', Icons.assignment_outlined),
      ('/schedule', 'Mi horario', Icons.calendar_month_outlined),
      ('/curriculum', 'Plan de estudios', Icons.account_tree_outlined),
      ('/requests', 'Mis solicitudes', Icons.support_agent_outlined),
    ]),
    AppRole.teacher => const RoleWorkspace('Espacio docente',
      'Tus grupos, sesiones y comunicación con estudiantes.', Color(0xFF245B64), [
      ('/enrollments', 'Mis grupos', Icons.groups_outlined),
      ('/schedule', 'Horario docente', Icons.calendar_month_outlined),
      ('/reports', 'Listas y reportes', Icons.bar_chart_rounded),
      ('/catalog', 'Oferta de laboratorios', Icons.science_outlined),
      ('/requests', 'Solicitudes', Icons.support_agent_outlined),
    ]),
    AppRole.coordinator => const RoleWorkspace('Coordinación académica',
      'Supervisa la oferta, las vacantes y la atención de solicitudes.', Color(0xFF705525), [
      ('/requests', 'Atender solicitudes', Icons.support_agent_outlined),
      ('/admin', 'Gestión académica', Icons.tune_rounded),
      ('/enrollments', 'Matrículas', Icons.assignment_outlined),
      ('/catalog', 'Oferta y vacantes', Icons.science_outlined),
      ('/schedule', 'Horario de laboratorios', Icons.calendar_month_outlined),
      ('/reports', 'Reportes', Icons.bar_chart_rounded),
      ('/curriculum', 'Plan de estudios', Icons.account_tree_outlined),
    ]),
    AppRole.admin => const RoleWorkspace('Administración del sistema',
      'Gestiona usuarios, configuración y actividad institucional.', Color(0xFF39466C), [
      ('/admin', 'Administración', Icons.admin_panel_settings_outlined),
      ('/admin?section=users', 'Usuarios', Icons.manage_accounts_outlined),
      ('/admin?section=audit', 'Auditoría', Icons.history),
      ('/reports', 'Reportes', Icons.bar_chart_rounded),
      ('/requests', 'Solicitudes', Icons.support_agent_outlined),
      ('/enrollments', 'Matrículas', Icons.assignment_outlined),
      ('/catalog', 'Oferta de laboratorios', Icons.science_outlined),
      ('/curriculum', 'Plan de estudios', Icons.account_tree_outlined),
    ]),
  };
}
