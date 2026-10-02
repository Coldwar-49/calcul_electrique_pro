import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/ik_max.dart';
import '../../core/calculs/ik_min.dart';
import '../../core/donnees/calibres.dart';
import '../../core/donnees/sections_resistivites.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/ik_min_provider.dart';
import '../providers/triangle_provider.dart' show ChoixReglage;
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/choix_ou_autre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

const _vert = Color(0xFF0B5B22);
const _vertFond = Color(0xFFD7F5DD);

/// Texte de la conclusion pour un point.
String _texteStatut(SourceIk s, ResultatIkMinPoint p) => switch (p.statut) {
      StatutProtection.assuree =>
        'Assurée (DJ ${nomProtection(s, p.protecteur!)})',
      StatutProtection.nonAssuree => 'Non assurée',
      StatutProtection.nonApplicable => 'Sans protection',
    };

class IkMinScreen extends StatelessWidget {
  const IkMinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Courant de défaut minimal (Ik min)',
      sousTitre: 'Contacts indirects par la méthode des impédances',
      icone: Icons.flash_off_rounded,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(sourceIkProvider);
    final liaisons = ref.watch(liaisonsDe(source));
    final points = ref.watch(ikMinVueProvider).points;
    final notifier = ref.read(liaisonsDe(source).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CarteSource(),
        const SizedBox(height: 16),
        if (source == SourceIk.transformateur)
          const _CarteTransfo()
        else
          const _CarteGroupe(),
        const SizedBox(height: 16),
        for (var i = 0; i < liaisons.length; i++) ...[
          _CarteLiaison(
            source: source,
            indice: i,
            liaison: liaisons[i],
            point: points[i],
            supprimable: i == liaisons.length - 1 && liaisons.length > 1,
          ),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: notifier.ajouter,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter une liaison'),
          ),
        ),
      ],
    );
  }
}

class _CarteSource extends ConsumerWidget {
  const _CarteSource();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(sourceIkProvider);
    final regime = ref.watch(regimeNeutreProvider);

    return CarteSection(
      titre: 'Source et régime de neutre',
      icone: Icons.power_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<SourceIk>(
            showSelectedIcon: false,
            segments: [
              for (final s in SourceIk.values)
                ButtonSegment(value: s, label: Text(s.libelle)),
            ],
            selected: {source},
            onSelectionChanged: (s) =>
                ref.read(sourceIkProvider.notifier).choisir(s.first),
          ),
          const SizedBox(height: 16),
          GrilleChamps(children: [
            ListeDeroulante<RegimeNeutre>(
              label: 'Régime de neutre',
              valeur: regime,
              options: {for (final r in RegimeNeutre.values) r: r.libelle},
              onChanged: ref.read(regimeNeutreProvider.notifier).choisir,
            ),
          ]),
        ],
      ),
    );
  }
}

class _CarteTransfo extends ConsumerWidget {
  const _CarteTransfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(transfoMinProvider);
    final n = ref.read(transfoMinProvider.notifier);

    return CarteSection(
      titre: 'Réseau amont et transformateur',
      icone: Icons.electric_meter_outlined,
      child: GrilleChamps(children: [
        ChoixOuAutre(
          label: 'Tension entre phases',
          valeur: r.u0,
          choix: tensionsUsuelles,
          unite: 'V',
          minimum: 1,
          onChanged: (v) => n.modifier((x) => x.copyWith(u0: v)),
        ),
        ChampNombre(
          key: const ValueKey('min-pcc'),
          label: 'Pcc amont',
          suffixe: 'MVA',
          valeurInitiale: fmtCompact(r.pccMva),
          minimum: 0.1,
          onValide: (v) => n.modifier((x) => x.copyWith(pccMva: v)),
        ),
        ListeDeroulante<Couplage>(
          label: 'Couplage',
          valeur: r.couplage,
          options: {for (final c in Couplage.values) c: c.libelle},
          onChanged: (v) => n.modifier((x) => x.copyWith(couplage: v)),
        ),
        ChoixOuAutre(
          label: 'Puissance du transformateur',
          valeur: r.puissanceKva,
          choix: puissancesTransfoUsuelles,
          unite: 'kVA',
          minimum: 1,
          onChanged: (v) => n.modifier((x) => x.copyWith(puissanceKva: v)),
        ),
        ChoixOuAutre(
          label: 'Tension de court-circuit Ucc',
          valeur: r.uccPourcent,
          choix: uccUsuelles,
          unite: '%',
          minimum: 0.1,
          onChanged: (v) => n.modifier((x) => x.copyWith(uccPourcent: v)),
        ),
        ChampNombre(
          key: const ValueKey('min-nbt'),
          label: 'Transformateurs en parallèle',
          valeurInitiale: r.nbTransfos.toString(),
          entier: true,
          minimum: 1,
          onValide: (v) => n.modifier((x) => x.copyWith(nbTransfos: v.toInt())),
        ),
      ]),
    );
  }
}

class _CarteGroupe extends ConsumerWidget {
  const _CarteGroupe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(groupeProvider);
    final n = ref.read(groupeProvider.notifier);

    return CarteSection(
      titre: 'Groupe électrogène',
      icone: Icons.electrical_services_rounded,
      child: GrilleChamps(children: [
        ChoixOuAutre(
          label: 'Tension entre phases',
          valeur: g.u0,
          choix: tensionsUsuelles,
          unite: 'V',
          minimum: 1,
          onChanged: (v) => n.modifier((x) => x.copyWith(u0: v)),
        ),
        ChampNombre(
          key: const ValueKey('ge-nb'),
          label: 'Groupes en parallèle',
          valeurInitiale: g.nbGroupes.toString(),
          entier: true,
          minimum: 1,
          onValide: (v) => n.modifier((x) => x.copyWith(nbGroupes: v.toInt())),
        ),
        ChampNombre(
          key: const ValueKey('ge-kva'),
          label: 'Puissance',
          suffixe: 'kVA',
          valeurInitiale: fmtCompact(g.puissanceKva),
          minimum: 1,
          onValide: (v) => n.modifier((x) => x.copyWith(puissanceKva: v)),
        ),
        ChampNombre(
          key: const ValueKey('ge-xd'),
          label: 'Réactance transitoire x\'d',
          suffixe: '%',
          valeurInitiale: fmtCompact(g.xdPourcent),
          minimum: 0.1,
          onValide: (v) => n.modifier((x) => x.copyWith(xdPourcent: v)),
        ),
        ChampNombre(
          key: const ValueKey('ge-x0'),
          label: 'Réactance homopolaire x0',
          suffixe: '%',
          valeurInitiale: fmtCompact(g.x0Pourcent),
          minimum: 0.1,
          onValide: (v) => n.modifier((x) => x.copyWith(x0Pourcent: v)),
        ),
      ]),
    );
  }
}

class _CarteLiaison extends ConsumerWidget {
  const _CarteLiaison({
    required this.source,
    required this.indice,
    required this.liaison,
    required this.point,
    required this.supprimable,
  });

  final SourceIk source;
  final int indice;
  final LiaisonMinUi liaison;
  final ResultatIkMinPoint point;
  final bool supprimable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = liaison;
    final id = l.id;
    final n = ref.read(liaisonsDe(source).notifier);
    void maj(LiaisonMinUi Function(LiaisonMinUi) f) => n.modifier(id, f);
    final sections = {for (final s in sectionsUsuelles) s: fmtCompact(s)};
    final protegee = aProtection(source, indice);
    final cle = '${source.name}-$id';

    return CarteSection(
      titre: 'Liaison ${nomLiaisonMin(source, indice)}',
      icone: Icons.timeline_rounded,
      action: supprimable
          ? IconButton(
              tooltip: 'Supprimer cette liaison',
              onPressed: n.supprimerDerniere,
              icon: const Icon(Icons.delete_outline_rounded),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GrilleChamps(largeurMin: 200, children: [
            ListeDeroulante<Ame>(
              label: 'Âme',
              valeur: l.ame,
              options: const {
                Ame.cuivre: 'Cuivre',
                Ame.aluminium: 'Aluminium',
              },
              onChanged: (v) => maj((x) => x.copyWith(ame: v)),
            ),
            ChampNombre(
              key: ValueKey('min-long-$cle'),
              label: 'Longueur',
              suffixe: 'm',
              valeurInitiale: fmtCompact(l.longueur),
              minimum: 0,
              onValide: (v) => maj((x) => x.copyWith(longueur: v)),
            ),
            ListeDeroulante<double>(
              label: 'Section phase (mm²)',
              valeur: l.sectionPhase,
              options: sections,
              onChanged: (v) => maj((x) => x.copyWith(sectionPhase: v)),
            ),
            ChampNombre(
              key: ValueKey('min-nbp-$cle'),
              label: 'Phases par pôle',
              valeurInitiale: l.nbPhases.toString(),
              entier: true,
              minimum: 1,
              onValide: (v) => maj((x) => x.copyWith(nbPhases: v.toInt())),
            ),
            ListeDeroulante<double>(
              label: 'Section PE (mm²)',
              valeur: l.sectionPe,
              options: sections,
              onChanged: (v) => maj((x) => x.copyWith(sectionPe: v)),
            ),
            ChampNombre(
              key: ValueKey('min-nbe-$cle'),
              label: 'PE par pôle',
              valeurInitiale: l.nbPe.toString(),
              entier: true,
              minimum: 1,
              onValide: (v) => maj((x) => x.copyWith(nbPe: v.toInt())),
            ),
          ]),
          if (protegee) ...[
            const SizedBox(height: 18),
            Text('Disjoncteur ${nomProtection(source, indice)}',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GrilleChamps(largeurMin: 200, children: [
              ListeDeroulante<ChoixReglage>(
                label: 'Réglage magnétique',
                valeur: l.choixReglage,
                options: {for (final c in ChoixReglage.values) c: c.libelle},
                onChanged: (v) => maj((x) => x.copyWith(choixReglage: v)),
              ),
              if (l.choixReglage == ChoixReglage.multipleIr)
                ChampNombre(
                  key: ValueKey('min-mult-$cle'),
                  label: 'Multiple de Ir',
                  valeurInitiale: fmtCompact(l.multipleIr),
                  minimum: 0.1,
                  aide: 'Le calcul applique 1,2 × la valeur saisie.',
                  onValide: (v) => maj((x) => x.copyWith(multipleIr: v)),
                ),
              ChoixOuAutre(
                key: ValueKey('min-ir-$cle'),
                label: 'Réglage thermique Ir',
                valeur: l.ir,
                choix: calibresNormalises,
                unite: 'A',
                minimum: 0.1,
                onChanged: (v) => maj((x) => x.copyWith(ir: v)),
              ),
            ]),
          ],
          const SizedBox(height: 18),
          _BandeauMin(
            nomPoint: nomArrivee(indice),
            source: source,
            point: point,
          ),
        ],
      ),
    );
  }
}

class _BandeauMin extends StatelessWidget {
  const _BandeauMin({
    required this.nomPoint,
    required this.source,
    required this.point,
  });

  final String nomPoint;
  final SourceIk source;
  final ResultatIkMinPoint point;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final (couleur, fond, icone) = switch (point.statut) {
      StatutProtection.assuree => (
          _vert,
          _vertFond,
          Icons.check_circle_rounded
        ),
      StatutProtection.nonAssuree => (
          cs.error,
          cs.errorContainer,
          Icons.error_rounded
        ),
      StatutProtection.nonApplicable => (
          cs.onSurfaceVariant,
          cs.surfaceContainerHighest,
          Icons.remove_circle_outline_rounded
        ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('If en $nomPoint',
                    style: texte.labelSmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('${fmtKa(point.ifKa)} kA',
                    style: texte.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: fond,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 16, color: couleur),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(_texteStatut(source, point),
                        overflow: TextOverflow.ellipsis,
                        style: texte.labelMedium?.copyWith(
                            color: couleur, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
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
    final vue = ref.watch(ikMinVueProvider);
    final regime = ref.watch(regimeNeutreProvider);
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;
    final dernier = vue.points.last;
    final nbNonAssurees =
        vue.points.where((p) => p.statut == StatutProtection.nonAssuree).length;

    final statut = switch (dernier.statut) {
      StatutProtection.assuree => StatutResultat.conforme,
      StatutProtection.nonAssuree => StatutResultat.nonConforme,
      StatutProtection.nonApplicable => StatutResultat.neutre,
    };

    TableRow ligne(List<String> cellules, {bool entete = false}) => TableRow(
          children: [
            for (var c = 0; c < cellules.length; c++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  cellules[c],
                  textAlign: c == 1 ? TextAlign.end : TextAlign.start,
                  style: (entete ? texte.labelSmall : texte.bodySmall)
                      ?.copyWith(
                    color: entete ? cs.onSurfaceVariant : null,
                    fontWeight: entete ? FontWeight.w600 : null,
                  ),
                ),
              ),
          ],
        );

    return PanneauResultat(
      libelle: 'If au point le plus éloigné (${nomArrivee(vue.points.length - 1)})',
      valeur: fmtKa(dernier.ifKa),
      unite: 'kA',
      statut: statut,
      messageStatut: 'Protection contre les contacts indirects : '
          '${_texteStatut(vue.source, dernier).toLowerCase()}',
      details: [
        LigneDetail('Régime de neutre', regime.libelle),
        LigneDetail('Points non protégés', '$nbNonAssurees'),
      ],
      extra: Table(
        columnWidths: const {
          0: FlexColumnWidth(0.8),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1.6),
        },
        border: TableBorder(
          horizontalInside: BorderSide(color: cs.outlineVariant),
        ),
        children: [
          ligne(['Point', 'If (kA)', 'Protection'], entete: true),
          for (var i = 0; i < vue.points.length; i++)
            ligne([
              nomArrivee(i),
              fmtKa(vue.points[i].ifKa),
              _texteStatut(vue.source, vue.points[i]),
            ]),
        ],
      ),
      pied: 'If = 0,95 × 1,05 × U / (√3 × Z), × 0,5 (ITAN) ou × 0,866 (ITSN). '
          'Protection assurée si 1000 × If ≥ Im de la protection ou d\'une '
          'protection amont. Valeurs de l\'édition 2013.',
    );
  }
}
