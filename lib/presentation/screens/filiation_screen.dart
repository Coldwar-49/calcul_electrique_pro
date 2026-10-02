import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/filiation.dart';
import '../formats.dart';
import '../providers/filiation_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

const _vert = Color(0xFF0B5B22);

class FiliationScreen extends StatelessWidget {
  const FiliationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Filiation',
      sousTitre: 'Pouvoir de coupure renforcé par le disjoncteur amont',
      icone: Icons.account_tree_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(filiationEntreeProvider);
    final n = ref.read(filiationEntreeProvider.notifier);
    final tables = e.tables;
    final table = e.table;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Tableau de filiation Merlin Gerin',
          icone: Icons.table_chart_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GrilleChamps(children: [
                ListeDeroulante<String>(
                  label: 'Catalogue',
                  valeur: e.catalogue,
                  options: {
                    for (final c in cataloguesFiliation()) c: 'Année $c',
                  },
                  onChanged: n.choisirCatalogue,
                ),
                ListeDeroulante<int>(
                  label: 'Réseau',
                  valeur: e.tensionEffective,
                  options: {
                    for (final t in tensionsFiliation(e.catalogue)) t: '$t V',
                  },
                  onChanged: n.choisirTension,
                ),
              ]),
              const SizedBox(height: 14),
              ListeDeroulante<int>(
                label: 'Familles d\'appareils',
                valeur: tables.indexOf(table),
                options: {
                  for (var i = 0; i < tables.length; i++) i: tables[i].libelle,
                },
                onChanged: n.choisirTable,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: 'Appareils et courant de court-circuit',
          icone: Icons.electrical_services_rounded,
          child: GrilleChamps(children: [
            ListeDeroulante<String>(
              label: 'Disjoncteur amont',
              valeur: e.amontEffectif,
              options: {for (final a in table.amonts) a: a},
              onChanged: n.choisirAmont,
            ),
            ListeDeroulante<String>(
              label: 'Disjoncteur aval',
              valeur: e.avalEffectif,
              options: {for (final a in table.avals) a: a},
              onChanged: n.choisirAval,
            ),
            ChampNombre(
              key: const ValueKey('fil-ik'),
              label: 'Courant de court-circuit Ik',
              suffixe: 'kA',
              valeurInitiale: fmtCompact(e.ik),
              minimum: 0,
              aide: 'Au point d\'installation du disjoncteur aval.',
              onValide: n.choisirIk,
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
    final e = ref.watch(filiationEntreeProvider);
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final table = e.table;
    final amont = e.amontEffectif;
    final aval = e.avalEffectif;
    final r = verifierFiliation(table, amont, aval, e.ik);
    final possibles = amontsPourAval(table, aval, e.ik);

    final (statut, message) = switch (r.statut) {
      StatutFiliation.assuree => (
          StatutResultat.conforme,
          'Filiation assurée (Ik = ${fmtCompact(e.ik)} kA)'
        ),
      StatutFiliation.insuffisante => (
          StatutResultat.nonConforme,
          'Filiation insuffisante (Ik = ${fmtCompact(e.ik)} kA)'
        ),
      StatutFiliation.aucune => (
          StatutResultat.neutre,
          'Aucune filiation prévue entre ces deux appareils'
        ),
    };

    Widget icone(StatutFiliation s) => switch (s) {
          StatutFiliation.assuree =>
            const Icon(Icons.check_circle_rounded, size: 18, color: _vert),
          StatutFiliation.insuffisante =>
            Icon(Icons.cancel_rounded, size: 18, color: cs.error),
          StatutFiliation.aucune =>
            Icon(Icons.remove_rounded, size: 18, color: cs.outline),
        };

    Widget cellule(String t,
            {bool fin = false, bool entete = false, bool gras = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            t,
            textAlign: fin ? TextAlign.end : TextAlign.start,
            style: (entete ? texte.labelSmall : texte.bodySmall)?.copyWith(
              color: entete ? cs.onSurfaceVariant : null,
              fontWeight: (entete || gras) ? FontWeight.w600 : null,
            ),
          ),
        );

    return PanneauResultat(
      libelle: 'Pouvoir de coupure renforcé de $aval',
      valeur: r.pdcRenforce == null ? '—' : fmtCompact(r.pdcRenforce!),
      unite: r.pdcRenforce == null ? null : 'kA',
      statut: statut,
      messageStatut: message,
      details: [
        LigneDetail('Amont', amont),
        LigneDetail('Pdc de l\'amont',
            r.pdcAmont == null ? 'non indiqué' : '${fmtCompact(r.pdcAmont!)} kA'),
        LigneDetail('Réseau', '${e.tensionEffective} V — année ${e.catalogue}'),
      ],
      extra: possibles.isEmpty
          ? Text(
              '$aval n\'a aucune filiation dans ce tableau.',
              style: texte.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Amonts possibles pour $aval',
                    style: texte.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1.6),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FixedColumnWidth(32),
                  },
                  border: TableBorder(
                    horizontalInside: BorderSide(color: cs.outlineVariant),
                  ),
                  children: [
                    TableRow(children: [
                      cellule('Amont', entete: true),
                      cellule('Pdc amont', entete: true, fin: true),
                      cellule('Renforcé', entete: true, fin: true),
                      const SizedBox.shrink(),
                    ]),
                    for (final p in possibles)
                      TableRow(children: [
                        cellule(p.amont, gras: p.amont == amont),
                        cellule(
                            p.pdcAmont == null ? '—' : fmtCompact(p.pdcAmont!),
                            fin: true),
                        cellule(fmtCompact(p.pdcRenforce),
                            fin: true, gras: p.amont == amont),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Align(
                              alignment: Alignment.centerRight,
                              child: icone(p.statut)),
                        ),
                      ]),
                  ],
                ),
              ],
            ),
      pied: 'Valeurs en kA, tableaux de filiation Merlin Gerin / Schneider '
          '(catalogues 1998 à 2012). La filiation est retenue si le pouvoir '
          'de coupure renforcé et celui de l\'amont couvrent Ik.',
    );
  }
}
