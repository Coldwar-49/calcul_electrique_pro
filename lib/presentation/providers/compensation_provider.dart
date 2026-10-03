import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/compensation_reactive.dart';

class CompensationEntree {
  const CompensationEntree({
    this.puissanceKw = 100,
    this.cosPhiActuel = 0.8,
    this.cosPhiVise = 0.95,
  });

  final double puissanceKw;
  final double cosPhiActuel;
  final double cosPhiVise;

  CompensationEntree copyWith(
          {double? puissanceKw, double? cosPhiActuel, double? cosPhiVise}) =>
      CompensationEntree(
        puissanceKw: puissanceKw ?? this.puissanceKw,
        cosPhiActuel: cosPhiActuel ?? this.cosPhiActuel,
        cosPhiVise: cosPhiVise ?? this.cosPhiVise,
      );
}

class CompensationNotifier extends Notifier<CompensationEntree> {
  @override
  CompensationEntree build() => const CompensationEntree();

  void modifier(CompensationEntree Function(CompensationEntree) f) =>
      state = f(state);
}

final compensationEntreeProvider =
    NotifierProvider<CompensationNotifier, CompensationEntree>(
        CompensationNotifier.new);

final compensationResultatProvider = Provider<ResultatCompensation>((ref) {
  final e = ref.watch(compensationEntreeProvider);
  return calculerCompensation(
    puissance: e.puissanceKw * 1000,
    cosPhiActuel: e.cosPhiActuel,
    cosPhiVise: e.cosPhiVise,
  );
});
