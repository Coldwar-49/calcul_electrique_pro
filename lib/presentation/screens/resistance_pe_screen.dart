import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/donnees/calibres.dart';
import '../../core/donnees/courbes_disjoncteurs.dart';
import '../../core/donnees/fusibles.dart';
import '../formats.dart';
import '../providers/resistance_pe_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/choix_ou_autre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

/// Tensions simples proposées (valeurs des onglets du classeur).
const List<double> _tensionsPe = [127, 230, 400];

class ResistancePeScreen extends StatelessWidget {
  const ResistancePeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Résistance maximale du PE',
      sousTitre: 'Disjoncteurs et fusibles, schémas TN et IT (visite initiale)',
      icone: Icons.vertical_align_bottom_rounded,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(resistancePeEntreeProvider);
    final n = ref.read(resistancePeEntreeProvider.notifier);
    final fusible = e.famille == FamillePe.fusible;
    final industriel = !fusible && e.typeDisjoncteur == TypeDisjoncteurPe.industriel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Protection',
          icone: Icons.electrical_services_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<FamillePe>(
                showSelectedIcon: false,
                segments: [
                  for (final f in FamillePe.values)
                    ButtonSegment(value: f, label: Text(f.libelle)),
                ],
                selected: {e.famille},
                onSelectionChanged: (s) =>
                    n.modifier((x) => x.copyWith(famille: s.first)),
              ),
              const SizedBox(height: 16),
              GrilleChamps(children: [
                if (fusible)
                  ListeDeroulante<TypeFusible>(
                    label: 'Type de fusible',
                    valeur: e.typeFusible,
                    options: {for (final t in TypeFusible.values) t: t.libelle},
                    onChanged: (v) =>
                        n.modifier((x) => x.copyWith(typeFusible: v)),
                  )
                else
                  ListeDeroulante<TypeDisjoncteurPe>(
                    label: 'Type de disjoncteur',
                    valeur: e.typeDisjoncteur,
                    options: {
                      for (final t in TypeDisjoncteurPe.values) t: t.libelle,
                    },
                    onChanged: (v) =>
                        n.modifier((x) => x.copyWith(typeDisjoncteur: v)),
                  ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: 'Paramètres',
          icone: Icons.tune_rounded,
          child: GrilleChamps(children: [
            ChoixOuAutre(
              label: 'Tension simple U0',
              valeur: e.u0,
              choix: _tensionsPe,
              unite: 'V',
              minimum: 1,
              onChanged: (v) => n.modifier((x) => x.copyWith(u0: v)),
            ),
            ListeDeroulante<int>(
              label: 'Rapport Sph / Spe',
              valeur: e.rapportSphSpe,
              options: const {
                1: 'Sph / Spe ≤ 1  (k2 = 1)',
                2: 'Sph / Spe = 2  (k2 = 1,33)',
                3: 'Sph / Spe = 3  (k2 = 1,5)',
              },
              onChanged: (v) => n.modifier((x) => x.copyWith(rapportSphSpe: v)),
            ),
            if (fusible)
              ListeDeroulante<double>(
                label: 'Calibre du fusible',
                valeur: e.calibreFusible,
                options: {
                  for (final c in calibresFusible(e.typeFusible))
                    c: '${fmtCompact(c)} A',
                },
                onChanged: (v) =>
                    n.modifier((x) => x.copyWith(calibreFusible: v)),
              )
            else ...[
              if (!industriel)
                ListeDeroulante<CourbeDisjoncteur>(
                  label: 'Courbe',
                  valeur: e.courbe,
                  options: {
                    for (final c in CourbeDisjoncteur.values)
                      c: 'Courbe ${c.libelle}',
                  },
                  onChanged: (v) => n.modifier((x) => x.copyWith(courbe: v)),
                )
              else
                ChampNombre(
                  key: const ValueKey('pe-mult'),
                  label: 'Multiple de Ir',
                  valeurInitiale: fmtCompact(e.multipleIr),
                  minimum: 0.1,
                  onValide: (v) => n.modifier((x) => x.copyWith(multipleIr: v)),
                ),
              ChoixOuAutre(
                key: ValueKey('pe-ir-${e.ir}'),
                label: 'Réglage thermique Ir',
                valeur: e.ir,
                choix: calibresNormalises,
                unite: 'A',
                minimum: 0.1,
                onChanged: (v) => n.modifier((x) => x.copyWith(ir: v)),
              ),
            ],
          ]),
        ),
        if (industriel) ...[
          const SizedBox(height: 16),
          const _CarteCalculatriceIr(),
        ],
      ],
    );
  }
}

class _CarteCalculatriceIr extends ConsumerWidget {
  const _CarteCalculatriceIr();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(resistancePeEntreeProvider);
    final n = ref.read(resistancePeEntreeProvider.notifier);
    final texte = Theme.of(context).textTheme;

    return CarteSection(
      titre: 'Calculatrice pour Ir',
      icone: Icons.calculate_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GrilleChamps(largeurMin: 180, children: [
            ChampNombre(
              key: const ValueKey('pe-calc-in'),
              label: 'Calibre In',
              suffixe: 'A',
              valeurInitiale: fmtCompact(e.calcIn),
              minimum: 0.1,
              onValide: (v) => n.modifier((x) => x.copyWith(calcIn: v)),
            ),
            ChampNombre(
              key: const ValueKey('pe-calc-f1'),
              label: 'Facteur de réglage',
              valeurInitiale: fmtCompact(e.calcFacteur1),
              minimum: 0.01,
              onValide: (v) => n.modifier((x) => x.copyWith(calcFacteur1: v)),
            ),
            ChampNombre(
              key: const ValueKey('pe-calc-f2'),
              label: 'Facteur de correction',
              valeurInitiale: fmtCompact(e.calcFacteur2),
              minimum: 0.01,
              onValide: (v) => n.modifier((x) => x.copyWith(calcFacteur2: v)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text('Ir = ${fmt(e.irCalcule, 1)} A',
                    style: texte.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              FilledButton.tonal(
                onPressed: () =>
                    n.modifier((x) => x.copyWith(ir: x.irCalcule)),
                child: const Text('Utiliser comme Ir'),
              ),
            ],
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
    final vue = ref.watch(resistancePeVueProvider);
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final t = vue.terminaux;

    if (t == null) {
      return PanneauResultat(
        libelle: 'Calcul impossible',
        valeur: '—',
        statut: StatutResultat.nonConforme,
        messageStatut: vue.erreur,
      );
    }

    final div = vue.divisionnaires;
    TableRow ligne(List<String> cellules, {bool entete = false}) => TableRow(
          children: [
            for (var c = 0; c < cellules.length; c++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  cellules[c],
                  textAlign: c == 0 ? TextAlign.start : TextAlign.end,
                  style: (entete ? texte.labelSmall : texte.bodyMedium)
                      ?.copyWith(
                    color: entete ? cs.onSurfaceVariant : null,
                    fontWeight: entete ? FontWeight.w600 : null,
                  ),
                ),
              ),
          ],
        );

    return PanneauResultat(
      libelle: 'Rmax du PE en schéma TN',
      valeur: fmtMohm(t.tn),
      unite: 'mΩ',
      details: [
        if (vue.ia != null)
          LigneDetail('Courant de fusion Ia', '${fmt(vue.ia!)} A'),
      ],
      extra: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: cs.outlineVariant),
        ),
        children: [
          ligne([
            'Régime',
            div == null ? 'Rmax (mΩ)' : 'Terminaux (mΩ)',
            if (div != null) 'Divisionnaires (mΩ)',
          ], entete: true),
          ligne(['TN', fmtMohm(t.tn), if (div != null) fmtMohm(div.tn)]),
          ligne(['IT – ITAN', fmtMohm(t.itan), if (div != null) fmtMohm(div.itan)]),
          ligne(['IT – ITSN', fmtMohm(t.itsn), if (div != null) fmtMohm(div.itsn)]),
        ],
      ),
      pied: 'Rmax = 1000 × U0 × k2 / (2 × m × Ir) pour un disjoncteur, '
          '1000 × U0 × k2 / (2 × Ia) pour un fusible. ITAN = × 0,5, '
          'ITSN = × 0,866. Valeurs de l\'édition 2013.',
    );
  }
}
