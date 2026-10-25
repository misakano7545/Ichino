import 'package:flutter/material.dart';

import '../../config/strings.dart';
import '../app_card.dart';
import 'risk_list_widgets.dart';
import 'risk_widgets.dart';

/// 一行待提交的收藏品道具（对应 wire 上的 UserItem）。
class PendingItem {
  final int kind;
  final int id;

  const PendingItem(this.kind, this.id);
}

/// 一行待提交的歌曲解锁，展开成 itemKind 5/6/7 的若干行。
class PendingMusic {
  final int musicId;
  final bool base;
  final bool master;
  final bool remaster;

  const PendingMusic(this.musicId, this.base, this.master, this.remaster);

  /// 难度由 itemKind 表达，不写在 musicDetail 上。
  List<int> get itemKinds => [
    if (base) 5,
    if (master) 6,
    if (remaster) 7,
  ];

  String get optionLabel => [
    if (base) '歌曲',
    if (master) 'Master',
    if (remaster) 'Re:Master',
  ].join('/');

  /// ConstParameter.DxScoreBaseID=10000 / StrongScoreBaseID=20000
  /// （`MAI2System/ConstParameter.cs:168,171`）。这段里的歌 Master 需要
  /// 显式 itemKind 6，不像 id < 10000 那样在 IsUnlockMaster 里直接放过。
  bool get isDeluxeRange => musicId >= 10000 && musicId < 20000;
}

/// 歌曲解锁的输入卡。输入框与三个难度勾选由本组件持有，
/// 校验通过后把待提交行交给父级；父级返回 false 表示重复、保留输入。
class UnlockMusicEditorCard extends StatefulWidget {
  final bool enabled;
  final bool Function(PendingMusic music) onAdd;
  final ValueChanged<String> onError;
  final Widget pendingList;
  final bool showDxNotice;

  const UnlockMusicEditorCard({
    super.key,
    required this.enabled,
    required this.onAdd,
    required this.onError,
    required this.pendingList,
    required this.showDxNotice,
  });

  @override
  State<UnlockMusicEditorCard> createState() => _UnlockMusicEditorCardState();
}

class _UnlockMusicEditorCardState extends State<UnlockMusicEditorCard> {
  final _controller = TextEditingController();
  bool _music = false;
  bool _master = false;
  bool _remaster = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final id = int.tryParse(_controller.text.trim()) ?? -1;
    if (id <= 0) {
      widget.onError(AppStrings.unlockNeedMusicId);
      return;
    }
    if (!_music && !_master && !_remaster) {
      widget.onError(AppStrings.unlockNeedOption);
      return;
    }

    final added = widget.onAdd(PendingMusic(id, _music, _master, _remaster));
    if (!added) return;

    setState(() {
      _controller.clear();
      _music = _master = _remaster = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.enabled;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RiskNumberField(
            controller: _controller,
            label: AppStrings.unlockMusicIdLabel,
            hint: AppStrings.unlockMusicIdHint,
            enabled: enabled,
          ),
          const SizedBox(height: 6),
          RiskCheckRow(
            value: _music,
            label: AppStrings.unlockMusicOption,
            enabled: enabled,
            onChanged: (v) => setState(() => _music = v),
          ),
          RiskCheckRow(
            value: _master,
            label: AppStrings.unlockMasterOption,
            enabled: enabled,
            onChanged: (v) => setState(() => _master = v),
          ),
          RiskCheckRow(
            value: _remaster,
            label: AppStrings.unlockRemasterOption,
            enabled: enabled,
            onChanged: (v) => setState(() => _remaster = v),
          ),
          const SizedBox(height: 8),
          RiskAddButton(onPressed: enabled ? _add : null),
          widget.pendingList,
          // DX 段的 Master / Re:Master 不白送，勾选项里漏一个就开不出来，
          // 这是这段 ID 最容易踩的坑，只在列表真含 DX 曲时才说明。
          if (widget.showDxNotice) ...[
            const SizedBox(height: 10),
            Text(
              AppStrings.unlockDxRangeNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 收藏品获取的输入卡（类型下拉 + ID）。
class CollectiblesEditorCard extends StatefulWidget {
  final bool enabled;
  final bool Function(PendingItem item) onAdd;
  final ValueChanged<String> onError;
  final Widget pendingList;

  const CollectiblesEditorCard({
    super.key,
    required this.enabled,
    required this.onAdd,
    required this.onError,
    required this.pendingList,
  });

  @override
  State<CollectiblesEditorCard> createState() => _CollectiblesEditorCardState();
}

class _CollectiblesEditorCardState extends State<CollectiblesEditorCard> {
  final _controller = TextEditingController();
  int _kind = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final id = int.tryParse(_controller.text.trim()) ?? -1;
    if (id <= 0) {
      widget.onError(AppStrings.collectiblesNeedItemId);
      return;
    }

    final added = widget.onAdd(PendingItem(_kind, id));
    if (!added) return;

    setState(() => _controller.clear());
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RiskDropdownField<int>(
            value: _kind,
            label: AppStrings.collectiblesItemKindLabel,
            enabled: enabled,
            items: [
              for (final kind in AppStrings.collectiblesItemKinds)
                DropdownMenuItem(
                  value: kind,
                  child: Text(
                    '${AppStrings.collectiblesItemKindName(kind)} ($kind)',
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _kind = v),
          ),
          const SizedBox(height: 12),
          RiskNumberField(
            controller: _controller,
            label: AppStrings.collectiblesItemIdLabel,
            hint: AppStrings.collectiblesItemIdHint,
            enabled: enabled,
          ),
          const SizedBox(height: 8),
          RiskAddButton(onPressed: enabled ? _add : null),
          widget.pendingList,
        ],
      ),
    );
  }
}
