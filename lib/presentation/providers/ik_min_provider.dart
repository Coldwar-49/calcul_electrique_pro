import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/ik_max.dart';
import '../../core/calculs/ik_min.dart';
import '../../core/donnees/courbes_disjoncteurs.dart';
import '../../core/donnees/types.dart';
import 'triangle_provider.dart' show ChoixReglage;

enum SourceIk {
  transformateur('Transformateur'),
  groupe('Groupe électrogène');

  const SourceIk(this.libelle);
  final String libelle;
}

class SourceNotifier extends Notifier<SourceIk> {
  @override
  SourceIk build() => SourceIk.transformateur;

  void choisir(SourceIk s) => state = s;
}

final sourceIkProvider =
    NotifierProvider<SourceNotifier, SourceIk>(SourceNotifier.new);

class RegimeNotifier extends Notifier<RegimeNeutre> {
  @override
  RegimeNeutre build() => RegimeNeutre.tn;

  void choisir(RegimeNeutre r) => state = r;
}

final regimeNeutreProvider =
    NotifierProvider<RegimeNotifier, RegimeNeutre>(RegimeNotifier.new);

/// Transformateur et réseau amont (mêmes champs que l'écran Ik max).
class TransfoMinNotifier extends Notifier<ReseauAmont> {
  @override
  ReseauAmont build() => const ReseauAmont();

  void modifier(ReseauAmont Function(ReseauAmont) f) => state = f(state);
}

final transfoMinProvider =
    NotifierProvider<TransfoMinNotifier, ReseauAmont>(TransfoMinNotifier.new);

class GroupeElectrogene {
  const GroupeElectrogene({
    this.u0 = 400,
    this.nbGroupes = 1,
    this.puissanceKva = 2500,
    this.xdPourcent = 30,
    this.x0Pourcent = 6,
  });

  final double u0;
  final int nbGroupes;
  final double puissanceKva;
  final double xdPourcent;
  final double x0Pourcent;

  GroupeElectrogene copyWith({
    double? u0,
    int? nbGroupes,
    double? puissanceKva,
    double? xdPourcent,
    double? x0Pourcent,
  }) =>
      GroupeElectrogene(
        u0: u0 ?? this.u0,
        nbGroupes: nbGroupes ?? this.nbGroupes,
        puissanceKva: puissanceKva ?? this.puissanceKva,
        xdPourcent: xdPourcent ?? this.xdPourcent,
        x0Pourcent: x0Pourcent ?? this.x0Pourcent,
      );
}

class GroupeNotifier extends Notifier<GroupeElectrogene> {
  @override
  GroupeElectrogene build() => const GroupeElectrogene();

  void modifier(GroupeElectrogene Function(GroupeElectrogene) f) =>
      state = f(state);
}

final groupeProvider =
    NotifierProvider<GroupeNotifier, GroupeElectrogene>(GroupeNotifier.new);

/// Liaison saisie dans l'interface, avec sa protection éventuelle.
class LiaisonMinUi {
  const LiaisonMinUi({
    required this.id,
    this.ame = Ame.cuivre,
    this.longueur = 10,
    this.sectionPhase = 10,
    this.nbPhases = 1,
    this.sectionPe = 10,
    this.nbPe = 1,
    this.choixReglage = ChoixReglage.c,
    this.multipleIr = 8,
    this.ir = 40,
  });

  final int id;
  final Ame ame;
  final double longueur;
  final double sectionPhase;
  final int nbPhases;
  final double sectionPe;
  final int nbPe;
  final ChoixReglage choixReglage;
  final double multipleIr;
  final double ir;

  LiaisonMinUi copyWith({
    Ame? ame,
    double? longueur,
    double? sectionPhase,
    int? nbPhases,
    double? sectionPe,
    int? nbPe,
    ChoixReglage? choixReglage,
    double? multipleIr,
    double? ir,
  }) =>
      LiaisonMinUi(
        id: id,
        ame: ame ?? this.ame,
        longueur: longueur ?? this.longueur,
        sectionPhase: sectionPhase ?? this.sectionPhase,
        nbPhases: nbPhases ?? this.nbPhases,
        sectionPe: sectionPe ?? this.sectionPe,
        nbPe: nbPe ?? this.nbPe,
        choixReglage: choixReglage ?? this.choixReglage,
        multipleIr: multipleIr ?? this.multipleIr,
        ir: ir ?? this.ir,
      );

  /// Même liaison avec un autre identifiant (copie pour une nouvelle liaison).
  LiaisonMinUi avecId(int nouvelId) => LiaisonMinUi(
        id: nouvelId,
        ame: ame,
        longueur: longueur,
        sectionPhase: sectionPhase,
        nbPhases: nbPhases,
        sectionPe: sectionPe,
        nbPe: nbPe,
        choixReglage: choixReglage,
        multipleIr: multipleIr,
        ir: ir,
      );

  ReglageMagnetique get reglage => choixReglage.courbe != null
      ? ReglageMagnetique.courbe(choixReglage.courbe!)
      : ReglageMagnetique.multipleIr(multipleIr);

  LiaisonIkMin versMoteur({required bool avecProtection}) => LiaisonIkMin(
        ame: ame,
        longueur: longueur,
        sectionPhase: sectionPhase,
        nbPhasesParPole: nbPhases,
        sectionPe: sectionPe,
        nbPeParPole: nbPe,
        protection:
            avecProtection ? ProtectionIk(reglage: reglage, ir: ir) : null,
      );
}

class LiaisonsMinNotifier extends Notifier<List<LiaisonMinUi>> {
  LiaisonsMinNotifier(this.groupe);

  final bool groupe;
  int _prochainId = 1;

  @override
  List<LiaisonMinUi> build() => groupe
      ? [
          LiaisonMinUi(
              id: _prochainId++,
              longueur: 10,
              sectionPhase: 25,
              sectionPe: 25,
              ir: 100),
          LiaisonMinUi(id: _prochainId++, longueur: 30, ir: 40),
        ]
      : [
          LiaisonMinUi(
              id: _prochainId++, longueur: 5, sectionPhase: 25, sectionPe: 25),
          LiaisonMinUi(id: _prochainId++, longueur: 30, ir: 40),
        ];

  /// Ajoute une liaison en aval, en reprenant les réglages de la dernière.
  void ajouter() {
    final modele = state.isEmpty ? LiaisonMinUi(id: 0) : state.last;
    state = [...state, modele.avecId(_prochainId++)];
  }

  void supprimerDerniere() {
    if (state.length <= 1) return;
    state = state.sublist(0, state.length - 1);
  }

  void modifier(int id, LiaisonMinUi Function(LiaisonMinUi) f) {
    state = [for (final l in state) l.id == id ? f(l) : l];
  }
}

final liaisonsTransfoProvider =
    NotifierProvider<LiaisonsMinNotifier, List<LiaisonMinUi>>(
        () => LiaisonsMinNotifier(false));

final liaisonsGroupeProvider =
    NotifierProvider<LiaisonsMinNotifier, List<LiaisonMinUi>>(
        () => LiaisonsMinNotifier(true));

/// Liste de liaisons de la source choisie.
NotifierProvider<LiaisonsMinNotifier, List<LiaisonMinUi>> liaisonsDe(
        SourceIk s) =>
    s == SourceIk.groupe ? liaisonsGroupeProvider : liaisonsTransfoProvider;

// ------------------------------------------------------------- libellés

String nomArrivee(int i) => i == 0 ? 'TGBT' : 'TD$i';

String nomLiaisonMin(SourceIk s, int i) {
  if (i == 0) {
    return s == SourceIk.groupe ? 'Groupe → TGBT' : 'Source → TGBT';
  }
  return '${nomArrivee(i - 1)} → ${nomArrivee(i)}';
}

/// Le transformateur n'a pas de protection sur sa première liaison.
bool aProtection(SourceIk s, int i) => s == SourceIk.groupe || i > 0;

/// Nom du disjoncteur de la liaison [i] (noms repris du classeur).
String nomProtection(SourceIk s, int i) {
  if (s == SourceIk.groupe) {
    return i == 0 ? 'GE' : (i == 1 ? 'TGBT' : 'TD${i - 1}');
  }
  return 'TD$i';
}

// -------------------------------------------------------------- résultat

class IkMinVue {
  const IkMinVue({required this.source, required this.points});

  final SourceIk source;
  final List<ResultatIkMinPoint> points;
}

final ikMinVueProvider = Provider<IkMinVue>((ref) {
  final s = ref.watch(sourceIkProvider);
  final regime = ref.watch(regimeNeutreProvider);
  final liaisons = ref.watch(liaisonsDe(s));

  final impedance = s == SourceIk.groupe
      ? _sourceGroupe(ref.watch(groupeProvider))
      : _sourceTransfo(ref.watch(transfoMinProvider));

  final points = calculerIkMin(impedance, regime, [
    for (var i = 0; i < liaisons.length; i++)
      liaisons[i].versMoteur(avecProtection: aProtection(s, i)),
  ]);
  return IkMinVue(source: s, points: points);
});

ImpedanceSource _sourceTransfo(ReseauAmont r) => sourceTransformateur(
      u0: r.u0,
      pccMva: r.pccMva,
      couplage: r.couplage,
      puissanceKva: r.puissanceKva,
      uccPourcent: r.uccPourcent,
      nbTransfos: r.nbTransfos,
    );

ImpedanceSource _sourceGroupe(GroupeElectrogene g) => sourceGroupe(
      u0: g.u0,
      puissanceKva: g.puissanceKva,
      xdPourcent: g.xdPourcent,
      x0Pourcent: g.x0Pourcent,
      nbGroupes: g.nbGroupes,
    );
