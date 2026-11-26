import 'package:flutter/material.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 920});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final horizontal = constraints.maxWidth > maxWidth + 32
            ? (constraints.maxWidth - maxWidth) / 2
            : 16.0;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 16),
          child: child,
        );
      },
    );
  }
}
