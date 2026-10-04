import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/demarrage_moteur.dart';

class DemarrageEntree {
  const DemarrageEntree({
    this.alimentation = AlimentationMoteur.triphase,
    this.local = LocalMoteur.autres,
    this.reseau = ReseauMoteur.aerien,
    this.mode = ModeDemarrage.direct,
    this.puissanceKva,
    this.intensite,
  });

  final AlimentationMoteur alimentation;
  final LocalMoteur local;
  final ReseauMoteur reseau;
  final ModeDemarrage mode;

  /// Facultatifs : vides, seules les limites du tableau sont affichées.
  final double? puissanceKva;
  final double? intensite;

  DemarrageEntree copyWith({
    AlimentationMoteur? alimentation,
    LocalMoteur? local,
    ReseauMoteur? reseau,
    ModeDemarrage? mode,
    double? puissanceKva,
    double? intensite,
    bool effacerPuissance = false,
    bool effacerIntensite = false,
  }) =>
      DemarrageEntree(
        alimentation: alimentation ?? this.alimentation,
        local: local ?? this.local,
        reseau: reseau ?? this.reseau,
        mode: mode ?? this.mode,
        puissanceKva:
            effacerPuissance ? null : (puissanceKva ?? this.puissanceKva),
        intensite: effacerIntensite ? null : (intensite ?? this.intensite),
      );
}

class DemarrageNotifier extends Notifier<DemarrageEntree> {
  @override
  DemarrageEntree build() => const DemarrageEntree();

  void modifier(DemarrageEntree Function(DemarrageEntree) f) =>
      state = f(state);
}

final demarrageEntreeProvider =
    NotifierProvider<DemarrageNotifier, DemarrageEntree>(DemarrageNotifier.new);

final demarrageResultatProvider = Provider<ResultatDemarrage>((ref) {
  final e = ref.watch(demarrageEntreeProvider);
  return verifierDemarrage(
    alimentation: e.alimentation,
    local: e.local,
    reseau: e.reseau,
    mode: e.mode,
    intensiteDemarrage: e.intensite,
    puissanceKva: e.puissanceKva,
  );
});
