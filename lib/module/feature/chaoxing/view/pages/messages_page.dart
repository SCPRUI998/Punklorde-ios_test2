import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:punklorde/i18n/strings.g.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Center(
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.messageCircle, size: 32, color: colors.mutedForeground),
          Text(
            t.submodule.chaoxing.messages_placeholder,
            style: TextStyle(color: colors.mutedForeground, fontSize: 16),
          ),
        ],
      ),
    );
  }
}