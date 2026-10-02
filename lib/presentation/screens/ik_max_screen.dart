import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/ik_max.dart';
import '../../core/donnees/sections_resistivites.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/ik_max_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/choix_ou_autre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';
import '../widgets/selecteur_tarif.dart';

String _ka(double v) => fmt(v, v < 1 ? 3 : 2);

class IkMaxScreen extends StatelessWidget {
  const IkMaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Courants de court-circuit maximaux',
      sousTitre: 'Ik3, Ik2 et Ik1 de la source jusqu\'aux tableaux',
      icone: Icons.flash_on_rounded,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liaisons = ref.watch(liaisonsProvider);
    final resultat = ref.watch(ikMaxResultatProvider);
    final n = ref.read(liaisonsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CarteReseau(),
        const SizedBox(height: 16),
        for (var i = 0; i < liaisons.length; i++) ...[
          _CarteLiaison(
            indice: i,
            liaison: liaisons[i],
            point: resultat.points[i],
            supprimable: i == liaisons.length - 1 && liaisons.length > 1,
          ),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: n.ajouter,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ajouter une liaison'),
          ),
        ),
      ],
    );
  }
}

class _CarteReseau extends ConsumerWidget {
  const _CarteReseau();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(reseauAmontProvider);
    final n = ref.read(reseauAmontProvider.notifier);

    return CarteSection(
      titre: 'Réseau amont et transformateur',
      icone: Icons.electric_meter_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GrilleChamps(children: [
            const SelecteurTarif(),
            ChoixOuAutre(
              label: 'Tension entre phases',
              valeur: r.u0,
              choix: tensionsUsuelles,
              unite: 'V',
              minimum: 1,
              onChanged: (v) => n.modifier((x) => x.copyWith(u0: v)),
            ),
            ChampNombre(
              key: const ValueKey('ik-pcc'),
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
              key: const ValueKey('ik-nbt'),
              label: 'Transformateurs en parallèle',
              valeurInitiale: r.nbTransfos.toString(),
              entier: true,
              minimum: 1,
              onValide: (v) =>
                  n.modifier((x) => x.copyWith(nbTransfos: v.toInt())),
            ),
          ]),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Transformateur fabriqué avant juillet 2003'),
            value: r.transfoAvant2003,
            onChanged: (v) =>
                n.modifier((x) => x.copyWith(transfoAvant2003: v)),
          ),
        ],
      ),
    );
  }
}

class _CarteLiaison extends ConsumerWidget {
  const _CarteLiaison({
    required this.indice,
    required this.liaison,
    required this.point,
    required this.supprimable,
  });

  final int indice;
  final LiaisonUi liaison;
  final ResultatIkMaxPoint point;
  final bool supprimable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = liaison.liaison;
    final id = liaison.id;
    final n = ref.read(liaisonsProvider.notifier);
    void maj(LiaisonIkMax Function(LiaisonIkMax) f) => n.modifier(id, f);
    final sections = {for (final s in sectionsUsuelles) s: fmtCompact(s)};

    return CarteSection(
      titre: 'Liaison ${nomLiaison(indice)}',
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
              key: ValueKey('ik-long-$id'),
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
              key: ValueKey('ik-nbp-$id'),
              label: 'Phases par pôle',
              valeurInitiale: l.nbPhasesParPole.toString(),
              entier: true,
              minimum: 1,
              onValide: (v) =>
                  maj((x) => x.copyWith(nbPhasesParPole: v.toInt())),
            ),
            ListeDeroulante<double>(
              label: 'Section neutre (mm²)',
              valeur: l.sectionNeutre,
              options: sections,
              onChanged: (v) => maj((x) => x.copyWith(sectionNeutre: v)),
            ),
            ChampNombre(
              key: ValueKey('ik-nbn-$id'),
              label: 'Neutres par pôle',
              valeurInitiale: l.nbNeutresParPole.toString(),
              entier: true,
              minimum: 1,
              onValide: (v) =>
                  maj((x) => x.copyWith(nbNeutresParPole: v.toInt())),
            ),
          ]),
          const SizedBox(height: 18),
          _BandeauIk(nom: nomPoint(indice), point: point),
        ],
      ),
    );
  }
}

class _BandeauIk extends StatelessWidget {
  const _BandeauIk({required this.nom, required this.point});

  final String nom;
  final ResultatIkMaxPoint point;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;

    Widget valeur(String libelle, double v) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(libelle,
                  style: texte.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text('${_ka(v)} kA',
                  style: texte.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          valeur('Ik3 en $nom', point.ik3),
          valeur('Ik2', point.ik2),
          valeur('Ik1', point.ik1),
        ],
      ),
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(ikMaxResultatProvider);
    final reseau = ref.watch(reseauAmontProvider);
    final tgbt = res.points.first;
    final cs = Theme.of(context).colorScheme;
    final texte = Theme.of(context).textTheme;

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
      libelle: 'Ik3 maximal au TGBT',
      valeur: _ka(tgbt.ik3),
      unite: 'kA',
      details: [
        LigneDetail('Ik2 au TGBT', '${_ka(tgbt.ik2)} kA'),
        LigneDetail('Ik1 au TGBT', '${_ka(tgbt.ik1)} kA'),
        if (reseau.nbTransfos == 1)
          LigneDetail(
              'Ik3 au secondaire du transformateur', '${_ka(res.ik3Transfo)} kA'),
      ],
      extra: res.points.length > 1
          ? Table(
              columnWidths: const {0: FlexColumnWidth(1.2)},
              border: TableBorder(
                horizontalInside: BorderSide(color: cs.outlineVariant),
              ),
              children: [
                ligne(['Point', 'Ik3', 'Ik2', 'Ik1'], entete: true),
                for (var i = 0; i < res.points.length; i++)
                  ligne([
                    nomPoint(i),
                    _ka(res.points[i].ik3),
                    _ka(res.points[i].ik2),
                    _ka(res.points[i].ik1),
                  ]),
              ],
            )
          : null,
      pied: 'Valeurs en kA. Ik3 = 1,05 × c × U / (√3 × Z), '
          'Ik2 = 0,866 × Ik3. Tables NF C 15-100 / IEC 60909, '
          'valeurs de l\'édition 2013.',
    );
  }
}
