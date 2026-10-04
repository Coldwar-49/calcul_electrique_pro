/// Chute de tension d'une suite de tronçons (cumul, seuils selon tarif/usage).
library;

import 'dart:math' as math;

import '../donnees/sections_resistivites.dart';
import '../donnees/types.dart';

enum SchemaCircuit {
  monophase('Monophasé', 2),
  triphaseEquilibre('Triphasé équilibré', 1),
  triphaseDesequilibre('Triphasé déséquilibré', 2);

  const SchemaCircuit(this.libelle, this.coefficientB);
  final String libelle;

  /// Coefficient b : 1 en triphasé équilibré, 2 sinon.
  final int coefficientB;
}

enum Tarif {
  bleu('Bleu'),
  jaune('Jaune'),
  vert('Vert');

  const Tarif(this.libelle);
  final String libelle;
}

enum UsageCircuit {
  eclairage('Éclairage'),
  force('Force');

  const UsageCircuit(this.libelle);
  final String libelle;
}

/// Seuil de chute de tension cumulée (fraction de U0).
/// Bleu et Jaune (même seuil) : 3 % éclairage, 5 % force.
/// Vert : 6 % éclairage, 8 % force.
double seuilChuteTension(Tarif tarif, UsageCircuit usage) =>
    switch ((tarif, usage)) {
      (Tarif.bleu || Tarif.jaune, UsageCircuit.eclairage) => 0.03,
      (Tarif.bleu || Tarif.jaune, UsageCircuit.force) => 0.05,
      (Tarif.vert, UsageCircuit.eclairage) => 0.06,
      (Tarif.vert, UsageCircuit.force) => 0.08,
    };

/// Majoration du seuil pour de grandes longueurs (NF C 15-100-1 2024, tableau
/// 52.23) : 0,005 % par mètre de canalisation principale au-delà de 100 m,
/// sans dépasser 0,5 %. Retourne une fraction de U0 (0,005 = 0,5 %).
double majorationSeuilLongueur(double longueurPrincipale) {
  final surplus = longueurPrincipale - 100;
  if (surplus <= 0) return 0;
  final m = surplus * 0.00005;
  return m > 0.005 ? 0.005 : m;
}

class LigneChuteTension {
  const LigneChuteTension({
    this.circuit = SchemaCircuit.triphaseEquilibre,
    this.u0 = 230,
    this.section = 2.5,
    this.nbConducteursParPole = 1,
    this.longueur = 20,
    this.ame = Ame.cuivre,
    this.cosPhi = 0.8,
    this.ib = 10,
    this.tarif = Tarif.bleu,
    this.usage = UsageCircuit.eclairage,
  });

  final SchemaCircuit circuit;
  final double u0;
  final double section;
  final int nbConducteursParPole;
  final double longueur;
  final Ame ame;
  final double cosPhi;
  final double ib;
  final Tarif tarif;
  final UsageCircuit usage;

  LigneChuteTension copyWith({
    SchemaCircuit? circuit,
    double? u0,
    double? section,
    int? nbConducteursParPole,
    double? longueur,
    Ame? ame,
    double? cosPhi,
    double? ib,
    Tarif? tarif,
    UsageCircuit? usage,
  }) => LigneChuteTension(
    circuit: circuit ?? this.circuit,
    u0: u0 ?? this.u0,
    section: section ?? this.section,
    nbConducteursParPole: nbConducteursParPole ?? this.nbConducteursParPole,
    longueur: longueur ?? this.longueur,
    ame: ame ?? this.ame,
    cosPhi: cosPhi ?? this.cosPhi,
    ib: ib ?? this.ib,
    tarif: tarif ?? this.tarif,
    usage: usage ?? this.usage,
  );
}

class ResultatChuteTension {
  const ResultatChuteTension({
    required this.deltaU,
    required this.cumulV,
    required this.ratio,
    required this.seuil,
    required this.conforme,
  });

  /// ΔU du tronçon, en volts.
  final double deltaU;

  /// ΔU cumulée depuis le premier tronçon, en volts.
  final double cumulV;

  /// ΔU cumulée / U0 (0,03 = 3 %).
  final double ratio;

  /// Seuil applicable (fraction de U0).
  final double seuil;
  final bool conforme;

  double get pourcent => ratio * 100;
}

/// ΔU = (b / n) × Ib × (ρ × L × cos φ / S + 0,00008 × L × sin φ).
double chuteTensionTroncon(LigneChuteTension l) {
  final phi = math.acos(l.cosPhi);
  final s = corrigerSection(l.section);
  return (l.circuit.coefficientB / l.nbConducteursParPole) *
      l.ib *
      ((rhoChuteTension(l.ame) * l.longueur * l.cosPhi / s) +
          (reactanceLineique * l.longueur * math.sin(phi)));
}

/// Calcule chaque tronçon avec le cumul des tronçons précédents.
///
/// [majorerSeuilLongueur] : applique au seuil la majoration du tableau 52.23
/// selon la longueur totale des tronçons (canalisations principales).
List<ResultatChuteTension> calculerChuteTension(
  List<LigneChuteTension> lignes, {
  bool majorerSeuilLongueur = false,
}) {
  final resultats = <ResultatChuteTension>[];
  final majoration = majorerSeuilLongueur
      ? majorationSeuilLongueur(lignes.fold(0.0, (s, l) => s + l.longueur))
      : 0.0;
  var cumul = 0.0;
  for (final l in lignes) {
    final du = chuteTensionTroncon(l);
    cumul += du;
    final ratio = cumul / l.u0;
    final seuil = seuilChuteTension(l.tarif, l.usage) + majoration;
    resultats.add(
      ResultatChuteTension(
        deltaU: du,
        cumulV: cumul,
        ratio: ratio,
        seuil: seuil,
        conforme: ratio <= seuil,
      ),
    );
  }
  return resultats;
}
