import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ichino/config/strings.dart';
import 'package:ichino/widgets/risk/risk_list_widgets.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Column(children: [child])));

void main() {
  testWidgets('RiskPendingList 空列表显示提示，非空显示行', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const RiskPendingList(
          title: '待解锁',
          emptyHint: '还没有添加',
          count: 0,
          rows: [],
        ),
      ),
    );
    expect(find.text('待解锁 (0)'), findsOneWidget);
    expect(find.text('还没有添加'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        RiskPendingList(
          title: '待解锁',
          emptyHint: '还没有添加',
          count: 1,
          rows: const [
            RiskPendingRow(leading: '#834', trailing: 'Master', onRemove: _noop),
          ],
        ),
      ),
    );
    expect(find.text('待解锁 (1)'), findsOneWidget);
    expect(find.text('还没有添加'), findsNothing);
    expect(find.textContaining('#834'), findsOneWidget);
  });

  testWidgets('RiskPendingRow 禁用时删除按钮不触发回调', (tester) async {
    var removed = 0;
    await tester.pumpWidget(
      _wrap(
        RiskPendingRow(
          leading: '#1',
          trailing: 'x',
          onRemove: () => removed++,
          enabled: false,
        ),
      ),
    );
    final button = tester.widget<IconButton>(find.byType(IconButton));
    expect(button.onPressed, isNull);
    expect(find.byTooltip(AppStrings.listRemoveTooltip), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        RiskPendingRow(
          leading: '#1',
          trailing: 'x',
          onRemove: () => removed++,
        ),
      ),
    );
    await tester.tap(find.byTooltip(AppStrings.listRemoveTooltip));
    expect(removed, 1);
  });

  testWidgets('RiskNumberField 与 RiskAddButton 共用统一样式', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var added = 0;

    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            RiskNumberField(controller: controller, label: 'A', hint: 'B'),
            RiskAddButton(onPressed: () => added++),
          ],
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    await tester.tap(find.text(AppStrings.listAddButton));
    expect(added, 1);
  });
}

void _noop() {}
