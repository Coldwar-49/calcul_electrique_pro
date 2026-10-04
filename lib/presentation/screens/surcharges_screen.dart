import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/coefficient_k.dart';
import '../../core/donnees/coefficients_k.dart';
import '../../core/donnees/sections_resistivites.dart';
import '../../core/donnees/types.dart';
import '../formats.dart';
import '../providers/surcharge_provider.dart';
import '../widgets/carte_section.dart';
import '../widgets/champ_nombre.dart';
import '../widgets/liste_deroulante.dart';
import '../widgets/mise_en_page_calcul.dart';
import '../widgets/panneau_resultat.dart';

const _libellesMode = {
  ModePose.b: 'B — Conduits, vides de construction, goulottes',
  ModePose.c: 'C — Fixé aux parois, chemin de câbles non perforé',
  ModePose.d: 'D — Canalisations enterrées',
  ModePose.e: 'E — Multipolaires sur corbeaux, colliers, chemins perforés',
  ModePose.f: 'F — Unipolaires sur corbeaux, colliers, chemins perforés',
};

const _libellesDistance = {
  DistanceCables.nulle: 'Nulle (câbles jointifs)',
  DistanceCables.undiametre: 'Un diamètre de câble',
  DistanceCables.cm25: '25 cm',
  DistanceCables.cm50: '50 cm',
  DistanceCables.m1: '1 mètre',
};

final _k7ModeB = {
  1.0: 'Aucun cas particulier (1)',
  0.7: 'Câbles multiconducteurs en conduits encastrés, parois isolantes (0,70)',
  0.77: 'Conducteurs isolés en conduits encastrés, parois isolantes (0,77)',
  0.865: 'Câbles en conduits profilés dans vides de construction (0,865)',
  0.9: 'Câbles en conduits apparents, goulottes (0,90)',
  0.95: 'Conducteurs en conduits ou câbles en caniveaux fermés (0,95)',
};

final _k7ModeC = {
  1.0: 'Aucun cas particulier (1)',
  0.95: 'Câbles fixés au plafond (0,95)',
  1.21: 'Conducteurs sur isolateurs (1,21)',
};

const _libellesCouches = {
  1: '1',
  2: '2',
  3: '3',
  4: '4 à 5',
  6: '6 à 8',
  9: '9 et plus',
};

class SurchargesScreen extends StatelessWidget {
  const SurchargesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MiseEnPageCalcul(
      titre: 'Protection contre les surcharges',
      sousTitre: 'Courant admissible, coefficient K et calibre de la protection',
      icone: Icons.shield_outlined,
      formulaire: _Formulaire(),
      resultat: _Resultat(),
    );
  }
}

class _Formulaire extends ConsumerWidget {
  const _Formulaire();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(surchargeEntreeProvider);
    final n = ref.read(surchargeEntreeProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarteSection(
          titre: 'Câble et circuit',
          icone: Icons.cable_outlined,
          child: Column(
            children: [
              GrilleChamps(children: [
                ListeDeroulante<String>(
                  label: 'Type de câble',
                  valeur: e.typeCable,
                  options: {for (final t in isolantParTypeCable.keys) t: t},
                  onChanged: (v) => n.modifier((s) => s.copyWith(typeCable: v)),
                ),
                ListeDeroulante<Ame>(
                  label: 'Âme',
                  valeur: e.ame,
                  options: const {
                    Ame.cuivre: 'Cuivre',
                    Ame.aluminium: 'Aluminium',
                  },
                  onChanged: (v) => n.modifier((s) => s.copyWith(ame: v)),
                ),
                ListeDeroulante<Circuit>(
                  label: 'Circuit',
                  valeur: e.circuit,
                  options: const {
                    Circuit.monophase: 'Monophasé',
                    Circuit.triphase: 'Triphasé',
                  },
                  onChanged: (v) => n.modifier((s) => s.copyWith(circuit: v)),
                ),
                ListeDeroulante<double>(
                  label: 'Section (mm²)',
                  valeur: e.section,
                  options: {
                    for (final s in sectionsUsuelles) s: fmtCompact(s),
                  },
                  onChanged: (v) => n.modifier((s) => s.copyWith(section: v)),
                ),
              ]),
              const SizedBox(height: 14),
              ListeDeroulante<ModePose>(
                label: 'Mode de pose',
                valeur: e.mode,
                options: _libellesMode,
                onChanged: (v) => n.modifier((s) => s.copyWith(mode: v)),
              ),
              const SizedBox(height: 14),
              GrilleChamps(children: [
                ChampNombre(
                  label: 'Conducteurs en parallèle par phase',
                  valeurInitiale: e.nbParalleles.toString(),
                  entier: true,
                  minimum: 1,
                  onValide: (v) =>
                      n.modifier((s) => s.copyWith(nbParalleles: v.toInt())),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CarteSection(
          titre: 'Coefficient K',
          icone: Icons.tune_rounded,
          action: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Assisté')),
              ButtonSegment(value: false, label: Text('Manuel')),
            ],
            selected: {e.kAssiste},
            onSelectionChanged: (s) =>
                n.modifier((x) => x.copyWith(kAssiste: s.first)),
          ),
          child: e.kAssiste ? const _AssistantK() : const _KManuel(),
        ),
      ],
    );
  }
}

class _KManuel extends ConsumerWidget {
  const _KManuel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(surchargeEntreeProvider);
    return ChampNombre(
      label: 'Coefficient K',
      valeurInitiale: e.kManuel.toString().replaceAll('.', ','),
      minimum: 0.01,
      aide: 'Produit de vos facteurs de correction (1 si aucun).',
      onValide: (v) => ref
          .read(surchargeEntreeProvider.notifier)
          .modifier((s) => s.copyWith(kManuel: v)),
    );
  }
}

class _AssistantK extends ConsumerWidget {
  const _AssistantK();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(surchargeEntreeProvider);
    final n = ref.read(surchargeEntreeProvider.notifier);
    final p = e.paramsK;
    final mode = e.mode;
    final sol = mode == ModePose.d;
    final vue = ref.watch(surchargeVueProvider);

    final temperature = temperatureEffective(mode, e.isolant, p.temperature);
    final nbMax = nombreMaxCircuits(mode, edition: p.edition);
    final nbCircuits = p.nbCircuits < nbMax ? p.nbCircuits : nbMax;

    // En 2024, le 0,95 « plafond » est inclus dans le tableau 52.12 (point 3) :
    // on ne le propose plus en K7 pour ne pas le compter deux fois.
    final k7C = p.edition == EditionNorme.norme2013
        ? _k7ModeC
        : {for (final e in _k7ModeC.entries) if (e.key != 0.95) e.key: e.value};

    String libelleNb(int i) =>
        (i == nbMax && mode != ModePose.d) ? '$i et plus' : '$i';

    Widget interrupteur(String titre, bool valeur, ValueChanged<bool> f) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(titre),
          value: valeur,
          onChanged: f,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GrilleChamps(children: [
          ListeDeroulante<int>(
            label: sol ? 'Température du sol' : 'Température ambiante',
            valeur: temperature,
            options: {
              for (final t in temperaturesDisponibles(e.isolant, sol: sol))
                t: (e.isolant == Isolant.pvc && t == 60) ? '≥ 60 °C' : '$t °C',
            },
            onChanged: (v) => n.modifierK((k) => k.copyWith(temperature: v)),
          ),
          ListeDeroulante<int>(
            label: 'Circuits ou câbles multiconducteurs groupés',
            valeur: nbCircuits,
            options: {for (var i = 1; i <= nbMax; i++) i: libelleNb(i)},
            onChanged: (v) => n.modifierK((k) => k.copyWith(nbCircuits: v)),
          ),
          if (!sol)
            ListeDeroulante<int>(
              label: 'Nombre de couches',
              valeur: p.nbCouches,
              options: _libellesCouches,
              onChanged: (v) => n.modifierK((k) => k.copyWith(nbCouches: v)),
            ),
          if (sol)
            ListeDeroulante<DistanceCables>(
              label: 'Distance entre câbles',
              valeur: p.distance,
              options: _libellesDistance,
              onChanged: (v) => n.modifierK((k) => k.copyWith(distance: v)),
            ),
          if (mode == ModePose.b)
            ListeDeroulante<double>(
              label: 'Coefficient complémentaire K7',
              valeur: _k7ModeB.containsKey(p.k7) ? p.k7 : 1.0,
              options: _k7ModeB,
              onChanged: (v) => n.modifierK((k) => k.copyWith(k7: v)),
            ),
          if (mode == ModePose.c)
            ListeDeroulante<double>(
              label: 'Coefficient complémentaire K7',
              valeur: k7C.containsKey(p.k7) ? p.k7 : 1.0,
              options: k7C,
              onChanged: (v) => n.modifierK((k) => k.copyWith(k7: v)),
            ),
        ]),
        const SizedBox(height: 8),
        if (mode == ModePose.c)
          interrupteur('Pose au plafond', p.plafond,
              (v) => n.modifierK((k) => k.copyWith(plafond: v))),
        if (mode == ModePose.e || mode == ModePose.f)
          interrupteur('Tablette perforée', p.tablettePerforee,
              (v) => n.modifierK((k) => k.copyWith(tablettePerforee: v))),
        interrupteur('Risque BE3 (K4 = 0,85)', p.risqueBe3,
            (v) => n.modifierK((k) => k.copyWith(risqueBe3: v))),
        interrupteur(
            p.edition == EditionNorme.norme2013
                ? 'Harmoniques de rang 3 > 15 % (K5 = 0,84)'
                : 'Harmoniques de rang 3 de 15 à 33 % (K5 = 0,86)',
            p.harmoniquesSup15,
            (v) => n.modifierK((k) => k.copyWith(harmoniquesSup15: v))),
        if (p.harmoniquesSup15) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Au-delà de 33 %, le neutre dimensionne le câble (tableau '
              '52.20) : voir l\'écran « Section du neutre ».',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        interrupteur('Disposition symétrique (sinon K6 = 0,8)', p.symetrique,
            (v) => n.modifierK((k) => k.copyWith(symetrique: v))),
        interrupteur(
            'Coefficients du classeur (2013) pour K2 et K5',
            p.edition == EditionNorme.norme2013,
            (v) => n.modifierK((k) => k.copyWith(
                edition: v
                    ? EditionNorme.norme2013
                    : EditionNorme.normeActuelle))),
        if (sol)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Mode D : K3 (conduits) et K4 (même conduit) sont pris à 1.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        const Divider(height: 28),
        Row(
          children: [
            Expanded(
              child: Text('K retenu',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
            Text(fmt(vue.k, 4),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _Resultat extends ConsumerWidget {
  const _Resultat();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vue = ref.watch(surchargeVueProvider);
    final e = ref.watch(surchargeEntreeProvider);
    final r = vue.resultat;

    if (r == null) {
      return PanneauResultat(
        libelle: 'Calcul impossible',
        valeur: '—',
        statut: StatutResultat.nonConforme,
        messageStatut: vue.erreur,
      );
    }

    final calibre = r.calibre;
    return PanneauResultat(
      libelle: 'Calibre maximal de la protection (In)',
      valeur: calibre == null ? '!' : fmtCompact(calibre),
      unite: calibre == null ? null : 'A',
      statut: calibre == null ? StatutResultat.nonConforme : StatutResultat.neutre,
      messageStatut: calibre == null
          ? 'Courant trop faible (< 0,655 A) ou aucune formule applicable '
              'pour cette section.'
          : null,
      details: [
        LigneDetail('Courant admissible I', '${fmt(r.i)} A'),
        LigneDetail('Courant de base (a × S^b)', '${fmt(r.courantBase)} A'),
        LigneDetail('Coefficient K', fmt(vue.k, 4)),
        LigneDetail('Conducteurs en parallèle', '${e.nbParalleles}'),
      ],
      pied: 'I = K × n × (a × S^b) × 1,05. '
          'Tables NF C 15-100, valeurs de l\'édition 2013.',
    );
  }
}
