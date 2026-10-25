import 'package:flutter/material.dart';

import '../../config/strings.dart';

/// 全宽的「添加到列表」按钮，样式统一。
class RiskAddButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const RiskAddButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: const Text(AppStrings.listAddButton),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

/// 待提交列表：标题带数量，空列表时显示提示。
class RiskPendingList extends StatelessWidget {
  final String title;
  final String emptyHint;
  final int count;
  final List<Widget> rows;

  const RiskPendingList({
    super.key,
    required this.title,
    required this.emptyHint,
    required this.count,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          '$title ($count)',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        if (count == 0)
          Text(
            emptyHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...rows,
      ],
    );
  }
}

/// 待提交列表的一行：等宽文本 + 删除按钮。
class RiskPendingRow extends StatelessWidget {
  final String leading;
  final String trailing;
  final VoidCallback onRemove;
  final bool enabled;

  const RiskPendingRow({
    super.key,
    required this.leading,
    required this.trailing,
    required this.onRemove,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '$leading  $trailing',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          tooltip: AppStrings.listRemoveTooltip,
          onPressed: enabled ? onRemove : null,
          color: theme.colorScheme.onSurfaceVariant,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

/// 风险页通用下拉框（圆角 10、内容内边距 14）。
class RiskDropdownField<T> extends StatelessWidget {
  final T value;
  final String label;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  const RiskDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
      items: items,
      onChanged: !enabled || onChanged == null
          ? null
          : (v) {
              if (v == null) return;
              onChanged!(v);
            },
    );
  }
}

/// 与 [RiskDropdownField] 配对的普通文本输入框，保持同样的圆角与内边距。
class RiskNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool enabled;

  const RiskNumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }
}
