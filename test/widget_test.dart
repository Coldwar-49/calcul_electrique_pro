import 'package:calcul_electrique_pro/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _ouvrir(WidgetTester tester, Size taille) async {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ProviderScope(child: CalculElectriqueApp()));
}

const _libelles = [
  'Bilan de puissance',
  'Chute de tension',
  'Compensation réactive',
  'Contrainte thermique',
  "Courant d'emploi",
  'Surcharges',
  'Ik max',
  'Ik min',
  'Règle du triangle',
  'Contacts indirects',
  'Filiation',
  'Pouvoir de coupure',
  'Protection TT par DDR',
  'Résistance du PE',
  'Influences externes',
];

void main() {
  testWidgets('surcharges : calibre par défaut puis K manuel', (tester) async {
    await _ouvrir(tester, const Size(1400, 1000));

    // Cuivre, triphasé, mode C, 10 mm², K assisté = 1 -> 73,5 A -> 63 A.
    expect(find.text('Protection contre les surcharges'), findsOneWidget);
    expect(find.text('63'), findsOneWidget);

    await tester.tap(find.text('Manuel'));
    await tester.pump();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Coefficient K'), '0,5');
    await tester.pump();
    expect(find.text('32'), findsOneWidget);
  });

  testWidgets('chute de tension : navigation, ajout de tronçon',
      (tester) async {
    await _ouvrir(tester, const Size(1400, 1000));

    await tester.tap(find.text('Chute de tension').first);
    await tester.pumpAndSettle();
    expect(find.text('Tronçon 1'), findsOneWidget);

    await tester.tap(find.text('Ajouter un tronçon'));
    await tester.pump();
    expect(find.text('Tronçon 2'), findsOneWidget);
  });

  testWidgets('contrainte thermique : cas de référence et crédit auteur',
      (tester) async {
    await _ouvrir(tester, const Size(1400, 1000));

    expect(find.text('Créé par Devismes Fabrice'), findsOneWidget);
    expect(find.textContaining('DevisApps'), findsNothing);

    await tester.tap(find.text('Contrainte thermique').first);
    await tester.pumpAndSettle();
    // 16/16 mm² cuivre, 230 V, 70 m, PR/EPR même canalisation : T = 9,28 s.
    expect(find.text('9,28'), findsOneWidget);
    expect(find.text('Non conforme (T > 5 s)'), findsOneWidget);

    await tester.tap(find.text('Par disjoncteur'));
    await tester.pump();
    // 10 kA : T = 0,0523 s.
    expect(find.text('0,0523'), findsOneWidget);
    expect(find.text('Conforme (T ≤ 5 s)'), findsOneWidget);
  });

  testWidgets('Ik max : TGBT du cas de référence', (tester) async {
    await _ouvrir(tester, const Size(1400, 1100));

    await tester.tap(find.text('Ik max').first);
    await tester.pumpAndSettle();
    // 500 MVA, Dyn 630 kVA 4 %, 6 m de 25 mm² cuivre : Ik3 = 18,24 kA.
    // Affiché dans le panneau de résultat et dans le tableau des points.
    expect(find.text('18,24'), findsNWidgets(2));

    await tester.ensureVisible(find.text('Ajouter une liaison'));
    await tester.pump();
    await tester.tap(find.text('Ajouter une liaison'));
    await tester.pump();
    expect(find.text('Liaison TD1 → TD2'), findsOneWidget);
  });

  testWidgets('Ik max : listes P transfo / Ucc / U0 et « Autre valeur »',
      (tester) async {
    await _ouvrir(tester, const Size(1400, 1100));
    await tester.tap(find.text('Ik max').first);
    await tester.pumpAndSettle();

    expect(find.text('400 V'), findsOneWidget);
    expect(find.text('630 kVA'), findsOneWidget);
    expect(find.text('4 %'), findsOneWidget);
    expect(find.text('Valeur personnalisée'), findsNothing);

    // Liste des tensions : 230 / 240 / 400 / 410.
    await tester.tap(find.text('400 V'));
    await tester.pumpAndSettle();
    for (final t in ['230 V', '240 V', '410 V']) {
      expect(find.text(t), findsWidgets);
    }
    await tester.tap(find.text('410 V').last);
    await tester.pumpAndSettle();
    expect(find.text('410 V'), findsOneWidget);

    // « Autre valeur… » sur la puissance fait apparaître la saisie libre.
    await tester.tap(find.text('630 kVA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autre valeur…').last);
    await tester.pumpAndSettle();
    expect(find.text('Valeur personnalisée'), findsOneWidget);
  });

  testWidgets('chute de tension : tarifs Bleu, Jaune et Vert', (tester) async {
    await _ouvrir(tester, const Size(1400, 1100));
    await tester.tap(find.text('Chute de tension').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bleu'));
    await tester.pumpAndSettle();
    expect(find.text('Jaune'), findsWidgets);
    expect(find.text('Vert'), findsWidgets);
  });

  testWidgets('tarif partagé entre Ik max et chute de tension', (tester) async {
    await _ouvrir(tester, const Size(1400, 1100));

    await tester.tap(find.text('Ik max').first);
    await tester.pumpAndSettle();
    expect(find.text('Bleu'), findsOneWidget);

    await tester.tap(find.text('Bleu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jaune').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chute de tension').first);
    await tester.pumpAndSettle();
    expect(find.text('Jaune'), findsOneWidget);
    expect(find.text('Bleu'), findsNothing);
  });

  testWidgets('Ik min : transformateur puis groupe électrogène', (tester) async {
    await _ouvrir(tester, const Size(1400, 1200));

    await tester.tap(find.text('Ik min').first);
    await tester.pumpAndSettle();
    expect(find.text('Courant de défaut minimal (Ik min)'), findsOneWidget);
    expect(find.text('Réseau amont et transformateur'), findsOneWidget);
    // Par défaut la 2e liaison (30 m, 10 mm², C 40 A) est protégée par DJ TD1.
    expect(find.text('Assurée (DJ TD1)'), findsWidgets);
    expect(find.text('Sans protection'), findsWidgets);

    await tester.tap(find.text('Groupe électrogène'));
    await tester.pumpAndSettle();
    expect(find.text('Réactance transitoire x\'d'), findsOneWidget);
    expect(find.text('Disjoncteur GE'), findsOneWidget);
    expect(find.text('Sans protection'), findsNothing);
  });

  testWidgets('Contacts indirects : disjoncteur, fusible et avertissements',
      (tester) async {
    await _ouvrir(tester, const Size(1400, 1400));

    await tester.tap(find.text('Contacts indirects').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('ne remplace ni un logiciel de calcul agréé'),
        findsOneWidget);
    // C 10 A, 2,5 mm² cuivre, 230 V, TN : 0,8·230·2,5/(2·0,023·10·10) = 100 m.
    expect(find.text('100,0'), findsWidgets);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);

    // Fusible aM, Sph ≠ Spe : deux avertissements (coefficient 1,88).
    await tester.tap(find.text('Fusible'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sph ≠ Spe'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    await tester.tap(find.text('gG'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('aM').last);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.textContaining('1,88'), findsWidgets);
  });

  testWidgets('Influences externes : niveaux par défaut puis immersion',
      (tester) async {
    await _ouvrir(tester, const Size(1400, 1600));

    await tester.tap(find.text('Influences externes').first);
    await tester.pumpAndSettle();
    // Niveaux par défaut : les 8 câbles conviennent, 6 conduits sur 9.
    expect(find.text('8 / 8'), findsOneWidget);
    expect(find.text('6 / 9'), findsOneWidget);
    expect(find.text('Hors usage courant'), findsNWidgets(3));

    // AD7 (immersion) : H05VVF (AD > 6) et H05RNF (AD > 5) ne conviennent plus.
    await tester.tap(find.text('AD1 — Négligeable'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AD7 — Immersion').last);
    await tester.pumpAndSettle();
    expect(find.text('6 / 8'), findsOneWidget);
    expect(find.textContaining('Toléré si immersion limitée'), findsOneWidget);
  });

  testWidgets('Filiation : tableau, appareils et conclusion', (tester) async {
    await _ouvrir(tester, const Size(1400, 1400));

    await tester.tap(find.text('Filiation').first);
    await tester.pumpAndSettle();
    expect(find.text('Filiation').first, findsOneWidget);
    // Par défaut : 2012, 400 V, premier tableau, premiers appareils, Ik 10 kA.
    expect(find.textContaining('Pouvoir de coupure renforcé de'),
        findsOneWidget);
    expect(find.textContaining('Amonts possibles pour'), findsOneWidget);

    // Changer le catalogue recharge les tableaux sans erreur.
    await tester.tap(find.text('Année 2012'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Année 1998/1999').last);
    await tester.pumpAndSettle();
    expect(find.text('Année 1998/1999'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pouvoir de coupure : IT, fusibles, disjoncteurs moteurs',
      (tester) async {
    await _ouvrir(tester, const Size(1400, 1400));

    await tester.tap(find.text('Pouvoir de coupure').first);
    await tester.pumpAndSettle();
    // DT 40 : 2 kA, Id2 = 3 kA par défaut -> insuffisant.
    expect(find.text('Pouvoir de coupure insuffisant (Id2 = 3 kA)'),
        findsOneWidget);

    // Fusibles gG 16 A, 8,5 x 31,5 : 20 kA, Ik 10 kA -> suffisant.
    await tester.tap(find.text('Fusibles'));
    await tester.pumpAndSettle();
    expect(find.text('Pouvoir de coupure suffisant (Ik = 10 kA)'),
        findsOneWidget);
    expect(find.text('Fusibles à couteaux'), findsOneWidget);

    // Disjoncteurs moteurs : GV2 ME 01 à 08, 10, 14 = 100 kA.
    await tester.tap(find.text('Disj. moteurs'));
    await tester.pumpAndSettle();
    expect(find.text('Pdc — GV2 ME 01 à 08, 10, 14'), findsOneWidget);
    expect(find.text('Pouvoir de coupure suffisant (Ik = 10 kA)'),
        findsOneWidget);
  });

  testWidgets('Résistance du PE : disjoncteur puis fusibles', (tester) async {
    await _ouvrir(tester, const Size(1400, 1200));

    await tester.tap(find.text('Résistance du PE').first);
    await tester.pumpAndSettle();
    // 230 V, courbe C, 10 A, Sph/Spe ≤ 1 : 1150 mΩ en TN.
    expect(find.text('1150,0'), findsWidgets);
    expect(find.text('575,0'), findsOneWidget); // ITAN

    await tester.tap(find.text('Fusible'));
    await tester.pumpAndSettle();
    // Fusible gG 10 A (Ia = 83,94 A) : tableau terminaux / divisionnaires.
    expect(find.text('Type de fusible'), findsOneWidget);
    expect(find.text('Divisionnaires (mΩ)'), findsOneWidget);
    expect(find.text('Courant de fusion Ia'), findsOneWidget);
  });

  testWidgets('règle du triangle : cas de référence', (tester) async {
    await _ouvrir(tester, const Size(1400, 1100));

    await tester.tap(find.text('Règle du triangle').first);
    await tester.pumpAndSettle();
    // Courbe C, 63 A, S1 10 mm², S2 4 mm² à 30 m : 13,40 m, 10 m distribués.
    expect(find.text('13,40'), findsOneWidget);
    expect(find.text('Conforme : 10 m distribués'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Longueur distribuée de S2'), '14');
    await tester.pump();
    expect(find.text('Non conforme : 14 m distribués'), findsOneWidget);
  });

  testWidgets('menu à gauche : rubriques et entrées par ordre alphabétique',
      (tester) async {
    const rubriques = ['CIRCUITS', 'COURT-CIRCUIT', 'PROTECTION', 'RÉFÉRENCES'];
    const entrees = [
      'Bilan de puissance',
      'Chute de tension',
      'Compensation réactive',
      'Contrainte thermique',
      "Courant d'emploi",
      'Dimensionnement',
      'Surcharges',
      'Ik max',
      'Ik min',
      'Règle du triangle',
      'Contacts indirects',
      'Filiation',
      'Pouvoir de coupure',
      'Protection TT par DDR',
      'Résistance du PE',
      'Influences externes',
    ];
    final menu = find.byKey(const ValueKey('menu-lateral'));

    // Fenêtre large : menu fixe à gauche, rubriques puis entrées.
    await _ouvrir(tester, const Size(1400, 1300));
    expect(tester.getTopLeft(menu).dx, 0);
    final textes = [
      for (final t in tester.widgetList<Text>(
          find.descendant(of: menu, matching: find.byType(Text))))
        if (t.data != null) t.data!,
    ];
    expect([for (final t in textes) if (rubriques.contains(t)) t], rubriques);
    expect([for (final t in textes) if (entrees.contains(t)) t], entrees);
    // Ordre complet : chaque rubrique est suivie de ses entrées.
    expect(textes.indexOf('CIRCUITS'), lessThan(textes.indexOf('Bilan de puissance')));
    expect(textes.indexOf('Surcharges'), lessThan(textes.indexOf('COURT-CIRCUIT')));
    expect(textes.indexOf('Résistance du PE'),
        lessThan(textes.indexOf('RÉFÉRENCES')));

    // Fenêtre étroite (600 à 900 px) : menu fixe à gauche, icônes seules.
    await _ouvrir(tester, const Size(700, 1300));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(menu).dx, 0);
    expect(tester.getSize(menu).width, 80);
    final infobulles = [
      for (final t in tester.widgetList<Tooltip>(
          find.descendant(of: menu, matching: find.byType(Tooltip))))
        t.message!,
    ];
    expect(infobulles, entrees);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu à gauche : défile dans une fenêtre basse, dernière entrée atteignable',
      (tester) async {
    // 1400 x 360 : bien trop bas pour 11 entrées et 4 rubriques.
    await _ouvrir(tester, const Size(1400, 360));
    expect(tester.takeException(), isNull);

    final menu = find.byKey(const ValueKey('menu-lateral'));
    // La dernière entrée n'est pas encore affichée (liste défilante)…
    final derniere =
        find.descendant(of: menu, matching: find.text('Influences externes'));
    expect(derniere, findsNothing);
    // …mais on peut y accéder en faisant défiler le menu,
    await tester.scrollUntilVisible(derniere, 100,
        scrollable:
            find.descendant(of: menu, matching: find.byType(Scrollable)));
    await tester.pumpAndSettle();
    expect(derniere, findsOneWidget);
    expect(tester.getTopLeft(derniere).dy, lessThan(360));
    // …et le crédit reste visible en bas, sans défilement.
    final credit = find.descendant(
        of: menu, matching: find.text('Créé par Devismes Fabrice'));
    expect(credit, findsOneWidget);
    expect(tester.getTopLeft(credit).dy, lessThan(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('téléphone : menu latéral, 15 écrans sans débordement',
      (tester) async {
    await _ouvrir(tester, const Size(390, 844));

    expect(find.byKey(const ValueKey('menu-lateral')), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    for (var i = 0; i < 15; i++) {
      // Ouvre le menu depuis le bandeau de l'écran affiché, puis choisit l'écran i.
      await tester.tap(find.byTooltip('Menu').first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.descendant(
              of: find.byType(Drawer),
              matching: find.text(_libelles[i])),
          100,
          scrollable: find.descendant(
              of: find.byType(Drawer), matching: find.byType(Scrollable)));
      await tester.tap(find.descendant(
          of: find.byType(Drawer), matching: find.text(_libelles[i])));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'écran $i');
    }
  });
}
