import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dlist/widgets/primary_button.dart';
import 'package:dlist/widgets/custom_text_field.dart';
import 'package:dlist/theme/app_theme.dart';

void main() {
  // Helper : enveloppe un widget dans MaterialApp + Scaffold
  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: Center(child: child)),
      );

  // ── PrimaryButton ────────────────────────────────────────────
  group('PrimaryButton', () {
    testWidgets('affiche le texte fourni', (tester) async {
      await tester.pumpWidget(
        wrap(const PrimaryButton(text: 'Se connecter', onPressed: null)),
      );
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('affiche CircularProgressIndicator quand isLoading=true',
        (tester) async {
      await tester.pumpWidget(
        wrap(const PrimaryButton(
          text: 'Se connecter',
          onPressed: null,
          isLoading: true,
        )),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Se connecter'), findsNothing);
    });

    testWidgets('ne déclenche pas onPressed quand isLoading=true',
        (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        wrap(PrimaryButton(
          text: 'Cliquer',
          onPressed: () => pressed = true,
          isLoading: true,
        )),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(pressed, false);
    });

    testWidgets('déclenche onPressed au tap quand non-loading', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        wrap(PrimaryButton(
          text: 'Cliquer',
          onPressed: () => pressed = true,
        )),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('affiche une icône si fournie', (tester) async {
      await tester.pumpWidget(
        wrap(const PrimaryButton(
          text: 'Avec icône',
          onPressed: null,
          icon: Icons.check,
        )),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('le SizedBox occupe toute la largeur', (tester) async {
      await tester.pumpWidget(
        wrap(const PrimaryButton(text: 'Test', onPressed: null)),
      );
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, double.infinity);
      expect(sizedBox.height, 52);
    });

    testWidgets('pas d\'icône affichée si icon=null', (tester) async {
      await tester.pumpWidget(
        wrap(const PrimaryButton(text: 'Sans icône', onPressed: null)),
      );
      expect(find.byType(Icon), findsNothing);
    });
  });

  // ── CustomTextField ──────────────────────────────────────────
  group('CustomTextField', () {
    testWidgets('affiche le labelText', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
        wrap(CustomTextField(controller: ctrl, labelText: 'Email')),
      );
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('met à jour le controller à la saisie', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
        wrap(CustomTextField(controller: ctrl, labelText: 'Email')),
      );
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(ctrl.text, 'test@example.com');
    });

    testWidgets('affiche une icône de préfixe si fournie', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
        wrap(CustomTextField(
          controller: ctrl,
          labelText: 'Email',
          prefixIcon: Icons.email_outlined,
        )),
      );
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('le champ est de type obscure quand obscureText=true',
        (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(
        wrap(CustomTextField(
          controller: ctrl,
          labelText: 'Mot de passe',
          obscureText: true,
        )),
      );
      // Vérifier via le widget EditableText sous-jacent
      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.obscureText, true);
    });

    testWidgets('appelle validator au submit', (tester) async {
      final ctrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextField(
                controller: ctrl,
                labelText: 'Email',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Champ requis'), findsOneWidget);
    });
  });
}
