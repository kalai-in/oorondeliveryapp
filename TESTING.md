# Testing Plan — SnapBuy Delivery Boy App

Feature-by-feature test case checklist. Built 1 by 1, product-ready pass —
each feature covered on **3 layers: unit, widget, integration** — before next
feature starts.

## Setup (done)

`pubspec.yaml` `dev_dependencies` (added, marked with a comment pointing here):
```yaml
bloc_test: ^10.0.0   # ^9.x pins bloc ^8, incompatible with flutter_bloc ^9.1.1
mocktail: ^1.0.4
integration_test:
  sdk: flutter
```

Dirs:
- `test/features/<feature>/...` — unit (models, repository, cubit) + widget tests. Mirrors `lib/features/<feature>/...`.
- `test/fixtures/<feature>/` — real API response payloads as JSON. Refresh these when the backend contract changes instead of editing assertions inline.
- `test/helpers/` — shared test infra:
  - `pump_test_widget.dart` — wraps the widget under test in `AppTheme.lightTheme()` + `MaterialApp` (+ `Scaffold` unless `wrapInScaffold: false`).
  - `mock_cubits.dart` — `MockCubit` classes per cubit (`MockSignInCubit`, `MockCountriesCubit`, …).
  - `mock_api_client.dart` / `mock_auth_repository.dart` — mocktail mocks for the network and repository layers.
  - `hive_test_helper.dart` — opens a plain temp-dir Hive box for code paths that read `AuthHiveBox` / `SettingsHiveBox`.
  - `test_logging.dart` — `printTestDivider(String label)` helper.
- `integration_test/` — full end-to-end flows: real router, real screens, real cubits and repositories, driven on a device/simulator (`flutter test integration_test/auth_flow_test.dart -d <device>`). The network is faked at the Dio adapter level via `FakeApiAdapter` + `ApiClient().httpClientAdapter` (a `@visibleForTesting` seam on `ApiClient`), and Hive runs against a temp dir.

Run everything headless (unit + widget) with `flutter test`. The default
template `test/widget_test.dart` (counter smoke test) was removed — it never
matched this app and always failed.

## Progress

| # | Feature | Unit | Widget | Integration |
|---|---------|------|--------|--------------|
| 1 | auth | ✅ | ✅ | ✅ |
| 2 | home | ✅ | ✅ | ✅ |
| 3 | orders | 🔲 | 🔲 | 🔲 |
| 4 | cash_collection | 🔲 | 🔲 | 🔲 |
| 5 | earnings | 🔲 | 🔲 | 🔲 |
| 6 | wallet | 🔲 | 🔲 | 🔲 |
| 7 | salary | 🔲 | 🔲 | 🔲 |
| 8 | settlement_history | 🔲 | 🔲 | 🔲 |
| 9 | notifications | 🔲 | 🔲 | 🔲 |
| 10 | chat | 🔲 | 🔲 | 🔲 |
| 11 | profile | 🔲 | 🔲 | 🔲 |
| 12 | main / splash | 🔲 | 🔲 | 🔲 |

Mark 🔲 → 🟡 (in progress) → ✅ (done, tests green) per column as we go.

---

## 1. auth — done ✅

`flutter test`: 85 unit + widget tests green. Integration: 10 tests green on
device (`auth_flow_test.dart` 5, `session_flow_test.dart` 5).

### A. Unit tests

**Models** — `AuthModel` / `AuthModelData`
- fromJson: full payload → all fields parsed correctly
- fromJson: null/missing fields → nulls not crash
- fromJson: `status` as bare int vs quoted string (`toSafeIntOrNull` lenient parse)
- toJson: round-trip (fromJson → toJson → same shape)

**Repository (`AuthRepository`)** — mock `ApiClient`
- `login` — sends correct fields (email/password/type=3/fcmToken/platform/languageId), parses `AuthModel`
- `register` — multipart fields built correctly per bonusType/returnBonusType branches (conditional field inclusion), image files attached when path given
- `forgotPassword` — correct field, returns message map
- `changePassword` — correct field mapping (old/new/confirm)
- `getProfile` — GET, parses `AuthModel`
- `addFcmToken` / `updateFcmToken` — correct fields sent
- `logout` — sends stored fcmToken from `AuthHiveBox`
- `getDeliveryBoyStatus` — status as bare int AND quoted string both parse; missing/null status → throws `ApiException`; remark passthrough
- `updateDeliveryBoyStatus` — correct status field
- `deleteAccount` — POST called
- `updateProfile` — conditional field inclusion same as register, image upload

**Cubits (bloc_test)** — mock `AuthRepository`
- `SignInCubit.login`
  - emits [Loading, Loaded] on success; saves session via `AuthHiveBox.saveLoginData`
  - emits [Loading, Error] on `ApiException`
  - `onSuccess`: analytics `eventLogin` fired, userId set on Analytics/Crashlytics/Clarity when `user.data?.id` present; skipped when id null
  - `reset()` → back to Initial
- `SignUpCubit.register`
  - emits [Loading, Loaded] w/ message from response or localized fallback
  - emits [Loading, Error] on failure
  - analytics `eventSignUp` fired on success only
  - `reset()` → Initial
- `AuthCubit`
  - `checkAuth()`: emits Authenticated when `AuthHiveBox.isLoggedIn` true + token non-empty
  - `checkAuth()`: emits Unauthenticated when logged out OR token empty
  - `logout()`: emits Loading → Unauthenticated; clears local auth even if server call throws (swallowed)
- `ForgotPasswordCubit.forgotPassword` — [Loading, Loaded]/[Loading, Error], message fallback
- `ChangePasswordCubit.changePassword` — [Loading, Loaded]/[Loading, Error], message fallback
- `DeleteAccountCubit.deleteAccount` — [Loading, Loaded]; clears `AuthHiveBox` on success
- `LogoutCubit.logout` — [Loading, Loaded]; clears `AuthHiveBox`
- `AddFcmTokenCubit.addFcmToken` / `UpdateFcmTokenCubit.updateFcmToken` — [Loading, Loaded]/[Loading, Error]

### B. Widget tests

- `sign_in_screen.dart` / `login_form.dart`
  - empty email/password → validation error shown, no submit call
  - invalid email format rejected
  - valid input → `SignInCubit.login` called w/ entered values
  - loading state → button shows spinner / disabled
  - error state → error message/snackbar shown
  - success → navigates to home
- `sign_up_screen.dart` / `register_form.dart` + `register_credential_fields.dart` + `register_identity_docs.dart`
  - required field validation (name, mobile, password, confirmPassword match)
  - password ≠ confirmPassword → validation error
  - bonusType conditional fields show/hide correctly
  - image pickers (profile/national id/driving license) set path on selection
  - submit success → navigates / shows success
  - submit error → error shown, form stays
- `forgot_password_screen.dart`
  - empty email → validation error
  - valid submit → `ForgotPasswordCubit` called, success message shown
  - error → error shown

### C. Integration tests

Real router, real screens, real cubits and repositories; only the network is
faked. Run with `flutter test integration_test/<file> -d <device>`.

`integration_test/auth_flow_test.dart` — getting in:
- **Login success**: session persisted to Hive, sign-in screen left behind.
- **Login rejected**: server message surfaced, stays on sign-in, nothing persisted.
- **Forgot password**: sheet opens from the login form, submits, hits the endpoint.
- **Sign-up validation**: an empty form never reaches the register endpoint.
- **Session persistence**: token survives a full app rebuild (stand-in for a cold start).

`integration_test/session_flow_test.dart` — getting out (logout/delete dialogs
live in the profile feature but drive auth cubits and clear `AuthHiveBox`):
- **Logout success**: endpoint called, session cleared, back on sign-in.
- **Logout cancelled**: no request, session intact.
- **Logout failed**: `LogoutCubit` surfaces the error and keeps the session (unlike `AuthCubit.logout`, which clears regardless).
- **Delete account success**: endpoint called, session cleared, back on sign-in.
- **Delete cancelled**: no request, account intact.

Not covered here: the **blocked-account** flow (`getDeliveryBoyStatus` returning
4). The repository parsing is unit-tested, but the dialog is driven by
`DashboardScreen` — it belongs to the home feature's own integration test.

---

## 2. home — done ✅

`flutter test`: 137 unit + widget tests green. Integration: 8 green on device
(`home_flow_test.dart`). Every file under `lib/features/home/` has its own
test.

### A. Unit
- **Model** (`dashboard_model_test.dart`, 16) — every section of the real
  `/dashboard` payload (profile, today, wallet, cash, salary, orders, status
  breakdown, returns + nested breakdown, earnings trend, recent cash,
  withdrawals), plus a missing `data` block, an empty `data` block, and a
  `toJson` round trip.
- **Repository** (4) — endpoint, default and explicit `trend` query, error
  propagation.
- **Cubits** (14) — `DashboardCubit` (5, incl. refresh-after-error);
  `DeliveryBoyStatusCubit` (9, incl. the optimistic toggle, API-error rollback,
  silent rollback on an unexpected error, blocked no-op, and no-op before a
  status is loaded).
- **Socket service** (12) — `MaintenanceSocketService` driven against a real
  local WebSocket server rather than a mock (point `broadcast_config` at
  127.0.0.1 and the service resolves to it): handshake → subscribe, ping/pong
  keepalive, toggle on/off, persistence to the settings box, ignoring another
  surface's toggle, remark language fallback, malformed frames, no-key skip,
  duplicate connect, reconnect after disconnect.

### B. Widget (91)
Stat card/column, order status grid, return-requests card, earnings trend card
(+ `trendValueForPeriod`), dashboard list card, home header + profile row,
toggle-status dialog, account-blocked dialog, overview section (rate maths,
zero-total guards, clamping, status-7 filtering), performance section, the
charts and skeleton loader (`active_status_chart`, `return_requests_pie_chart`,
`earnings_line_chart`, `dashboard_skeleton_loader`), the maintenance scheduled
dialog (19: window logic, once-per-session, dismissal, countdown, duration
wording), and `dashboard_screen` itself (13: initial fetches, skeleton, loaded,
error, header persistence across states, offline swap, online/offline mapping,
toggle dialog, blocked dialog, pull-to-refresh).

### C. Integration (`integration_test/home_flow_test.dart`)
Dashboard loads and renders; default trend window; header reflects server
status (online and offline); status toggle persists and flips the header;
blocked account raises the dialog; acknowledging it clears the session and
returns to sign-in; a failed fetch shows the error state without crashing.

### Bugs found and fixed
`DashboardScreen`'s error branch used `SliverFillRemaining(hasScrollBody:
false)` around `EmptyStateWidget`, whose root is a `LayoutBuilder`. The sliver
measures its child's intrinsic height, which a `LayoutBuilder` cannot provide —
so **every failed dashboard fetch** threw "LayoutBuilder does not support
returning intrinsic dimensions" and then a null-check crash in the viewport.
Reproduced in isolation with just those two widgets. Fixed by switching to
`hasScrollBody: true`; both the widget test and the integration test now guard
against it.

`DashboardStatCard`'s inner `Column` overflowed vertically by 1px on a real
device — the row leaves it only as much height as the 32px icon, which the
label + value are within a pixel of once the real (downloaded) font's metrics
differ slightly from the fallback's. It rendered the debug overflow stripes and
only reproduced on device, never in widget tests. Fixed by making the column
`mainAxisSize.min` with both lines `Flexible`, so they give way instead of
overflowing.

### Still open (backend/model mismatches, not fixed)
- `DashboardDataModel.fromJson` reads `recent_fund_transfers`, but the API
  sends `recent_settlements`, so `recentFundTransfers` is always null. Its
  `id` also arrives as a String (`"W-34"`) into an `int?` field, and
  `entry_type` isn't parsed. Latent — nothing in the UI reads the list yet.
- `EarningsTrend.data` is `List<int>` and rounds every point (`526.25 → 526`,
  `96.7 → 97`), so the chart loses the paise that `total` keeps.

---

## 3–12. Other features

Same 3-layer shape as auth and home for each (write detailed checklist just before that
feature starts — avoids drift if repo/model shape changes meanwhile):

1. **Unit**
   - Models — fromJson/toJson edge cases (nulls, lenient int/double parse)
   - Repository — mock `ApiClient`, verify endpoint + params per method
   - Cubit — bloc_test, verify emitted state sequence per `BaseAsyncCubit`/paginated-list-cubit pattern, verify side effects (Hive writes, analytics)
2. **Widget** — validation, loading/error/success UI states, key interactions (tap, scroll/pagination, pull-to-refresh)
3. **Integration** — real navigation through the feature's primary user journey end-to-end (list → detail → action → result), mocked API layer only

Update progress table + write that feature's checklist section as it starts.

## Conventions (apply to every test file, from file 1)

1. Every `expect()` preceded by `print('expected: X, actual: Y')`.
2. Every `testWidgets`/`test` body opens `printTestDivider('<Widget/Unit> — what this checks')`.
3. `tearDownAll` → `GetIt.instance.reset()` if `setUpAll` registered anything.
4. Bounded `pump()` over `pumpAndSettle()` wherever a screen has looping/long animation (check widget source first).
5. Read full widget/cubit source before writing assertions — no guessing constructor params, callbacks, or `context.read<T>()` deps.
6. Integration tests never hit real network — swap `ApiClient().httpClientAdapter` for a `FakeApiAdapter`; use a temp Hive dir per test run.

## Gotchas found while writing the auth suite

- **`AppText(isRequired: true)` renders a `RichText` with a trailing `" *"`**, so `find.text(key)` misses it. Match on the widget instead: `find.byWidgetPredicate((w) => w is AppText && w.text == key)`.
- **Translations aren't loaded under `flutter test`**, so `LocalizationService.translate` returns the raw key. Assert against `LanguageLabelKeys.<key>` (e.g. `'email_required'`), not English copy. Integration tests call `LocalizationService.instance.loadFromAssets()` first, so those *do* see real English text.
- **`BaseAsyncCubit.run` swallows `onSuccess` failures** (wrapped in its own try/catch), so Firebase Analytics/Crashlytics/Clarity calls throwing `MissingPluginException` in tests never turn a success into an error state — no platform-channel mocks needed for cubit tests.
- **Anything touching `AuthHiveBox`/`SettingsHiveBox` needs an open box**, or it throws `HiveError: Box not found`. Includes non-obvious paths: `AuthRepository.logout` (reads the stored FCM token) and the register form's password checklist (`PasswordPolicy.fromSettings`).
- **The register form is far taller than the default 800×600 test surface.** Pin `tester.view.physicalSize` *and* `tester.view.devicePixelRatio = 1.0` — `physicalSize` alone is divided by a default ratio of 3.0, silently giving a third of the intended logical height.
- **`SignInScreen._onLogin` does not call `_formKey.currentState!.validate()`** — the login button submits whatever is typed and the server rejects it. Widget tests assert the validators through an explicit `Form.validate()` rather than pretending the button gates submission.
- **`AuthModelData.cashReceived` is `int?` while the API sends a double** (`15996.84` → `15996`). Tests document the truncation as current behavior; change the model to `double?` if the fractional part matters.

- **A screen whose `initState` reaches `NotificationService` needs Firebase faked.** `NotificationService.instance` builds `FirebaseMessaging.instance` in a field initializer, so merely touching the singleton throws `[core/no-app]`. Mocking the raw platform channels does *not* work — `firebase_core` talks over Pigeon channels now, and `Firebase.app()` reads a registered-apps map. `test/helpers/firebase_test_helper.dart` swaps `FirebasePlatform.instance` and `FirebaseMessagingPlatform.instance` for fakes instead; call `await FirebaseTestHelper.setUp()` in `setUpAll`.
- **Re-pumping the same widget after re-stubbing a mock cubit does not rebuild it.** Asserting two different states in one test silently checks the first one twice — split them into separate tests.
- **`RefreshIndicator` needs a scroll view that can actually move.** With a viewport tall enough to fit all the content, the scrollable never leaves its idle state and the pull is a silent no-op (the refetch just never happens). Give that one test a short viewport, and drive the gesture by hand (`startGesture` → repeated `moveBy` → `up`) — `drag()`/`fling()` can finish before the indicator arms.
- **Watch the viewport width too.** Shrinking it to make a list scrollable can push a header `Row` into a "RenderFlex overflowed" assert that has nothing to do with what's being tested.
- **`google_fonts` will hang any test that lets real wall-clock time pass.** The theme's text styles come from `google_fonts`, which falls back to *downloading* a font file when it isn't bundled. Under `flutter test` that request never resolves, so a test containing a `runAsync` block stalls the runner with no failure message at all. `pumpTestWidget` now sets `GoogleFonts.config.allowRuntimeFetching = false` for every widget test.
- **Popping a dialog that is the only route hangs the runner.** A handler ending in `AppNavigator.pop` empties the Navigator when the dialog was pumped directly. Open such dialogs through their real entry point (`showDialog`/`maybeShow`) from a host screen instead.
- **A Hive write started inside a widget test never completes.** The test's fake clock never runs the event loop the write finishes on, so the pending future then blocks `tearDown`'s `box.close()` forever — again with no failure message. Neither `runAsync` nor extra pumps rescue it, because the future belongs to the test's own zone. Assert storage side effects in a plain `test()` instead, and keep fire-and-forget writes out of `testWidgets` bodies.
- **Leaving a dialog mounted at test end keeps its timers alive.** Unmount with `pumpWidget(const SizedBox.shrink())` before the test finishes when the widget runs a `Timer.periodic`.

### Integration-test-specific (learned running auth on a real device)

- **`tester.pump(Duration)` does not wait wall-clock time under the live binding**, so an assertion right after a tap sees the pre-response UI even though the fake adapter "already" answered. Wait with `tester.runAsync(() => Future.delayed(...))` and then pump (the `waitForResponse` helper in `auth_flow_test.dart`).
- **Fixtures must be Dart constants, not file reads.** The test runs on the device, where the host's `test/fixtures/` path doesn't exist (`PathNotFoundException`) — and adding it to `pubspec.yaml` assets would ship test JSON inside the real app. `integration_test/helpers/auth_fixtures.dart` mirrors the JSON fixture; keep the two in sync.
- **`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` must run in `setUpAll`**, exactly as `main()` does it — `SignInScreen` reads `FirebaseMessaging.instance` and otherwise throws `[core/no-app]`.
- **Let in-flight requests land before the tree is unmounted.** Teardown mid-request closes the cubits and each pending future then throws `Bad state: Cannot emit new states after calling close`, which is reported as the test failing (see `settleAndUnmount`).
- **Keep a feature's integration test inside that feature's boundary.** Letting login navigate into the real `MainScreen` pulled in dashboard/orders/profile startup — provider lookups, sockets, and a paint-time null check in `dashboard_screen.dart` — and auth flows failed on unrelated home-feature errors. `AuthTestApp` therefore routes `RouteNames.main` to a `PostLoginPlaceholder`; every other route goes through the real `AppRouter`. Do the same per feature.
