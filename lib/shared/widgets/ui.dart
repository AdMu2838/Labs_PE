import 'package:flutter/material.dart';
export '../presentation_labels.dart';
import '../../app/theme/app_theme.dart';

class Brand extends StatelessWidget {
  const Brand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 42, height: 48, decoration: BoxDecoration(color: light ? Colors.white.withValues(alpha: .12) : UnsaColors.garnet,
      borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_balance_rounded, color: UnsaColors.gold, size: 27)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('UNSA · LAB', style: TextStyle(color: light ? Colors.white : UnsaColors.garnet, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      Text('Ingeniería de Sistemas', style: TextStyle(color: light ? Colors.white70 : UnsaColors.muted, fontSize: 11)),
    ])),
  ]);
}

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, this.subtitle, {super.key, this.action});
  final String title, subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 24), child: LayoutBuilder(builder: (context, c) => Wrap(
    alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 16, runSpacing: 16,
    children: [SizedBox(width: c.maxWidth, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(color: UnsaColors.muted)),
    ])), ?action],
  )));
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = 22});
  final Widget child;
  final double padding;
  @override
  // Cada campo conserva su propio nodo accesible, incluso dentro de una tarjeta.
  Widget build(BuildContext context) => Semantics(container: true, explicitChildNodes: true,
    child: Card(semanticContainer: false, margin: EdgeInsets.zero, child: Padding(padding: EdgeInsets.all(padding), child: child)));
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.good = true});
  final String label;
  final bool good;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: good ? const Color(0xFFEAF5EE) : const Color(0xFFFFF3DC), borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: good ? const Color(0xFF236442) : const Color(0xFF805C13))));
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = Icons.inbox_outlined});
  final String message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Panel(child: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
    Icon(icon, size: 40, color: UnsaColors.gold), const SizedBox(height: 14), Text(message, textAlign: TextAlign.center),
  ]))));
}

void notify(BuildContext context, String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

Future<bool> confirm(BuildContext context, String title, String message) async => await showDialog<bool>(context: context,
  builder: (context) => AlertDialog(title: Text(title), content: Text(message), actions: [
    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
  ])) ?? false;
