import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/bilan_puissance.dart';
import '../../core/calculs/courant_emploi.dart';

class LigneBilanSaisie {
  const LigneBilanSaisie({
    required this.id,
    this.nom = '',
    this.puissanceKw = 1,
    this.ku = 1,
    this.ks = 1,
  });

  final int id;
  final String nom;
  final double puissanceKw;
  final double ku;
  final double ks;

  LigneBilanSaisie copyWith(
          {String? nom, double? puissanceKw, double? ku, double? ks}) =>
      LigneBilanSaisie(
        id: id,
        nom: nom ?? this.nom,
        puissanceKw: puissanceKw ?? this.puissanceKw,
        ku: ku ?? this.ku,
        ks: ks ?? this.ks,
      );
}

class BilanEntree {
  const BilanEntree({
    required this.lignes,
    this.ksGlobal = 1,
    this.alimentation = Alimentation.triphase,
    this.tension = 400,
    this.cosPhi = 0.85,
    this.prochainId = 3,
  });

  final List<LigneBilanSaisie> lignes;
  final double ksGlobal;
  final Alimentation alimentation;
  final double tension;
  final double cosPhi;
  final int prochainId;

  BilanEntree copyWith({
    List<LigneBilanSaisie>? lignes,
    double? ksGlobal,
    Alimentation? alimentation,
    double? tension,
    double? cosPhi,
    int? prochainId,
  }) =>
      BilanEntree(
        lignes: lignes ?? this.lignes,
        ksGlobal: ksGlobal ?? this.ksGlobal,
        alimentation: alimentation ?? this.alimentation,
        tension: tension ?? this.tension,
        cosPhi: cosPhi ?? this.cosPhi,
        prochainId: prochainId ?? this.prochainId,
      );
}

class BilanNotifier extends Notifier<BilanEntree> {
  @override
  BilanEntree build() => const BilanEntree(lignes: [
        LigneBilanSaisie(id: 1, nom: 'Circuit 1', puissanceKw: 10, ku: 0.8),
        LigneBilanSaisie(id: 2, nom: 'Circuit 2', puissanceKw: 5),
      ]);

  void modifier(BilanEntree Function(BilanEntree) f) => state = f(state);

  void modifierLigne(int id, LigneBilanSaisie Function(LigneBilanSaisie) f) =>
      state = state.copyWith(
          lignes: [for (final l in state.lignes) l.id == id ? f(l) : l]);

  void ajouter() => state = state.copyWith(
        lignes: [
          ...state.lignes,
          LigneBilanSaisie(
              id: state.prochainId, nom: 'Circuit ${state.lignes.length + 1}')
        ],
        prochainId: state.prochainId + 1,
      );

  void supprimer(int id) => state = state.copyWith(
      lignes: [for (final l in state.lignes) if (l.id != id) l]);
}

final bilanEntreeProvider =
    NotifierProvider<BilanNotifier, BilanEntree>(BilanNotifier.new);

final bilanResultatProvider = Provider<ResultatBilan>((ref) {
  final e = ref.watch(bilanEntreeProvider);
  return calculerBilan(
    lignes: [
      for (final l in e.lignes)
        LigneBilan(
            nom: l.nom,
            puissance: l.puissanceKw * 1000,
            ku: l.ku,
            ks: l.ks),
    ],
    ksGlobal: e.ksGlobal,
    alimentation: e.alimentation,
    tension: e.tension,
    cosPhi: e.cosPhi,
  );
});
