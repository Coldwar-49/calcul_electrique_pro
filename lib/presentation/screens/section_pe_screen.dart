import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/donnees/k_conducteurs_protection.dart';
import '../../core/donnees/sections_resistivites.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/section_pe_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

const _ames = {Ame.cuivre: 'Cuivre', Ame.aluminium: 'Aluminium'};

class SectionPeScreen extends StatelessWidget {
  const SectionPeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Section du PE',
      sousTitre: 'Section minimale du conducteur de protection',
      icone: Icons.vertical_align_center_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(sectionPeEntreeProvider);
    final n = ref.read(sectionPeEntreeProvider.notifier);
    final differents = e.amePhase != e.amePe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Conducteur de phase',
          icone: Icons.cable_outlined,
          child: GrilleChamps(
            children: [
              ListeDeroulante<double>(
                label: 'Section de phase (mm²)',
                valeur: e.sectionPhase,
                options: {for (final s in sectionsUsuelles) s: fmtCompact(s)},
                onChanged: (v) =>
                    n.modifier((x) => x.copyWith(sectionPhase: v)),
              ),
              ListeDeroulante<Ame>(
                label: 'Âme de la phase',
                valeur: e.amePhase,
                options: _ames,
                onChanged: (v) => n.modifier((x) => x.copyWith(amePhase: v)),
              ),
              if (differents)
                ListeDeroulante<int>(
                  label: 'Isolant de la phase',
                  valeur: e.lignePhase,
                  options: {
                    for (final (i, l) in lignesKPhase().indexed) i: l.libelle,
                  },
                  onChanged: (v) =>
                      n.modifier((x) => x.copyWith(lignePhase: v)),
                ),
            ],
          ),
        ),
        CarteSection(
          titre: 'Conducteur de protection',
          icone: Icons.vertical_align_bottom_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GrilleChamps(
                children: [
                  ListeDeroulante<Ame>(
                    label: 'Âme du PE',
                    valeur: e.amePe,
                    options: _ames,
                    onChanged: (v) => n.modifier((x) => x.copyWith(amePe: v)),
                  ),
                  ListeDeroulante<SituationPe>(
                    label: 'Situation du PE',
                    valeur: e.situation,
                    options: {for (final s in SituationPe.values) s: s.libelle},
                    onChanged: (v) =>
                        n.modifier((x) => x.copyWith(situation: v)),
                  ),
                  if (differents || e.verifierThermique)
                    ListeDeroulante<int>(
                      label: 'Isolant ou conditions du PE',
                      valeur: e.lignePe,
                      options: {
                        for (final (i, l) in lignesK(e.situation).indexed)
                          i: l.libelle,
                      },
                      onChanged: (v) =>
                          n.modifier((x) => x.copyWith(lignePe: v)),
                    ),
                  if (e.horsCanalisation)
                    ListeDeroulante<bool>(
                      label: 'Protection mécanique du PE',
                      valeur: e.protegeMecaniquement,
                      options: const {
                        true: 'Protégé mécaniquement',
                        false: 'Non protégé mécaniquement',
                      },
                      onChanged: (v) => n.modifier(
                        (x) => x.copyWith(protegeMecaniquement: v),
                      ),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vérifier la contrainte thermique'),
                subtitle: const Text('S ≥ √(I²t) / k, temps de coupure ≤ 5 s'),
                value: e.verifierThermique,
                onChanged: (v) =>
                    n.modifier((x) => x.copyWith(verifierThermique: v)),
              ),
              if (e.verifierThermique)
                GrilleChamps(
                  children: [
                    ChampNombre(
                      key: const ValueKey('spe-ik'),
                      label: 'Courant de défaut Ik',
                      suffixe: 'kA',
                      valeurInitiale: fmtCompact(e.ikKa),
                      minimum: 0.001,
                      onValide: (v) => n.modifier((x) => x.copyWith(ikKa: v)),
                    ),
                    ChampNombre(
                      key: const ValueKey('spe-t'),
                      label: 'Durée de coupure t',
                      suffixe: 's',
                      valeurInitiale: fmtCompact(e.temps),
                      minimum: 0.001,
                      maximum: 5,
                      onValide: (v) => n.modifier((x) => x.copyWith(temps: v)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vue = ref.watch(sectionPeVueProvider);
    final e = ref.watch(sectionPeEntreeProvider);
    final r = vue.resultat;
    return PanneauResultat(
      libelle: 'Section minimale du PE',
      valeur: fmtCompact(r.retenue),
      unite: 'mm²',
      details: [
        LigneDetail(
          e.amePhase == e.amePe
              ? 'Tableau 3 (même métal)'
              : 'Tableau 3 × k1/k2 (k1 = ${fmtCompact(vue.k1!)}, '
                    'k2 = ${fmtCompact(r.k2Utilise)})',
          '${fmt(r.tableau3)} mm²',
        ),
        if (e.horsCanalisation)
          LigneDetail(
            'Minimum hors canalisation',
            '${fmtCompact(r.minimumMecanique)} mm²',
          ),
        if (r.thermique != null)
          LigneDetail(
            'Contrainte thermique (k = ${fmtCompact(r.k2Utilise)})',
            '${fmt(r.thermique!)} mm²',
          ),
        LigneDetail('Plus grande exigence', '${fmt(r.calculee)} mm²'),
      ],
      pied:
          'NF C 15-100-1 (août 2024), partie 5-54 : tableau 54.3 et valeurs '
          'de k des tableaux 54A.2 à 54A.6. Minima hors canalisation et '
          'formule thermique : guide UTE C 15-106 (2003), à confirmer dans '
          'l\'édition 2024.',
    );
  }
}
