// Valeurs de référence : NF C 15-100-1 (2024-08), tableaux 55.3 et 55.4.
import 'package:calcul_electrique_pro/core/calculs/demarrage_moteur.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mono = AlimentationMoteur.monophase;
  const tri = AlimentationMoteur.triphase;
  const hab = LocalMoteur.habitation;
  const aut = LocalMoteur.autres;
  const aer = ReseauMoteur.aerien;
  const sou = ReseauMoteur.souterrain;

  test('tableau 55.3 : intensité maximale de démarrage', () {
    expect(intensiteDemarrageMax(mono, hab, aer), 45);
    expect(intensiteDemarrageMax(mono, hab, sou), 45);
    expect(intensiteDemarrageMax(mono, aut, aer), 100);
    expect(intensiteDemarrageMax(mono, aut, sou), 200);
    expect(intensiteDemarrageMax(tri, hab, aer), 60);
    expect(intensiteDemarrageMax(tri, hab, sou), 60);
    expect(intensiteDemarrageMax(tri, aut, aer), 125);
    expect(intensiteDemarrageMax(tri, aut, sou), 250);
  });

  test('tableau 55.4 : puissance maximale des moteurs alimentés directement', () {
    const d = ModeDemarrage.direct;
    const o = ModeDemarrage.autre;
    expect(puissanceMoteurMax(mono, hab, aer, d), 1.4);
    expect(puissanceMoteurMax(mono, hab, sou, o), 1.4);
    expect(puissanceMoteurMax(mono, aut, aer, d), 3);
    expect(puissanceMoteurMax(mono, aut, sou, d), 5.5);
    expect(puissanceMoteurMax(tri, hab, aer, d), 5.5);
    expect(puissanceMoteurMax(tri, hab, aer, o), 11);
    expect(puissanceMoteurMax(tri, aut, aer, d), 11);
    expect(puissanceMoteurMax(tri, aut, aer, o), 22);
    expect(puissanceMoteurMax(tri, aut, sou, d), 22);
    expect(puissanceMoteurMax(tri, aut, sou, o), 45);
  });

  test('vérification : conforme si inférieur ou égal', () {
    final r = verifierDemarrage(
      alimentation: tri,
      local: aut,
      reseau: aer,
      mode: ModeDemarrage.direct,
      intensiteDemarrage: 125,
      puissanceKva: 12,
    );
    expect(r.intensiteConforme, isTrue); // 125 A = limite
    expect(r.puissanceConforme, isFalse); // 12 kVA > 11 kVA
    final sans = verifierDemarrage(
        alimentation: mono, local: hab, reseau: aer, mode: ModeDemarrage.direct);
    expect(sans.intensiteConforme, isNull);
    expect(sans.puissanceConforme, isNull);
  });
}
