// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:shadow_shat/burning_card_with_real_fire.dart';
import 'package:shadow_shat/shadow_chat_screen.dart' show ShadowChatScreen;

import 'package:shadow_shat/main.dart';

Future<void> _openJourneyToFinalDay(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: ShadowChatScreen()));
  expect(find.text('هل تجرأ على فتح الباب؟'), findsOneWidget);
  expect(find.text('DO YOU DARE TO OPEN THE DOOR?'), findsOneWidget);
  expect(find.text('القرار لك... والنتيجة غير مضمونة.'), findsOneWidget);
  expect(
    find.text('THE CHOICE IS YOURS... THE OUTCOME IS NOT GUARANTEED.'),
    findsOneWidget,
  );
  expect(find.text('الرجوع'), findsNothing);
  expect(find.text('GO BACK'), findsNothing);
  expect(find.byKey(const ValueKey('exit-door')), findsOneWidget);
  expect(find.byKey(const ValueKey('door-card-burn-effect')), findsOneWidget);
  expect(find.text('ENTER'), findsOneWidget);
  expect(find.text('RETREAT'), findsOneWidget);
  expect(
    tester.getSize(find.byKey(const ValueKey('open-door'))),
    tester.getSize(find.byKey(const ValueKey('exit-door'))),
  );
  expect(find.byKey(const ValueKey('shadow-door-frame')), findsNothing);
  expect(find.byKey(const ValueKey('shadow-door-image-left')), findsNothing);
  expect(find.byKey(const ValueKey('shadow-door-image-right')), findsNothing);
  expect(find.byKey(const ValueKey('shadow-chat-input')), findsNothing);

  await tester.tap(find.byKey(const ValueKey('open-door')));
  await tester.pumpAndSettle();
  expect(find.text('اليوم الأول • المرحلة الأولى'), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-chat-input')), findsOneWidget);
  expect(find.byKey(const ValueKey('shadow-chat-send')), findsOneWidget);

  const nextDayTitles = [
    'اليوم الثاني • المرحلة الثانية',
    'اليوم الثالث • المرحلة الثالثة',
    'اليوم الرابع • المرحلة الرابعة',
  ];
  for (final title in nextDayTitles) {
    await tester.tap(find.byKey(const ValueKey('next-day')));
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget);
  }
}

void main() {
  testWidgets('burn effect animates the card away', (
    WidgetTester tester,
  ) async {
    final controller = AnimationController(
      vsync: tester,
      duration: const Duration(seconds: 1),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: BurningCardWithRealFire(
            key: const ValueKey('burn-effect-test'),
            controller: controller,
            child: const Text('door card'),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const ValueKey('burn-effect-test')),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      1,
    );

    controller.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final middleOpacity = tester
        .widget<Opacity>(
          find.descendant(
            of: find.byKey(const ValueKey('burn-effect-test')),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
    expect(middleOpacity, greaterThan(0));
    expect(middleOpacity, lessThan(1));
    expect(
      tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byKey(const ValueKey('burn-effect-test')),
              matching: find.byType(CustomPaint),
            ),
          )
          .foregroundPainter,
      isA<RealFirePainter>(),
    );

    expect(
      tester
          .widget<ClipPath>(
            find.descendant(
              of: find.byKey(const ValueKey('burn-effect-test')),
              matching: find.byType(ClipPath),
            ),
          )
          .clipper,
      isNotNull,
    );

    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const ValueKey('burn-effect-test')),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0,
    );
  });

  test('duplicate Firebase initialization is ignored safely', () {
    final duplicateError = FirebaseException(
      plugin: 'firebase_core',
      code: 'duplicate-app',
      message: 'A Firebase App named "[DEFAULT]" already exists',
    );

    expect(isDuplicateFirebaseInitializationError(duplicateError), isTrue);
    expect(
      isDuplicateFirebaseInitializationError(
        FirebaseException(
          plugin: 'firebase_core',
          code: 'unknown',
          message: 'other error',
        ),
      ),
      isFalse,
    );
  });

  test(
    'Firebase web config falls back to demo mode when placeholder is used',
    () {
      const webAppId = '1:525641785110:web:abcdef123456';
      expect(
        hasUsableFirebaseWebConfig('REPLACE_WITH_WEB_API_KEY', webAppId),
        isFalse,
      );
      expect(hasUsableFirebaseWebConfig('abc123validkey', webAppId), isTrue);
      expect(hasUsableFirebaseWebConfig('', webAppId), isFalse);
      expect(
        hasUsableFirebaseWebConfig(
          'abc123validkey',
          '1:525641785110:android:abcdef123456',
        ),
        isFalse,
      );
    },
  );

  test('Firebase add failures expose the real error code', () {
    expect(
      firebaseWriteFailureMessage(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      ),
      contains('permission-denied'),
    );
  });

  test('regular contact action blocks duplicate request states', () {
    expect(
      determineRegularContactAction(myStatus: 'pending', otherStatus: 'none'),
      'pending',
    );
    expect(
      determineRegularContactAction(myStatus: 'none', otherStatus: 'incoming'),
      'incoming',
    );
    expect(
      determineRegularContactAction(myStatus: 'accepted', otherStatus: 'none'),
      'accepted',
    );
    expect(
      determineRegularContactAction(myStatus: 'rejected', otherStatus: 'none'),
      'rejected',
    );
  });

  test('display names are sanitized consistently before saving', () {
    expect(sanitizeDisplayName('   علي   أحمد   '), 'علي أحمد');
    expect(sanitizeDisplayName(''), isEmpty);
  });

  test(
    'secret member removal policy allows group removal and owner-only room removal',
    () {
      expect(
        canRemoveSecretMember(
          isGroup: true,
          ownerVerified: false,
          isOwnerUser: false,
        ),
        isTrue,
      );
      expect(
        canRemoveSecretMember(
          isGroup: false,
          ownerVerified: false,
          isOwnerUser: true,
        ),
        isFalse,
      );
      expect(
        canRemoveSecretMember(
          isGroup: false,
          ownerVerified: true,
          isOwnerUser: true,
        ),
        isTrue,
      );
      expect(
        canRemoveSecretMember(
          isGroup: false,
          ownerVerified: true,
          isOwnerUser: false,
        ),
        isFalse,
      );
    },
  );

  testWidgets('Shadow Chat app starts', (WidgetTester tester) async {
    appLockEnabledNotifier.value = true;
    appLockPasswordNotifier.value = await hashPassword(
      'test-app-lock-password',
    );
    await tester.pumpWidget(const MaterialApp(home: AppLockGate()));

    expect(find.byType(AppLockGate), findsOneWidget);
    expect(find.text('تغيير كلمة سر قفل التطبيق'), findsOneWidget);
  });

  testWidgets('closed door video fills the screen on phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ShadowChatScreen()));
    expect(
      find.byKey(const ValueKey('shadow-door-black-background')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('shadow-door-video-player')),
      findsOneWidget,
    );
    expect(find.byType(VideoPlayer), findsOneWidget);
    final previewSize = tester.getSize(
      find.byKey(const ValueKey('shadow-door-preview')),
    );
    expect(previewSize, const Size(390, 844));
    expect(
      tester
          .widget<FittedBox>(
            find.descendant(
              of: find.byKey(const ValueKey('shadow-door-preview')),
              matching: find.byType(FittedBox),
            ),
          )
          .fit,
      BoxFit.cover,
    );
    expect(find.byKey(const ValueKey('shadow-door-frame')), findsNothing);
    expect(find.byKey(const ValueKey('shadow-door-image-left')), findsNothing);
    expect(find.byKey(const ValueKey('shadow-door-image-right')), findsNothing);
  });

  testWidgets('entering the door triggers a strong haptic impact', (
    WidgetTester tester,
  ) async {
    final platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(const MaterialApp(home: ShadowChatScreen()));
    await tester.tap(find.byKey(const ValueKey('open-door')));
    await tester.pump();

    expect(
      platformCalls,
      contains(
        isA<MethodCall>()
            .having((call) => call.method, 'method', 'HapticFeedback.vibrate')
            .having(
              (call) => call.arguments,
              'arguments',
              'HapticFeedbackType.heavyImpact',
            ),
      ),
    );
  });

  testWidgets('door opens into all stages and the left path ends in doom', (
    WidgetTester tester,
  ) async {
    await _openJourneyToFinalDay(tester);
    expect(find.byKey(const ValueKey('ending-doom')), findsOneWidget);
    expect(find.byKey(const ValueKey('ending-victory')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ending-doom')));
    await tester.pumpAndSettle();
    expect(find.text('هلاك إلى الأبد'), findsOneWidget);
  });

  testWidgets('the right path ends in victory', (WidgetTester tester) async {
    await _openJourneyToFinalDay(tester);

    await tester.tap(find.byKey(const ValueKey('ending-victory')));
    await tester.pumpAndSettle();
    expect(find.text('انتصرت في الرحلة'), findsOneWidget);
  });

  testWidgets('chat list opens the Shadow Chat door screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    firebaseReady = false;
    await tester.pumpWidget(const MaterialApp(home: ChatListScreen()));
    await tester.pump();

    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pumpAndSettle();
    await tester.tap(find.text('محادثة الظل'));
    await tester.pumpAndSettle();

    expect(find.text('هل تجرأ على فتح الباب؟'), findsOneWidget);
    expect(find.text('الرجوع'), findsNothing);
    expect(find.byKey(const ValueKey('exit-door')), findsOneWidget);
  });

  testWidgets('door exit button returns to the previous app page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ShadowChatScreen(),
                  ),
                );
              },
              child: const Text('Open Shadow Chat'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Shadow Chat'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exit-door')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('exit-door')));
    await tester.pumpAndSettle();
    expect(find.text('Open Shadow Chat'), findsOneWidget);
  });

  testWidgets('local demo starts without initializing Firebase', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'startup_intro_seen': true,
      'has_seen_onboarding': true,
    });
    firebaseReady = false;
    appLockEnabledNotifier.value = false;
    await tester.pumpWidget(const ShadowChatApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(ChatListScreen), findsOneWidget);
    expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('محادثة الظل'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('هل تجرأ على فتح الباب؟'), findsOneWidget);
    expect(find.text('الرجوع'), findsNothing);
    expect(find.byKey(const ValueKey('exit-door')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('local demo restores dark mode on startup', () async {
    SharedPreferences.setMockInitialValues({darkModeKey: false});

    await loadAppLockSettings();
    final preferences = await SharedPreferences.getInstance();

    expect(globalDarkModeNotifier.value, isTrue);
    expect(preferences.getBool(darkModeKey), isTrue);
  });
}
