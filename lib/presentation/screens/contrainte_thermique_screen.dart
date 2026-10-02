import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/donnees/contrainte_thermique.dart';
import '../../core/donnees/sections_resistivites.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/contrainte_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

class ContrainteThermiqueScreen extends StatelessWidget {
  const ContrainteThermiqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Contrainte thermique',
      sousTitre: 'Tenue des conducteurs actifs en court-circuit',
      icone: Icons.whatshot_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(contrainteEntreeProvider);
    final n = ref.read(contrainteEntreeProvider.notifier);
    final vue = ref.watch(contrainteVueProvider);
    final fusible = e.protection == Protection.fusible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Protection',
          icone: Icons.electrical_services_rounded,
          child: SegmentedButton<Protection>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                  value: Protection.fusible, label: Text('Par fusible')),
              ButtonSegment(
                  value: Protection.disjoncteur, label: Text('Par disjoncteur')),
            ],
            selected: {e.protection},
            onSelectionChanged: (s) =>
                n.modifier((x) => x.copyWith(protection: s.first)),
          ),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: 'Conducteurs',
          icone: Icons.cable_outlined,
          child: GrilleChamps(children: [
            ListeDeroulante<double>(
              label: 'Section phase (mm²)',
              valeur: e.sectionPh,
              options: {for (final s in sectionsUsuelles) s: fmtCompact(s)},
              onChanged: (v) => n.modifier((x) => x.copyWith(sectionPh: v)),
            ),
            ListeDeroulante<double>(
              label: 'Section neutre (mm²)',
              valeur: e.sectionN,
              options: {for (final s in sectionsUsuelles) s: fmtCompact(s)},
              onChanged: (v) => n.modifier((x) => x.copyWith(sectionN: v)),
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
            ListeDeroulante<CanalisationPe>(
              label: 'Position du PE',
              valeur: e.canalisation,
              options: {for (final c in CanalisationPe.values) c: c.libelle},
              onChanged: (v) => n.modifier((x) => x.copyWith(canalisation: v)),
            ),
            ListeDeroulante<IsolantContrainte>(
              label: 'Isolant',
              valeur: e.isolant,
              options: {
                for (final i in isolantsContrainte(e.canalisation))
                  i: i.libelle,
              },
              onChanged: (v) => n.modifier((x) => x.copyWith(isolant: v)),
            ),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Coefficient k'),
              child: Text(
                vue.erreur == null ? fmtCompact(vue.k) : '—',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: fusible ? 'Réseau (Ik min calculé)' : 'Court-circuit',
          icone: Icons.bolt_rounded,
          child: GrilleChamps(children: [
            if (fusible) ...[
              ChampNombre(
                key: const ValueKey('ct-u0'),
                label: 'Tension U0',
                suffixe: 'V',
                valeurInitiale: fmtCompact(e.u0),
                minimum: 1,
                onValide: (v) => n.modifier((x) => x.copyWith(u0: v)),
              ),
              ChampNombre(
                key: const ValueKey('ct-long'),
                label: 'Longueur',
                suffixe: 'm',
                valeurInitiale: fmtCompact(e.longueur),
                minimum: 0.01,
                onValide: (v) => n.modifier((x) => x.copyWith(longueur: v)),
              ),
            ] else
              ChampNombre(
                key: const ValueKey('ct-ik'),
                label: 'Ik maximal (Ik3, Ik2 ou Ik1)',
                suffixe: 'kA',
                valeurInitiale: fmtCompact(e.ikKa),
                minimum: 0.001,
                onValide: (v) => n.modifier((x) => x.copyWith(ikKa: v)),
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
    final vue = ref.watch(contrainteVueProvider);
    final e = ref.watch(contrainteEntreeProvider);
    final r = vue.resultat;

    if (r == null) {
      return PanneauResultat(
        libelle: 'Calcul impossible',
        valeur: '—',
        statut: StatutResultat.nonConforme,
        messageStatut: vue.erreur,
      );
    }

    return PanneauResultat(
      libelle: 'Temps T = (k × S)² / I²',
      valeur: fmt(r.temps, r.temps < 1 ? 4 : 2),
      unite: 's',
      statut:
          r.conforme ? StatutResultat.conforme : StatutResultat.nonConforme,
      messageStatut: r.conforme
          ? 'Conforme (T ≤ 5 s)'
          : 'Non conforme (T > 5 s)',
      details: [
        LigneDetail('Section retenue', '${fmtCompact(r.sectionRetenue)} mm²'),
        LigneDetail('Coefficient k', fmtCompact(vue.k)),
        if (r.ikMin != null) LigneDetail('Ik min', '${fmt(r.ikMin!)} A'),
        if (e.protection == Protection.disjoncteur)
          LigneDetail('Ik maximal', '${fmtCompact(e.ikKa)} kA'),
      ],
      pied: 'Section retenue = la plus petite de la phase et du neutre. '
          'Ik min = 0,8 × U0 / (ρ × L × (Xph/Sph + Xn/Sn)). '
          'Tables NF C 15-100, valeurs de l\'édition 2013.',
    );
  }
}
