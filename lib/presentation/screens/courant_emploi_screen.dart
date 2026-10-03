import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/courant_emploi.dart';
import '../formats.dart';
import '../providers/courant_emploi_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

class CourantEmploiScreen extends StatelessWidget {
  const CourantEmploiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Courant d\'emploi',
      sousTitre: 'Courant Ib d\'un récepteur à partir de sa puissance',
      icone: Icons.electric_meter_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(courantEmploiEntreeProvider);
    final n = ref.read(courantEmploiEntreeProvider.notifier);
    return CarteSection(
      titre: 'Récepteur',
      icone: Icons.power_outlined,
      child: GrilleChamps(children: [
        ListeDeroulante<Alimentation>(
          label: 'Alimentation',
          valeur: e.alimentation,
          options: {for (final a in Alimentation.values) a: a.libelle},
          onChanged: (v) => n.modifier(
              (x) => x.copyWith(alimentation: v, tension: v.tensionUsuelle)),
        ),
        ChampNombre(
          key: ValueKey('ce-u-${e.alimentation.name}'),
          label: 'Tension',
          suffixe: 'V',
          valeurInitiale: fmtCompact(e.tension),
          minimum: 1,
          onValide: (v) => n.modifier((x) => x.copyWith(tension: v)),
        ),
        ChampNombre(
          key: const ValueKey('ce-p'),
          label: 'Puissance',
          suffixe: 'kW',
          valeurInitiale: fmtCompact(e.puissanceKw),
          minimum: 0,
          onValide: (v) => n.modifier((x) => x.copyWith(puissanceKw: v)),
        ),
        ChampNombre(
          key: const ValueKey('ce-cos'),
          label: 'Facteur de puissance cos φ',
          valeurInitiale: fmtCompact(e.cosPhi),
          minimum: 0.01,
          maximum: 1,
          onValide: (v) => n.modifier((x) => x.copyWith(cosPhi: v)),
        ),
        ChampNombre(
          key: const ValueKey('ce-eta'),
          label: 'Rendement',
          valeurInitiale: fmtCompact(e.rendement),
          minimum: 0.01,
          maximum: 1,
          aide: '1 si la puissance est déjà la puissance absorbée ; '
              'moteur : puissance utile.',
          onValide: (v) => n.modifier((x) => x.copyWith(rendement: v)),
        ),
      ]),
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ib = ref.watch(courantEmploiResultatProvider);
    final e = ref.watch(courantEmploiEntreeProvider);
    return PanneauResultat(
      libelle: 'Courant d\'emploi Ib',
      valeur: fmt(ib),
      unite: 'A',
      details: [
        LigneDetail(
            'Puissance absorbée', '${fmt(e.puissanceKw / e.rendement)} kW'),
      ],
      pied: e.alimentation == Alimentation.triphase
          ? 'Ib = P / (η × √3 × U × cos φ)'
          : 'Ib = P / (η × U × cos φ)',
    );
  }
}
