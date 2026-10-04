import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/chute_tension.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/dimensionnement_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';
import '../widgets/selecteur_tarif.dart';

const _modes = {
  ModePose.b: 'B — Conduits, vides de construction, goulottes',
  ModePose.c: 'C — Fixé aux parois, chemin de câbles non perforé',
  ModePose.d: 'D — Canalisations enterrées',
  ModePose.e: 'E — Multipolaires sur corbeaux, colliers, chemins perforés',
  ModePose.f: 'F — Unipolaires sur corbeaux, colliers, chemins perforés',
};

class DimensionnementScreen extends StatelessWidget {
  const DimensionnementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Dimensionnement',
      sousTitre:
          'Plus petite section satisfaisant surcharges et chute de tension',
      icone: Icons.auto_fix_high_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(dimensionnementEntreeProvider);
    final n = ref.read(dimensionnementEntreeProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Circuit',
          icone: Icons.cable_outlined,
          child: GrilleChamps(children: [
            ChampNombre(
              key: const ValueKey('di-ib'),
              label: 'Courant d\'emploi Ib',
              suffixe: 'A',
              valeurInitiale: fmtCompact(e.ib),
              minimum: 0.01,
              onValide: (v) => n.modifier((x) => x.copyWith(ib: v)),
            ),
            ChampNombre(
              key: const ValueKey('di-l'),
              label: 'Longueur',
              suffixe: 'm',
              valeurInitiale: fmtCompact(e.longueur),
              minimum: 0,
              onValide: (v) => n.modifier((x) => x.copyWith(longueur: v)),
            ),
            ChampNombre(
              key: const ValueKey('di-u0'),
              label: 'Tension simple U0',
              suffixe: 'V',
              valeurInitiale: fmtCompact(e.u0),
              minimum: 1,
              onValide: (v) => n.modifier((x) => x.copyWith(u0: v)),
            ),
            ChampNombre(
              key: const ValueKey('di-cos'),
              label: 'Facteur de puissance cos φ',
              valeurInitiale: fmtCompact(e.cosPhi),
              minimum: 0.01,
              maximum: 1,
              onValide: (v) => n.modifier((x) => x.copyWith(cosPhi: v)),
            ),
            ListeDeroulante<Circuit>(
              label: 'Circuit',
              valeur: e.circuit,
              options: const {
                Circuit.monophase: 'Monophasé',
                Circuit.triphase: 'Triphasé',
              },
              onChanged: (v) => n.modifier((x) => x.copyWith(circuit: v)),
            ),
            ListeDeroulante<UsageCircuit>(
              label: 'Usage',
              valeur: e.usage,
              options: {for (final u in UsageCircuit.values) u: u.libelle},
              onChanged: (v) => n.modifier((x) => x.copyWith(usage: v)),
            ),
            const SelecteurTarif(),
          ]),
        ),
        CarteSection(
          titre: 'Câble et pose',
          icone: Icons.settings_input_component_outlined,
          child: GrilleChamps(children: [
            ListeDeroulante<String>(
              label: 'Type de câble',
              valeur: e.typeCable,
              options: {for (final t in isolantParTypeCable.keys) t: t},
              onChanged: (v) => n.modifier((x) => x.copyWith(typeCable: v)),
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
            ListeDeroulante<ModePose>(
              label: 'Mode de pose',
              valeur: e.mode,
              options: _modes,
              onChanged: (v) => n.modifier((x) => x.copyWith(mode: v)),
            ),
            ChampNombre(
              key: const ValueKey('di-k'),
              label: 'Coefficient K (M)',
              valeurInitiale: fmtCompact(e.coefficientK),
              minimum: 0.01,
              aide: 'Produit K1..K7 : le calculer avec l\'assistant de '
                  'l\'écran Surcharges.',
              onValide: (v) => n.modifier((x) => x.copyWith(coefficientK: v)),
            ),
            ChampNombre(
              key: const ValueKey('di-par'),
              label: 'Conducteurs en parallèle par phase',
              valeurInitiale: e.nbParalleles.toString(),
              minimum: 1,
              entier: true,
              onValide: (v) =>
                  n.modifier((x) => x.copyWith(nbParalleles: v.round())),
            ),
          ]),
        ),
      ],
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(dimensionnementResultatProvider);
    final c = r.retenu;
    if (c == null) {
      return const PanneauResultat(
        libelle: 'Section retenue',
        valeur: 'Aucune',
        statut: StatutResultat.nonConforme,
        messageStatut: 'Aucune section usuelle ne satisfait Ib et la chute de '
            'tension : réduire la longueur, ajouter des conducteurs en '
            'parallèle ou revoir les données.',
      );
    }
    return PanneauResultat(
      libelle: 'Section retenue',
      valeur: fmtCompact(c.section),
      unite: 'mm²',
      statut: StatutResultat.conforme,
      details: [
        LigneDetail('Calibre In', '${fmtCompact(c.calibre!)} A'),
        LigneDetail('Courant admissible Iz', '${fmt(c.iz)} A'),
        LigneDetail('Chute de tension',
            '${fmt(c.chute.pourcent)} % (seuil ${fmt(c.chute.seuil * 100)} %)'),
      ],
      pied: 'Première section usuelle avec In ≥ Ib et ΔU ≤ seuil. Vérifier '
          'ensuite la contrainte thermique, Ik min et la résistance du PE '
          'dans leurs écrans.',
    );
  }
}
