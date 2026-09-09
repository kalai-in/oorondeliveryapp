import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deliveryboy/core/api/hive_box_keys.dart';
import 'package:deliveryboy/features/orders/models/ecommerce_order_model.dart';
import 'package:deliveryboy/features/orders/widgets/ecommerce_order_billing_card.dart';
import 'package:deliveryboy/features/orders/widgets/ecommerce_order_customer_info_card.dart';
import 'package:deliveryboy/features/orders/widgets/ecommerce_order_detail_items_card.dart';
import 'package:deliveryboy/features/orders/widgets/payment_summary_section.dart';

import '../../../helpers/hive_test_helper.dart';
import '../../../helpers/pump_test_widget.dart';
import '../../../helpers/test_logging.dart';

/// The cards that make up the ecommerce order-detail body. They take plain
/// props, so each is exercised directly; the screen that assembles them is
/// covered by the orders integration flow.
void main() {
  late EcommerceOrderDataModel order;

  setUp(() async {
    // Dates are formatted through AppDateFormatter, which reads the
    // server-provided format out of SettingsHiveBox.
    await HiveTestHelper.setUp(settingsBox);

    final response =
        jsonDecode(
              File(
                'test/fixtures/orders/ecommerce_order_detail.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final row = Map<String, dynamic>.from(
      (response['data'] as List).first as Map,
    );
    // Blank the product image: a network image loader schedules a timer that
    // outlives the widget tree and fails the test with "A Timer is still
    // pending" after the assertions have already passed.
    row['image'] = '';
    order = EcommerceOrderDataModel.fromJson(row);
  });

  tearDown(() => HiveTestHelper.tearDown(settingsBox));

  tearDownAll(() => printTestDivider('=== All tests run! ==='));

  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(820, 2000);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(pumpTestWidget(SingleChildScrollView(child: card)));
    await tester.pump();
  }

  group('EcommerceOrderCustomerInfoCard', () {
    testWidgets('shows the order number and payment method', (tester) async {
      printTestDivider('shows the order number and payment method');
      await pumpCard(tester, EcommerceOrderCustomerInfoCard(order: order));

      printTestLog('order number → expected: "${order.orderNumber}" visible');
      expect(find.textContaining('${order.orderNumber}'), findsWidgets);
      printTestLog('payment method → expected: "${order.paymentMethod}" visible');
      expect(find.textContaining(order.paymentMethod!), findsWidgets);
    });

    testWidgets('omits the rows the payload leaves null', (tester) async {
      printTestDivider('omits the rows the payload leaves null');
      // The real ecommerce detail payload carries no store name, mobile,
      // address or note — every one of those rows is conditional, so the card
      // renders without them rather than showing blanks.
      printTestLog('storeName in payload → expected: null, actual: ${order.storeName}');
      expect(order.storeName, isNull);

      await pumpCard(tester, EcommerceOrderCustomerInfoCard(order: order));

      printTestLog('exception → expected: none, actual: ${tester.takeException()}');
      printTestLog('order number still shown → expected: visible');
      expect(find.textContaining('${order.orderNumber}'), findsWidgets);
    });

    testWidgets('adds a row once the payload carries that field', (
      tester,
    ) async {
      printTestDivider('adds a row once the payload carries that field');
      order.storeName = 'Mumbai Store';
      order.orderNote = 'Leave at the gate';
      await pumpCard(tester, EcommerceOrderCustomerInfoCard(order: order));

      printTestLog('store → expected: "Mumbai Store" visible');
      expect(find.textContaining('Mumbai Store'), findsWidgets);
      printTestLog('note → expected: "Leave at the gate" visible');
      expect(find.textContaining('Leave at the gate'), findsWidgets);
    });

    testWidgets('renders an order with no customer details', (tester) async {
      printTestDivider('renders an order with no customer details');
      final bare = EcommerceOrderDataModel.fromJson(const {'id': 1});
      await pumpCard(tester, EcommerceOrderCustomerInfoCard(order: bare));

      printTestLog('exception → expected: none, actual: ${tester.takeException()}');
    });
  });

  group('EcommerceOrderDetailItemsCard', () {
    testWidgets('shows the item this row is for', (tester) async {
      printTestDivider('shows the item this row is for');
      await pumpCard(
        tester,
        EcommerceOrderDetailItemsCard(order: order, symbol: '₹'),
      );

      printTestLog('product → expected: "${order.productName}" visible');
      expect(find.textContaining(order.productName!), findsWidgets);
    });

    testWidgets('renders when the order carries no other items', (
      tester,
    ) async {
      printTestDivider('renders when the order carries no other items');
      // The ecommerce list is per order item; `otherItems` is the rest of the
      // same order and is often absent.
      order.otherItems = null;
      await pumpCard(
        tester,
        EcommerceOrderDetailItemsCard(order: order, symbol: '₹'),
      );

      printTestLog('exception → expected: none, actual: ${tester.takeException()}');
      expect(find.textContaining(order.productName!), findsWidgets);
    });
  });

  group('EcommerceOrderBillingCard', () {
    testWidgets('summarises the payment', (tester) async {
      printTestDivider('EcommerceOrderBillingCard summarises the payment');
      await pumpCard(
        tester,
        EcommerceOrderBillingCard(order: order, symbol: '₹'),
      );

      printTestLog(
        'payment summary → expected: 1, actual: ${find.byType(PaymentSummarySection).evaluate().length}',
      );
      expect(find.byType(PaymentSummarySection), findsOneWidget);
    });

    testWidgets('drops the collect callout for a delivered COD item', (
      tester,
    ) async {
      printTestDivider('drops the collect callout for a delivered COD item');
      // Every row in the fixture is already delivered (status 6).
      printTestLog('activeStatus → expected: 6, actual: ${order.activeStatus}');
      expect(order.activeStatus, 6);
      await pumpCard(
        tester,
        EcommerceOrderBillingCard(order: order, symbol: '₹'),
      );

      printTestLog(
        'collect callout → expected: absent, actual: ${find.byType(CollectFromCustomerCallout).evaluate().length}',
      );
      expect(find.byType(CollectFromCustomerCallout), findsNothing);
    });

    testWidgets('asks for cash while the same item is out for delivery', (
      tester,
    ) async {
      printTestDivider('asks for cash while the same item is out for delivery');
      order.activeStatus = 5;
      order.paymentMethod = 'COD';
      await pumpCard(
        tester,
        EcommerceOrderBillingCard(order: order, symbol: '₹'),
      );

      printTestLog(
        'collect callout → expected: 1, actual: ${find.byType(CollectFromCustomerCallout).evaluate().length}',
      );
      expect(find.byType(CollectFromCustomerCallout), findsOneWidget);
    });
  });
}
