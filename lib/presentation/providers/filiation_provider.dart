import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/filiation.dart';
import '../../core/donnees/filiation.dart';

class FiliationEntree {
  const FiliationEntree({
    this.catalogue = '2012',
    this.tension = 400,
    this.tableIndex = 0,
    this.amont,
    this.aval,
    this.ik = 10,
  });

  final String catalogue;
  final int tension;

  /// Indice du tableau parmi ceux du catalogue et de la tension.
  final int tableIndex;
  final String? amont;
  final String? aval;

  /// Courant de court-circuit présumé au point d'installation (kA).
  final double ik;

  /// Tension retenue : la choisie si le catalogue la propose, sinon la 1re.
  int get tensionEffective {
    final tensions = tensionsFiliation(catalogue);
    return tensions.contains(tension) ? tension : tensions.first;
  }

  List<TableFiliation> get tables => tablesFiliation(catalogue, tensionEffective);

  TableFiliation get table =>
      tables[tableIndex < tables.length ? tableIndex : 0];

  String get amontEffectif =>
      table.amonts.contains(amont) ? amont! : table.amonts.first;

  String get avalEffectif =>
      table.avals.contains(aval) ? aval! : table.avals.first;

  FiliationEntree copyWith({double? ik}) => FiliationEntree(
        catalogue: catalogue,
        tension: tension,
        tableIndex: tableIndex,
        amont: amont,
        aval: aval,
        ik: ik ?? this.ik,
      );
}

class FiliationNotifier extends Notifier<FiliationEntree> {
  @override
  FiliationEntree build() => const FiliationEntree();

  /// Changer de catalogue réinitialise le tableau et les appareils.
  void choisirCatalogue(String c) => state = FiliationEntree(
      catalogue: c, tension: state.tension, ik: state.ik);

  void choisirTension(int t) => state = FiliationEntree(
      catalogue: state.catalogue, tension: t, ik: state.ik);

  void choisirTable(int i) => state = FiliationEntree(
      catalogue: state.catalogue,
      tension: state.tensionEffective,
      tableIndex: i,
      ik: state.ik);

  void choisirAmont(String a) => state = FiliationEntree(
      catalogue: state.catalogue,
      tension: state.tensionEffective,
      tableIndex: state.tableIndex,
      amont: a,
      aval: state.avalEffectif,
      ik: state.ik);

  void choisirAval(String a) => state = FiliationEntree(
      catalogue: state.catalogue,
      tension: state.tensionEffective,
      tableIndex: state.tableIndex,
      amont: state.amontEffectif,
      aval: a,
      ik: state.ik);

  void choisirIk(double ik) => state = state.copyWith(ik: ik);
}

final filiationEntreeProvider =
    NotifierProvider<FiliationNotifier, FiliationEntree>(FiliationNotifier.new);
