import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/courant_emploi.dart';

class CourantEmploiEntree {
  const CourantEmploiEntree({
    this.alimentation = Alimentation.triphase,
    this.puissanceKw = 10,
    this.tension = 400,
    this.cosPhi = 0.85,
    this.rendement = 1,
  });

  final Alimentation alimentation;
  final double puissanceKw;
  final double tension;
  final double cosPhi;
  final double rendement;

  CourantEmploiEntree copyWith({
    Alimentation? alimentation,
    double? puissanceKw,
    double? tension,
    double? cosPhi,
    double? rendement,
  }) =>
      CourantEmploiEntree(
        alimentation: alimentation ?? this.alimentation,
        puissanceKw: puissanceKw ?? this.puissanceKw,
        tension: tension ?? this.tension,
        cosPhi: cosPhi ?? this.cosPhi,
        rendement: rendement ?? this.rendement,
      );
}

class CourantEmploiNotifier extends Notifier<CourantEmploiEntree> {
  @override
  CourantEmploiEntree build() => const CourantEmploiEntree();

  void modifier(CourantEmploiEntree Function(CourantEmploiEntree) f) =>
      state = f(state);
}

final courantEmploiEntreeProvider =
    NotifierProvider<CourantEmploiNotifier, CourantEmploiEntree>(
        CourantEmploiNotifier.new);

final courantEmploiResultatProvider = Provider<double>((ref) {
  final e = ref.watch(courantEmploiEntreeProvider);
  return courantEmploi(
    alimentation: e.alimentation,
    puissance: e.puissanceKw * 1000,
    tension: e.tension,
    cosPhi: e.cosPhi,
    rendement: e.rendement,
  );
});
