import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/section_neutre.dart';
import '../../core/donnees/sections_resistivites.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/section_neutre_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

class SectionNeutreScreen extends StatelessWidget {
  const SectionNeutreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Section du neutre',
      sousTitre: 'Neutre et harmoniques de rang 3 (tableau 52.20)',
      icone: Icons.waves_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(sectionNeutreEntreeProvider);
    final n = ref.read(sectionNeutreEntreeProvider.notifier);
    return CarteSection(
      titre: 'Circuit',
      icone: Icons.cable_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GrilleChamps(children: [
            ChampNombre(
              key: const ValueKey('sn-ib'),
              label: 'Courant d\'emploi Ib',
              suffixe: 'A',
              valeurInitiale: fmtCompact(e.ib),
              minimum: 0.01,
              onValide: (v) => n.modifier((x) => x.copyWith(ib: v)),
            ),
            ChampNombre(
              key: const ValueKey('sn-th3'),
              label: 'Taux d\'harmoniques de rang 3',
              suffixe: '%',
              valeurInitiale: fmtCompact(e.th3),
              minimum: 0,
              maximum: 100,
              onValide: (v) => n.modifier((x) => x.copyWith(th3: v)),
            ),
            ListeDeroulante<bool>(
              label: 'Circuit',
              valeur: e.triphase,
              options: const {
                false: 'Monophasé',
                true: 'Triphasé avec neutre',
              },
              onChanged: (v) => n.modifier((x) => x.copyWith(triphase: v)),
            ),
            if (e.triphase)
              ListeDeroulante<CableNeutre>(
                label: 'Câbles du circuit triphasé',
                valeur: e.cable,
                options: {for (final c in CableNeutre.values) c: c.libelle},
                onChanged: (v) => n.modifier((x) => x.copyWith(cable: v)),
              ),
            ListeDeroulante<double>(
              label: 'Section de phase (mm²)',
              valeur: e.sectionPhase,
              options: {for (final s in sectionsUsuelles) s: fmtCompact(s)},
              onChanged: (v) => n.modifier((x) => x.copyWith(sectionPhase: v)),
            ),
            ListeDeroulante<Ame>(
              label: 'Âme',
              valeur: e.ame,
              options: const {
                Ame.cuivre: 'Cuivre',
                Ame.aluminium: 'Aluminium',
              },
              onChanged: (v) => n.modifier((x) => x.copyWith(ame: v)),
            ),
          ]),
          if (e.triphase)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Neutre protégé contre les surintensités'),
              subtitle: const Text('Condition de la réduction du neutre '
                  '(art. 524.2.3).'),
              value: e.neutreProtege,
              onChanged: (v) =>
                  n.modifier((x) => x.copyWith(neutreProtege: v)),
            ),
        ],
      ),
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(sectionNeutreResultatProvider);
    final e = ref.watch(sectionNeutreEntreeProvider);

    final String conclusion;
    if (!e.triphase) {
      conclusion = 'Circuit monophasé : le neutre porte le courant de la '
          'phase, il a la même section.';
    } else if (r.neutreReductibleAdmis) {
      conclusion = 'Un neutre de section réduite est admis (art. 524.2.3) : '
          '${fmtCompact(r.sectionNeutreMinimale!)} mm² minimum.';
    } else if (r.neutreSuperieurPhase) {
      conclusion = 'Phases calculées pour Ib, neutre calculé pour son propre '
          'courant : section du neutre supérieure à celle des phases.';
    } else if (r.cas == 1) {
      conclusion = 'Neutre de même section que les phases (conditions de la '
          'réduction non remplies).';
    } else {
      conclusion = 'Neutre de même section que les phases, calculées pour le '
          'courant indiqué.';
    }

    return PanneauResultat(
      libelle: r.cas == 1 && e.triphase
          ? 'Courant maximal du neutre (cas 1)'
          : 'Courant de dimensionnement du neutre (cas ${r.cas})',
      valeur: fmt(r.courantNeutre),
      unite: 'A',
      details: [
        LigneDetail('Cas du tableau 52.20', '${r.cas}'),
        LigneDetail('Courant de dimensionnement des phases',
            '${fmt(r.courantPhase)} A'),
      ],
      messageStatut: conclusion,
      pied: 'NF C 15-100-1 (2024), tableau 52.20 et art. 524.2.3. Au-dessus '
          'de 15 %, le coefficient 0,86 est appliqué. Cellule « câbles '
          'monoconducteurs, TH3 > 45 % » à relire dans la norme.',
    );
  }
}
