import 'package:audiodockr/screens/settings/pages/profile_pages.dart';
import 'package:audiodockr/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('cyberpunk profile page renders key sections',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'display_name': 'Audio Dockr',
      'profile_image_mode': 'none',
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: appTheme,
          home: const AccountProfilePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('// IDENTITY'), findsOneWidget);
    expect(find.text('// CURRENT AVATAR'), findsOneWidget);
    expect(find.text('// IMAGE CONFIG'), findsOneWidget);
    expect(find.text('DISPLAY NAME'), findsOneWidget);
    expect(find.text('UPLOAD IMAGE'), findsOneWidget);
    expect(find.text('DELETE IMAGE'), findsOneWidget);
    expect(find.text('NEURAL LINK ACTIVE'), findsOneWidget);
  });
}
