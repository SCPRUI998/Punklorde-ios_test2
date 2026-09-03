import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

class SimpleAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const SimpleAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  const SimpleAppBar.nested({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return FHeader.nested(
      title: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle ?? "",
                  style: TextStyle(
                    fontSize: 12,
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ],
            )
          : Text(title),
      prefixes: [FHeaderAction.x(onPress: () => context.pop())],
      suffixes: actions ?? [],
    );
  }
}
