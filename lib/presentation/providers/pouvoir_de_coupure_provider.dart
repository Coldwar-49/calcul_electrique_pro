import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/pouvoir_de_coupure.dart';
import '../../core/donnees/fusibles.dart';
import '../../core/donnees/pouvoir_de_coupure.dart';

enum TablePdc {
  it('IT 1 pôle'),
  fusibles('Fusibles'),
  moteurs('Disj. moteurs');

  const TablePdc(this.libelle);
  final String libelle;
}

class PdcEntree {
  const PdcEntree({
    this.table = TablePdc.it,
    this.id2 = 3,
    this.gamme = 0,
    this.typeFusible = TypeFusible.gg,
    this.calibre = 16,
    this.taille,
    this.ik = 10,
    this.moteur = 0,
  });

  final TablePdc table;

  /// Courant de double défaut sous un pôle (kA), table IT.
  final double id2;

  /// Indice de la gamme IT.
  final int gamme;
  final TypeFusible typeFusible;
  final double calibre;

  /// Libellé de la taille de fusible choisie (peut ne plus convenir au calibre).
  final String? taille;

  /// Courant de court-circuit présumé (kA), fusibles et disjoncteurs moteurs.
  final double ik;
  final int moteur;

  /// Tailles de fusibles qui conviennent au type et au calibre.
  List<TailleFusible> get taillesValides =>
      taillesPourCalibre(typeFusible, calibre);

  /// Taille retenue : la choisie si elle convient, sinon la première valide.
  TailleFusible? get tailleEffective {
    final valides = taillesValides;
    if (valides.isEmpty) return null;
    return valides.firstWhere((t) => t.libelle == taille,
        orElse: () => valides.first);
  }

  PdcEntree copyWith({
    TablePdc? table,
    double? id2,
    int? gamme,
    TypeFusible? typeFusible,
    double? calibre,
    String? taille,
    double? ik,
    int? moteur,
  }) =>
      PdcEntree(
        table: table ?? this.table,
        id2: id2 ?? this.id2,
        gamme: gamme ?? this.gamme,
        typeFusible: typeFusible ?? this.typeFusible,
        calibre: calibre ?? this.calibre,
        taille: taille ?? this.taille,
        ik: ik ?? this.ik,
        moteur: moteur ?? this.moteur,
      );
}

class PdcNotifier extends Notifier<PdcEntree> {
  @override
  PdcEntree build() => const PdcEntree();

  void modifier(PdcEntree Function(PdcEntree) f) => state = f(state);
}

final pdcEntreeProvider =
    NotifierProvider<PdcNotifier, PdcEntree>(PdcNotifier.new);
