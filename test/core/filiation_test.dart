// Valeurs de référence : classeur filiation.xlsx (feuilles 1, 3, 14, 24, 34, 62).
import 'package:calcul_electrique_pro/core/calculs/filiation.dart';
import 'package:calcul_electrique_pro/core/donnees/filiation.dart';
import 'package:calcul_electrique_pro/core/donnees/filiation_merlin_gerin.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tableaux d'une feuille du classeur (deux pour les feuilles à deux blocs).
List<TableFiliation> feuille(int numero) =>
    [for (final t in tablesFiliationMerlinGerin) if (t.numero == numero) t];

void main() {
  group('Contenu des tableaux', () {
    test('64 tableaux issus de 62 feuilles (14 et 25 ont deux blocs)', () {
      expect(tablesFiliationMerlinGerin.length, 64);
      expect(feuille(14).length, 2);
      expect(feuille(25).length, 2);
      expect(feuille(63), isEmpty); // tarif jaune : tableau de texte, non porté
    });

    test('catalogues et tensions', () {
      expect(cataloguesFiliation(),
          ['1998/1999', '2002/2003', '2005', '2009', '2011', '2012']);
      expect(tensionsFiliation('1998/1999'), [230, 400, 440]);
      expect(tensionsFiliation('2011'), [230, 400]);
    });

    test('noms d\'appareils uniques dans chaque tableau (listes déroulantes)', () {
      for (final t in tablesFiliationMerlinGerin) {
        expect(t.amonts.toSet().length, t.amonts.length,
            reason: 'amonts en double, feuille ${t.numero}');
        expect(t.avals.toSet().length, t.avals.length,
            reason: 'avals en double, feuille ${t.numero}');
      }
    });

    test('chaque ligne a autant de valeurs que d\'appareils amont', () {
      for (final t in tablesFiliationMerlinGerin) {
        expect(t.pdcAmont.length, t.amonts.length, reason: 'feuille ${t.numero}');
        expect(t.valeurs.length, t.avals.length, reason: 'feuille ${t.numero}');
        for (final ligne in t.valeurs) {
          expect(ligne.length, t.amonts.length, reason: 'feuille ${t.numero}');
        }
      }
    });
  });

  group('Valeurs du classeur', () {
    test('feuille 1 (230 V, Multi 9, 1998/1999)', () {
      final t = feuille(1).single;
      expect(t.tension, 230);
      expect(t.catalogue, '1998/1999');
      expect(t.pdcDe('C60N'), 20); // D9
      expect(t.renforce('C60N', 'C60a'), 20); // D11
      expect(t.renforce('C60a', 'DPN/DPN N'), 10); // C14
      expect(t.renforce('NG125L', 'NG125N'), 100); // M17
      expect(t.renforce('C60a', 'C60H'), isNull); // C13 vide
    });

    test('feuille 3 (230 V, Compact NS 100 à 250)', () {
      final t = feuille(3).single;
      expect(t.pdcDe('NS100N'), 85); // D9
      expect(t.renforce('NS100N', 'C60N'), 40); // D12
      expect(t.renforce('NS250L', 'NG125L/LMA'), 150); // L20
      expect(t.renforce('NSA160N', 'C60L ≤ 25A'), isNull); // C14 vide
    });

    test('feuille 14 : deuxième bloc (amont NS800L…)', () {
      final blocs = feuille(14);
      expect(blocs[0].amonts.first, 'NS400N');
      expect(blocs[1].amonts, ['NS800L', 'NS1000L', 'NT L1', 'NW L1']);
      expect(blocs[1].renforce('NS800L', 'NS100N'), 150); // K11
      expect(blocs[1].renforce('NW L1', 'NS400N'), 100); // N17
      expect(blocs[1].renforce('NW L1', 'NS1250N'), 100); // N25
    });

    test('feuille 24 (230 V, 2005)', () {
      final t = feuille(24).single;
      expect(t.pdcDe('NS160N'), 85); // J10
      expect(t.renforce('NS160N', 'C60L ≤ 40A'), 65); // J16
      expect(t.renforce('NR160F', 'NG125N'), isNull);
      expect(t.renforce('NS250L', 'NG125L/LMA'), 150); // R21
    });

    test('feuille 34 (230 V, 2009)', () {
      final t = feuille(34).single;
      expect(t.pdcDe('NSX100N'), 90); // F9
      expect(t.renforce('NSX100N', 'DT60N/C60N'), 60); // F13
      expect(t.renforce('NSX160L', 'NSX160S'), 150); // O32
    });

    test('feuilles 37 et 42 : en-têtes sur plusieurs lignes complétés', () {
      final t37 = feuille(37).single;
      expect(t37.amonts, [
        'NS800H', 'NS800L', 'NS1000H', 'NS1000L', 'NS1250H / NS1600H',
        'NS2000N / NS2500N / NS3200N', 'Masterpact / NT L1',
        'Masterpact / NW L1',
      ]);
      expect(t37.pdcDe('Masterpact / NT L1'), 150); // J11
      expect(t37.renforce('Masterpact / NW L1', 'NSX400N'), 100); // K
      expect(t37.renforce('Masterpact / NT L1', 'NSX400N'), 150);

      final t42 = feuille(42).single;
      expect(t42.pdcDe('NS800 à NS1600N'), 50); // C11
      expect(t42.renforce('Masterpact / NW L1', 'NS1250N'), 65);
      expect(t42.renforce('Masterpact / NT L1', 'NS1250N'), isNull);
    });

    test('feuille 62 (parafoudre) : pas de Pdc amont', () {
      final t = feuille(62).single;
      expect(t.pdcDe('NG125L'), isNull);
      expect(t.renforce('NG125L', 'iQuick PRD8r'), 50); // D11
      expect(t.renforce('NSX250L', 'iQuick PRD40r'), 30); // T13
    });
  });

  group('Vérification de la filiation', () {
    final t = feuille(3).single;

    test('assurée : NS100N / C60N, Ik 30 kA (40 kA renforcé, 85 kA amont)', () {
      final r = verifierFiliation(t, 'NS100N', 'C60N', 30);
      expect(r.statut, StatutFiliation.assuree);
      expect(r.pdcRenforce, 40);
      expect(r.pdcAmont, 85);
    });

    test('insuffisante : Ik 45 kA dépasse le Pdc renforcé de 40 kA', () {
      expect(verifierFiliation(t, 'NS100N', 'C60N', 45).statut,
          StatutFiliation.insuffisante);
    });

    test('limite : Ik égal au Pdc renforcé est accepté', () {
      expect(verifierFiliation(t, 'NS100N', 'C60N', 40).statut,
          StatutFiliation.assuree);
    });

    test('aucune filiation prévue', () {
      final r = verifierFiliation(t, 'NSA160N', 'C60L ≤ 25A', 10);
      expect(r.statut, StatutFiliation.aucune);
      expect(r.pdcRenforce, isNull);
    });

    test('Pdc amont insuffisant même si le renforcé convient (feuille 12)', () {
      // NS100H amont (Pdc 65 kA) / NS80H aval : renforcé 130 kA dans le classeur.
      final t12 = feuille(12).single;
      expect(t12.renforce('NS100H', 'NS80H'), 130);
      expect(t12.pdcDe('NS100H'), 65);
      expect(verifierFiliation(t12, 'NS100H', 'NS80H', 100).statut,
          StatutFiliation.insuffisante);
    });

    test('tableau sans Pdc amont : seul le renforcé compte', () {
      final t62 = feuille(62).single;
      expect(verifierFiliation(t62, 'NG125L', 'iQuick PRD8r', 40).statut,
          StatutFiliation.assuree);
      expect(verifierFiliation(t62, 'NG125L', 'iQuick PRD8r', 60).statut,
          StatutFiliation.insuffisante);
    });

    test('amonts possibles pour un aval, avec conclusion', () {
      final liste = amontsPourAval(t, 'C60N', 45);
      expect(liste.map((a) => a.amont).toList(),
          ['NSA160N', 'NS100N', 'NS100H', 'NS100L', 'NS160N', 'NS160H',
            'NS160L', 'NS250N', 'NS250H', 'NS250L']);
      final ns100h = liste.firstWhere((a) => a.amont == 'NS100H');
      expect(ns100h.pdcRenforce, 100);
      expect(ns100h.statut, StatutFiliation.assuree);
      final ns100n = liste.firstWhere((a) => a.amont == 'NS100N');
      expect(ns100n.statut, StatutFiliation.insuffisante);
    });

    test('tableaux d\'un catalogue et d\'une tension', () {
      // 2005 / 230 V : feuilles 22, 24 et 25 (deux blocs) = 4 tableaux.
      expect(tablesFiliation('2005', 230).map((t) => t.numero).toList(),
          [22, 24, 25, 25]);
      // 2012 / 440 V : feuilles 60 et 61.
      expect(tablesFiliation('2012', 440).map((t) => t.numero).toList(),
          [60, 61]);
    });
  });
}
