import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/ik_min.dart' show RegimeNeutre;
import '../../core/donnees/calibres.dart';
import '../../core/donnees/courbes_disjoncteurs.dart';
import '../../core/donnees/fusibles.dart';
import '../../core/donnees/sections_resistivites.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/contacts_indirects_provider.dart';
import '../providers/resistance_pe_provider.dart'
    show FamillePe, TypeDisjoncteurPe;
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/choix_ou_autre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

/// Tensions phase/neutre et entre phases proposées (tables du classeur).
const List<double> _tensionsPhN = [127, 230, 400, 580];
const List<double> _tensionsPhPh = [220, 400, 690, 1000];

class ContactsIndirectsScreen extends StatelessWidget {
  const ContactsIndirectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Contacts indirects TN / IT',
      sousTitre: 'Longueur maximale de câble protégée (visite périodique)',
      icone: Icons.back_hand_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(contactsEntreeProvider);
    final n = ref.read(contactsEntreeProvider.notifier);
    final fusible = e.famille == FamillePe.fusible;
    final industriel =
        !fusible && e.typeDisjoncteur == TypeDisjoncteurPe.industriel;
    final sections = {for (final s in sectionsUsuelles) s: fmtCompact(s)};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Régime de neutre et tensions',
          icone: Icons.power_outlined,
          child: GrilleChamps(children: [
            ListeDeroulante<RegimeNeutre>(
              label: 'Régime de neutre',
              valeur: e.regime,
              options: {for (final r in RegimeNeutre.values) r: r.libelle},
              onChanged: (v) => n.modifier((x) => x.copyWith(regime: v)),
            ),
            ChoixOuAutre(
              label: 'Tension phase / neutre (TN, ITAN)',
              valeur: e.tensionPhN,
              choix: _tensionsPhN,
              unite: 'V',
              minimum: 1,
              onChanged: (v) => n.modifier((x) => x.copyWith(tensionPhN: v)),
            ),
            ChoixOuAutre(
              label: 'Tension entre phases (ITSN)',
              valeur: e.tensionPhPh,
              choix: _tensionsPhPh,
              unite: 'V',
              minimum: 220,
              onChanged: (v) => n.modifier((x) => x.copyWith(tensionPhPh: v)),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: 'Dispositif de protection',
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
                if (fusible) ...[
                  ListeDeroulante<TypeFusible>(
                    label: 'Type de fusible',
                    valeur: e.typeFusible,
                    options: {for (final t in TypeFusible.values) t: t.libelle},
                    onChanged: (v) =>
                        n.modifier((x) => x.copyWith(typeFusible: v)),
                  ),
                  ListeDeroulante<double>(
                    label: 'Calibre du fusible',
                    valeur: e.calibreFusible,
                    options: {
                      for (final c in calibresFusible(e.typeFusible))
                        c: '${fmtCompact(c)} A',
                    },
                    onChanged: (v) =>
                        n.modifier((x) => x.copyWith(calibreFusible: v)),
                  ),
                ] else ...[
                  ListeDeroulante<TypeDisjoncteurPe>(
                    label: 'Type de disjoncteur',
                    valeur: e.typeDisjoncteur,
                    options: {
                      for (final t in TypeDisjoncteurPe.values) t: t.libelle,
                    },
                    onChanged: (v) =>
                        n.modifier((x) => x.copyWith(typeDisjoncteur: v)),
                  ),
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
                      key: const ValueKey('ci-mult'),
                      label: 'Réglage du magnétique (multiple de Ir)',
                      valeurInitiale: fmtCompact(e.multipleIr),
                      minimum: 0.1,
                      aide: 'Le calcul applique 1,2 × la valeur saisie.',
                      onValide: (v) =>
                          n.modifier((x) => x.copyWith(multipleIr: v)),
                    ),
                  ChoixOuAutre(
                    label: 'Réglage thermique Ir',
                    valeur: e.ir,
                    choix: calibresNormalises,
                    unite: 'A',
                    minimum: 0.1,
                    onChanged: (v) => n.modifier((x) => x.copyWith(ir: v)),
                  ),
                ],
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: 'Câble protégé',
          icone: Icons.cable_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Sph = Spe')),
                  ButtonSegment(value: false, label: Text('Sph ≠ Spe')),
                ],
                selected: {e.sphEgalSpe},
                onSelectionChanged: (s) =>
                    n.modifier((x) => x.copyWith(sphEgalSpe: s.first)),
              ),
              const SizedBox(height: 16),
              GrilleChamps(children: [
                ListeDeroulante<Ame>(
                  label: 'Âme',
                  valeur: e.ame,
                  options: const {
                    Ame.cuivre: 'Cuivre',
                    Ame.aluminium: 'Aluminium',
                  },
                  onChanged: (v) => n.modifier((x) => x.copyWith(ame: v)),
                ),
                ListeDeroulante<double>(
                  label: e.sphEgalSpe
                      ? 'Section (mm²)'
                      : 'Section de phase (mm²)',
                  valeur: e.sectionPh,
                  options: sections,
                  onChanged: (v) => n.modifier((x) => x.copyWith(sectionPh: v)),
                ),
                ChampNombre(
                  key: const ValueKey('ci-nbph'),
                  label: e.sphEgalSpe
                      ? 'Conducteurs par phase'
                      : 'Conducteurs de phase par pôle',
                  valeurInitiale: e.nbPh.toString(),
                  entier: true,
                  minimum: 1,
                  onValide: (v) => n.modifier((x) => x.copyWith(nbPh: v.toInt())),
                ),
                if (!e.sphEgalSpe) ...[
                  ListeDeroulante<double>(
                    label: 'Section du PE (mm²)',
                    valeur: e.sectionPe,
                    options: sections,
                    onChanged: (v) =>
                        n.modifier((x) => x.copyWith(sectionPe: v)),
                  ),
                  ChampNombre(
                    key: const ValueKey('ci-nbpe'),
                    label: 'Conducteurs de PE par pôle',
                    valeurInitiale: e.nbPe.toString(),
                    entier: true,
                    minimum: 1,
                    onValide: (v) =>
                        n.modifier((x) => x.copyWith(nbPe: v.toInt())),
                  ),
                ],
              ]),
              if (e.sphEgalSpe && e.regime == RegimeNeutre.itan)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'En ITAN, saisir la section du neutre si elle est plus '
                    'petite que celle de la phase.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
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
    final vue = ref.watch(contactsVueProvider);
    final e = ref.watch(contactsEntreeProvider);
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final l = vue.longueurs;

    if (l == null) {
      return PanneauResultat(
        libelle: 'Calcul impossible',
        valeur: '—',
        statut: StatutResultat.nonConforme,
        messageStatut: vue.erreur,
      );
    }

    final coef = vue.coefficientDistribution;
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

    String m(double v) => fmt(v, 1);

    return PanneauResultat(
      libelle: coef == null
          ? 'Longueur maximale (${e.regime.libelle})'
          : 'Longueur maximale, circuit terminal (${e.regime.libelle})',
      valeur: m(l.pour(e.regime)),
      unite: 'm',
      details: [
        if (coef != null)
          LigneDetail('Circuit de distribution',
              '${m(l.pour(e.regime) * coef)} m'),
        if (coef != null)
          LigneDetail('Coefficient de distribution', fmtCompact(coef)),
      ],
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in vue.avertissements) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 20, color: cs.onTertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a,
                        style: texte.bodySmall
                            ?.copyWith(color: cs.onTertiaryContainer)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: cs.outlineVariant),
            ),
            children: [
              ligne([
                'Régime',
                coef == null ? 'Lmax (m)' : 'Terminal (m)',
                if (coef != null) 'Distribution (m)',
              ], entete: true),
              for (final r in RegimeNeutre.values)
                ligne([
                  r.libelle,
                  m(l.pour(r)),
                  if (coef != null) m(l.pour(r) * coef),
                ]),
            ],
          ),
        ],
      ),
      pied: 'Méthode conventionnelle : L = 0,8 × U0 × S / (2 × ρ × Im), '
          'ITAN × 0,5, ITSN × facteur de tension. Visite périodique. '
          'Valeurs de l\'édition 2013.',
    );
  }
}
