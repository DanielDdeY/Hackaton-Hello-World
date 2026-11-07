import 'package:flutter/material.dart';

import 'dashed_action_box.dart';

class CollapsibleSection extends StatelessWidget {
  const CollapsibleSection({
    super.key,
    required this.label,
    required this.expanded,
    required this.onChanged,
    required this.child,
    this.icon = Icons.add,
  });

  final String label;
  final bool expanded;
  final ValueChanged<bool> onChanged;
  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: expanded,
          child: DashedActionBox(
            label: label,
            icon: expanded ? Icons.remove : icon,
            onTap: () => onChanged(!expanded),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Offstage(
            offstage: !expanded,
            child: ExcludeFocus(
              excluding: !expanded,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
