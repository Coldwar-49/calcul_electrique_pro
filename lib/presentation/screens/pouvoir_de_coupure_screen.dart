import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/pouvoir_de_coupure.dart';
import '../../core/donnees/fusibles.dart';
import '../../core/donnees/pouvoir_de_coupure.dart';
import '../formats.dart';
import '../providers/pouvoir_de_coupure_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

const _vert = Color(0xFF0B5B22);

String _kA(double v) => v.isInfinite ? 'Infini' : fmtCompact(v);

class PouvoirDeCoupureScreen extends StatelessWidget {
  const PouvoirDeCoupureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Pouvoir de coupure',
      sousTitre: 'Disjoncteurs IT, fusibles et disjoncteurs moteurs',
      icone: Icons.shield_moon_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(pdcEntreeProvider);
    final n = ref.read(pdcEntreeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Table de pouvoir de coupure',
          icone: Icons.table_chart_outlined,
          child: SegmentedButton<TablePdc>(
            showSelectedIcon: false,
            segments: [
              for (final t in TablePdc.values)
                ButtonSegment(value: t, label: Text(t.libelle)),
            ],
            selected: {e.table},
            onSelectionChanged: (s) =>
                n.modifier((x) => x.copyWith(table: s.first)),
          ),
        ),
        const SizedBox(height: 16),
        switch (e.table) {
          TablePdc.it => const _FormulaireIt(),
          TablePdc.fusibles => const _FormulaireFusibles(),
          TablePdc.moteurs => const _FormulaireMoteurs(),
        },
      ],
    );
  }
}

class _FormulaireIt extends ConsumerWidget {
  const _FormulaireIt();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(pdcEntreeProvider);
    final n = ref.read(pdcEntreeProvider.notifier);

    return CarteSection(
      titre: 'Disjoncteur en schéma IT',
      icone: Icons.electrical_services_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GrilleChamps(children: [
            ListeDeroulante<int>(
              label: 'Gamme de disjoncteur',
              valeur: e.gamme,
              options: {
                for (var i = 0; i < gammesIt.length; i++) i: gammesIt[i].libelle,
              },
              onChanged: (v) => n.modifier((x) => x.copyWith(gamme: v)),
            ),
            ChampNombre(
              key: const ValueKey('pdc-id2'),
              label: 'Courant de double défaut Id2 sur un pôle',
              suffixe: 'kA',
              valeurInitiale: fmtCompact(e.id2),
              minimum: 0,
              onValide: (v) => n.modifier((x) => x.copyWith(id2: v)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(
            'En schéma IT, le disjoncteur doit pouvoir couper sous un seul pôle '
            'le courant de double défaut, sous la tension entre phases.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _FormulaireFusibles extends ConsumerWidget {
  const _FormulaireFusibles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(pdcEntreeProvider);
    final n = ref.read(pdcEntreeProvider.notifier);
    final valides = e.taillesValides;
    final taille = e.tailleEffective;

    return CarteSection(
      titre: 'Fusible cylindrique',
      icone: Icons.bolt_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GrilleChamps(children: [
            ListeDeroulante<TypeFusible>(
              label: 'Type de fusible',
              valeur: e.typeFusible,
              options: {for (final t in TypeFusible.values) t: t.libelle},
              onChanged: (v) => n.modifier((x) => x.copyWith(typeFusible: v)),
            ),
            ChampNombre(
              key: const ValueKey('pdc-calibre'),
              label: 'Calibre',
              suffixe: 'A',
              valeurInitiale: fmtCompact(e.calibre),
              minimum: 0.01,
              onValide: (v) => n.modifier((x) => x.copyWith(calibre: v)),
            ),
            if (taille != null)
              ListeDeroulante<String>(
                label: 'Taille',
                valeur: taille.libelle,
                options: {for (final t in valides) t.libelle: '${t.libelle} mm'},
                onChanged: (v) => n.modifier((x) => x.copyWith(taille: v)),
              ),
            ChampNombre(
              key: const ValueKey('pdc-ik-f'),
              label: 'Courant de court-circuit Ik',
              suffixe: 'kA',
              valeurInitiale: fmtCompact(e.ik),
              minimum: 0,
              onValide: (v) => n.modifier((x) => x.copyWith(ik: v)),
            ),
          ]),
          if (taille == null) ...[
            const SizedBox(height: 12),
            Text(
              'Aucune taille cylindrique du tableau ne couvre ce calibre. '
              'Les fusibles à couteaux ont un pouvoir de coupure de '
              '${fmtCompact(pdcFusiblesCouteauxKa)} kA.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormulaireMoteurs extends ConsumerWidget {
  const _FormulaireMoteurs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(pdcEntreeProvider);
    final n = ref.read(pdcEntreeProvider.notifier);

    return CarteSection(
      titre: 'Disjoncteur moteur Schneider (catalogue 2009)',
      icone: Icons.settings_outlined,
      child: GrilleChamps(children: [
        ListeDeroulante<int>(
          label: 'Référence',
          valeur: e.moteur,
          options: {
            for (var i = 0; i < disjoncteursMoteurs.length; i++)
              i: disjoncteursMoteurs[i].reference,
          },
          onChanged: (v) => n.modifier((x) => x.copyWith(moteur: v)),
        ),
        ChampNombre(
          key: const ValueKey('pdc-ik-m'),
          label: 'Courant de court-circuit Ik',
          suffixe: 'kA',
          valeurInitiale: fmtCompact(e.ik),
          minimum: 0,
          onValide: (v) => n.modifier((x) => x.copyWith(ik: v)),
        ),
      ]),
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(pdcEntreeProvider);
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;

    // (désignation, pdc ou null si non applicable, courant à comparer)
    late final String libelle;
    late final double? pdc;
    late final double courant;
    late final String nomCourant;
    late final List<(String, double?)> lignes;
    String? pied;

    switch (e.table) {
      case TablePdc.it:
        libelle = 'Pdc sous un pôle — ${gammesIt[e.gamme].libelle}';
        pdc = gammesIt[e.gamme].pdcKa;
        courant = e.id2;
        nomCourant = 'Id2';
        lignes = [for (final g in gammesIt) (g.libelle, g.pdcKa)];
        pied = 'Tableau des pouvoirs de coupure sous un pôle (schéma IT).';
      case TablePdc.fusibles:
        final t = e.tailleEffective;
        libelle = t == null
            ? 'Aucune taille pour ce calibre'
            : 'Pdc — fusible ${e.typeFusible.libelle} ${t.libelle} mm';
        pdc = t?.plage(e.typeFusible).pdcKa;
        courant = e.ik;
        nomCourant = 'Ik';
        lignes = [
          for (final x in taillesFusibles)
            (
              '${x.libelle} mm',
              x.plage(e.typeFusible).contient(e.calibre)
                  ? x.plage(e.typeFusible).pdcKa
                  : null
            ),
          ('Fusibles à couteaux', pdcFusiblesCouteauxKa),
        ];
        pied = 'Fusibles cylindriques ${e.typeFusible.libelle} : une taille '
            'convient si le calibre est dans sa plage. « — » : calibre hors plage.';
      case TablePdc.moteurs:
        final d = disjoncteursMoteurs[e.moteur];
        libelle = 'Pdc — ${d.reference}';
        pdc = d.pdcKa;
        courant = e.ik;
        nomCourant = 'Ik';
        lignes = [for (final d in disjoncteursMoteurs) (d.reference, d.pdcKa)];
        pied = 'Pouvoir de coupure des disjoncteurs moteurs Schneider Merlin '
            'Gerin, catalogue 2009.';
    }

    final suffisant = pdc != null && pdcSuffisant(pdc, courant);

    Widget icone(double? valeur) {
      if (valeur == null) {
        return Icon(Icons.remove_rounded, size: 18, color: cs.outline);
      }
      return pdcSuffisant(valeur, courant)
          ? const Icon(Icons.check_circle_rounded, size: 18, color: _vert)
          : Icon(Icons.cancel_rounded, size: 18, color: cs.error);
    }

    return PanneauResultat(
      libelle: libelle,
      valeur: pdc == null ? '—' : _kA(pdc),
      unite: pdc == null || pdc.isInfinite ? null : 'kA',
      statut: pdc == null
          ? StatutResultat.neutre
          : (suffisant ? StatutResultat.conforme : StatutResultat.nonConforme),
      messageStatut: pdc == null
          ? null
          : (suffisant
              ? 'Pouvoir de coupure suffisant ($nomCourant = ${fmtCompact(courant)} kA)'
              : 'Pouvoir de coupure insuffisant ($nomCourant = ${fmtCompact(courant)} kA)'),
      extra: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.4),
          1: FlexColumnWidth(1),
          2: FixedColumnWidth(32),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: cs.outlineVariant),
        ),
        children: [
          TableRow(children: [
            for (final (i, t) in ['Désignation', 'Pdc (kA)', ''].indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(t,
                    textAlign: i == 1 ? TextAlign.end : TextAlign.start,
                    style: texte.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
              ),
          ]),
          for (final (nom, valeur) in lignes)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(nom, style: texte.bodySmall),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(valeur == null ? '—' : _kA(valeur),
                    textAlign: TextAlign.end, style: texte.bodySmall),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Align(
                    alignment: Alignment.centerRight, child: icone(valeur)),
              ),
            ]),
        ],
      ),
      pied: pied,
    );
  }
}
