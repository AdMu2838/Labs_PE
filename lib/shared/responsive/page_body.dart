import 'package:flutter/material.dart';

/// Cada ruta posee su propio scroll; el Navigator siempre ocupa el viewport.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) => SingleChildScrollView(
    padding: EdgeInsets.all(c.maxWidth < 600 ? 16 : 32),
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1440),
      child: SizedBox(width: double.infinity, child: child)))));
}
