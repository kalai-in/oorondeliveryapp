# Testing work — handoff context

Paste this into a new chat to continue. Everything below reflects the repo as
it stands right now.

## Where things stand

`flutter test` → **489 passing, 0 failing**. `flutter analyze lib test
integration_test` → no errors, no warnings (only `avoid_print` infos, which are
deliberate — see conventions).

| Feature | Unit | Widget | Integration |
|---|---|---|---|
| 1. auth | ✅ | ✅ | ✅ 10 on device |
| 2. home | ✅ | ✅ | ✅ 8 on device |
| 3. orders | ✅ | 🟡 partial | 🔲 not started |
| 4–12 (cash_collection, earnings, wallet, salary, settlement_history, notifications, chat, profile, main/splash) | 🔲 | 🔲 | 🔲 |

Integration tests run on a real Android device:
`flutter test integration_test/<file> -d <device-id>`
(the device used was `192.168.1.142:33149`; run `flutter devices` for the
current id). They are **not** part of `flutter test`.

## Orders — exactly what is left

Done (191 tests): all 4 models + status model against real payloads, the
repository (11 methods), all 13 cubits, `PaymentBreakdown`, and these widgets —
order card, ecommerce + return list cards, payment summary, OTP sheet, order
status action sheet, return status action sheet, orders filter, order-detail
cards (pickup/items/billing/timeline/note), return-detail body, ecommerce
detail cards. Plus `orders_screen` (10) and the shared `BasePaginationCubit`
(14, in `test/commons/`).

**Still to do:**

1. **Widgets** — `order_tracking_map_view` (454 lines), `order_tracking_info_card`,
   `order_tracking_no_location`, `order_action_buttons`, `order_skeletons`,
   `order_status_timeline`, `ecommerce_order_status_sheet`, `orders_list`,
   `return_orders_list`, `ecommerce_order_list`, `return_orders_filter`,
   `status_filter_chips`, `bill_row`, `order_appbar_title`.
2. **Screens** — `order_detail_screen`, `ecommerce_order_detail_screen`,
   `return_orders_screen`, `return_order_detail_screen`, `order_tracking_screen`.
   ⚠️ See "the screen-test wall" below before attempting these.
3. **Integration** — `integration_test/orders_flow_test.dart` does not exist
   yet. Should cover: list → detail → status update → OTP delivery, plus the
   return flow.

Then features 4–12, same 3-layer shape.

## The screen-test wall (read before writing any screen test)

Four orders screens build their own cubits internally and fire Dio requests on
build. In a widget test the fake clock never completes those futures, so Dio's
request-timeout timer stays pending and the test fails with **"A Timer is still
pending"** *after every assertion has already passed*. `runAsync`, extra pumps
and unmounting all failed to clear it.

Two things make it manageable:

- If the widget fires a request you *can* stub, stub it and pump ~500ms — the
  response lands, the timer cancels, the test passes. This is what
  `order_status_sheet_test.dart` and `return_order_detail_body_test.dart` do.
- If the screen chains two requests (order → then status list), that does not
  work. `order_detail_screen` was attempted and abandoned; its body cards are
  tested directly instead (`order_detail_cards_test.dart`), and the screen-level
  flow is meant to be covered by the integration test on device, where real
  async works.

Recommended approach for the remaining four screens: cover their bodies as
widgets, put the screen flow in `orders_flow_test.dart`.

## Conventions (follow these — they are used consistently in all 58 test files)

1. Every `expect()` is preceded by `print('label → expected: X, actual: Y')`.
2. Every test body opens with `printTestDivider('what this checks')` from
   `test/helpers/test_logging.dart`.
3. `tearDownAll(() => printTestDivider('=== All tests run! ==='))` in every file.
4. Fixtures are **real API payloads** in `test/fixtures/<feature>/`, never
   invented JSON. Tests read them with `File(...).readAsStringSync()`.
5. Comments explain *why* a non-obvious expectation is what it is (a backend
   quirk, a deliberate UI decision), not what the line does.
6. Bounded `pump()` over `pumpAndSettle()` anywhere an animation loops.

## Test helpers available (`test/helpers/`)

- `pump_test_widget.dart` — wraps a widget in the app's real `AppTheme.lightTheme()`
  + `MaterialApp` (+ `Scaffold` unless `wrapInScaffold: false`). **Also disables
  google_fonts runtime fetching** — see gotcha 1.
- `test_logging.dart` — `printTestDivider`.
- `hive_test_helper.dart` — opens a plain temp-dir Hive box.
- `firebase_test_helper.dart` — fakes `FirebasePlatform` +
  `FirebaseMessagingPlatform`; call `await FirebaseTestHelper.setUp()` in
  `setUpAll` for any screen whose `initState` touches `NotificationService`.
- `fake_api_adapter.dart` — Dio adapter answering from a path→responder map;
  install with `ApiClient().httpClientAdapter = FakeApiAdapter({...})`.
- `mock_cubits.dart`, `mock_api_client.dart`, `mock_auth_repository.dart`,
  `mock_dashboard_repository.dart`, `mock_order_repository.dart`.

`integration_test/helpers/` mirrors some of these (`fake_api_adapter.dart`,
`auth_test_app.dart`, and inlined fixtures — the device has no access to the
host's `test/fixtures/`, so integration fixtures are Dart constants).

## Gotchas that cost real time (all cause SILENT failures)

1. **google_fonts hangs any test that lets real time pass.** The theme's text
   styles come from google_fonts, which tries to *download* a font. Under
   `flutter test` that never resolves, so a test containing `runAsync` stalls
   the runner with no failure message. Already fixed globally in
   `pumpTestWidget`.
2. **A widget test hitting `ApiClient` needs BOTH Hive boxes open** (`authBox`
   *and* `settingsBox`) — `DioInterceptor` reads the auth token and the language
   code, and with either closed it throws before the request reaches the
   adapter: no request recorded, no error shown.
3. **An unstubbed endpoint leaves Dio's timer pending** → "A Timer is still
   pending" after assertions pass.
4. **A network image loader leaves a timer pending too.** Blank image URLs in
   the fixture copy when the test does not assert on images.
5. **An unstubbed mock getter returns `null` into a `bool`** and crashes the
   whole screen build (e.g. `hasActiveFilters`, which `orders_screen` ORs across
   three cubits). Same for a method returning `null` into `Future<void>` — that
   one throws inside the gesture handler *after* assertions pass.
6. **A Hive write started inside a widget test never completes** (fake clock
   never runs the event loop the write finishes on), and the pending future then
   blocks `tearDown`'s `box.close()` forever. Assert storage side effects in a
   plain `test()` instead.
7. **Popping a dialog that is the only route** empties the Navigator and hangs
   the runner. Open dialogs through their real entry point from a host screen.
8. **`SlideToConfirmButton` only fires at the full track width** — a short drag
   silently snaps back. Start the sweep at the track's left edge and exceed its
   width.
9. **`SlideAnimationList` staggers its children in**; a still-animating child is
   not hit-testable, so taps silently miss. Pump ~1s after opening a sheet.
10. **`pump(Duration)` does not advance wall-clock under the live (integration)
    binding** — assertions right after a tap see the pre-response UI. Use
    `tester.runAsync(() => Future.delayed(...))`.
11. **With translations unloaded, labels render as raw keys** (`ecommerce_tab`),
    which are wider than real labels and can overflow a phone-width row. Widen
    the test viewport rather than "fixing" a layout that is fine in production.
12. **`IconButton` contains its own `InkWell`** — `find.byType(InkWell)` is
    ambiguous; target by tooltip.

## Prod changes made during this work (all approved)

1. `ApiClient.httpClientAdapter` — `@visibleForTesting` seam so tests can swap
   Dio's adapter.
2. `dashboard_screen.dart` — `hasScrollBody: false` → `true`. **Real bug:** the
   error branch wrapped `EmptyStateWidget` (root = `LayoutBuilder`) in a sliver
   that measures intrinsic height, so *every failed dashboard fetch* threw
   during layout and then hit a null-check crash in the viewport.
3. `dashboard_stat_card.dart` — inner `Column` is now `mainAxisSize.min` with
   both lines `Flexible`. **Real bug:** 1px vertical overflow on a real device
   once the downloaded font's metrics differed from the fallback's.
4. `pubspec.yaml` — added dev deps: `bloc_test ^10.0.0` (^9 pins bloc ^8, which
   clashes with `flutter_bloc ^9.1.1`), `mocktail`, `integration_test`,
   `firebase_core_platform_interface`, `firebase_messaging_platform_interface`.

## Open findings — reported, NOT fixed (user's call)

1. `DashboardDataModel.fromJson` reads `recent_fund_transfers`, but the API
   sends `recent_settlements` → the list is always null. Its `id` also arrives
   as a String (`"W-34"`) into an `int?`, and `entry_type` is not parsed.
   Latent: nothing in the UI reads it yet.
2. `EarningsTrend.data` is `List<int>` and rounds every point
   (`526.25 → 526`), so the chart loses the paise that `total` keeps.
3. `OrderStatusUpdating` is declared in **both** `order_status_update_cubit.dart`
   and `order_live_tracking_cubit.dart` — they collide on a plain import. The
   tracking one looks like a copy-paste; `OrderLiveTrackingLoading` would fit.
4. `OrderCubit.updateFilters` treats omitted arguments as *cleared*, not
   unchanged (passing only `status:` wipes an active `search`). Documented in a
   test — confirm whether that is intended.
5. `ReturnRequestsPieChart`'s doc says tapping a legend row shows a tooltip, but
   the tooltip needs touch coordinates the legend tap does not supply. Only a
   tap on the chart itself shows one.

## Payload source

All orders fixtures were extracted from `lib/core/api/order.json` (a scratch
file of pasted API responses). If the backend contract changes, refresh the
fixtures in `test/fixtures/` rather than editing assertions inline.

## Plan doc

`TESTING.md` holds the per-feature checklist, progress table and the same
gotcha list. Keep both updated as features complete.
