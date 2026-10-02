import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculs/contacts_indirects.dart';
import '../../core/calculs/ik_min.dart' show RegimeNeutre;
import '../../core/donnees/courbes_disjoncteurs.dart';
import '../../core/donnees/fusibles.dart';
import '../../core/donnees/types.dart';
import 'resistance_pe_provider.dart' show FamillePe, TypeDisjoncteurPe;

class ContactsEntree {
  const ContactsEntree({
    this.famille = FamillePe.disjoncteur,
    this.sphEgalSpe = true,
    this.regime = RegimeNeutre.tn,
    this.tensionPhN = 230,
    this.tensionPhPh = 400,
    this.typeDisjoncteur = TypeDisjoncteurPe.petit,
    this.courbe = CourbeDisjoncteur.c,
    this.multipleIr = 10,
    this.ir = 10,
    this.typeFusible = TypeFusible.gg,
    this.calibreFusible = 16,
    this.ame = Ame.cuivre,
    this.sectionPh = 2.5,
    this.nbPh = 1,
    this.sectionPe = 2.5,
    this.nbPe = 1,
  });

  final FamillePe famille;
  final bool sphEgalSpe;
  final RegimeNeutre regime;
  final double tensionPhN;
  final double tensionPhPh;
  final TypeDisjoncteurPe typeDisjoncteur;
  final CourbeDisjoncteur courbe;
  final double multipleIr;
  final double ir;
  final TypeFusible typeFusible;
  final double calibreFusible;
  final Ame ame;
  final double sectionPh;
  final int nbPh;
  final double sectionPe;
  final int nbPe;

  ReglageMagnetique get reglage => typeDisjoncteur == TypeDisjoncteurPe.petit
      ? ReglageMagnetique.courbe(courbe)
      : ReglageMagnetique.multipleIr(multipleIr);

  ContactsEntree copyWith({
    FamillePe? famille,
    bool? sphEgalSpe,
    RegimeNeutre? regime,
    double? tensionPhN,
    double? tensionPhPh,
    TypeDisjoncteurPe? typeDisjoncteur,
    CourbeDisjoncteur? courbe,
    double? multipleIr,
    double? ir,
    TypeFusible? typeFusible,
    double? calibreFusible,
    Ame? ame,
    double? sectionPh,
    int? nbPh,
    double? sectionPe,
    int? nbPe,
  }) =>
      ContactsEntree(
        famille: famille ?? this.famille,
        sphEgalSpe: sphEgalSpe ?? this.sphEgalSpe,
        regime: regime ?? this.regime,
        tensionPhN: tensionPhN ?? this.tensionPhN,
        tensionPhPh: tensionPhPh ?? this.tensionPhPh,
        typeDisjoncteur: typeDisjoncteur ?? this.typeDisjoncteur,
        courbe: courbe ?? this.courbe,
        multipleIr: multipleIr ?? this.multipleIr,
        ir: ir ?? this.ir,
        typeFusible: typeFusible ?? this.typeFusible,
        calibreFusible: calibreFusible ?? this.calibreFusible,
        ame: ame ?? this.ame,
        sectionPh: sectionPh ?? this.sectionPh,
        nbPh: nbPh ?? this.nbPh,
        sectionPe: sectionPe ?? this.sectionPe,
        nbPe: nbPe ?? this.nbPe,
      );
}

class ContactsNotifier extends Notifier<ContactsEntree> {
  @override
  ContactsEntree build() => const ContactsEntree();

  void modifier(ContactsEntree Function(ContactsEntree) f) => state = f(state);
}

final contactsEntreeProvider =
    NotifierProvider<ContactsNotifier, ContactsEntree>(ContactsNotifier.new);

class ContactsVue {
  const ContactsVue({
    this.longueurs,
    this.coefficientDistribution,
    this.avertissements = const [],
    this.erreur,
  });

  final LongueursMax? longueurs;

  /// Coefficient des circuits de distribution (fusibles uniquement).
  final double? coefficientDistribution;

  /// Points du classeur reproduits à l'identique mais à vérifier.
  final List<String> avertissements;
  final String? erreur;
}

final contactsVueProvider = Provider<ContactsVue>((ref) {
  final e = ref.watch(contactsEntreeProvider);
  try {
    if (e.famille == FamillePe.disjoncteur) {
      final r = e.sphEgalSpe
          ? longueurMaxDisjoncteurSphEgalSpe(
              reglage: e.reglage,
              ir: e.ir,
              section: e.sectionPh,
              nbConducteurs: e.nbPh,
              ame: e.ame,
              tensionPhN: e.tensionPhN,
              tensionPhPh: e.tensionPhPh,
            )
          : longueurMaxDisjoncteurSphDiffSpe(
              reglage: e.reglage,
              ir: e.ir,
              sectionPh: e.sectionPh,
              nbPh: e.nbPh,
              sectionPe: e.sectionPe,
              nbPe: e.nbPe,
              ame: e.ame,
              tensionPhN: e.tensionPhN,
              tensionPhPh: e.tensionPhPh,
            );
      return ContactsVue(longueurs: r);
    }

    final r = e.sphEgalSpe
        ? longueurMaxFusibleSphEgalSpe(
            type: e.typeFusible,
            calibre: e.calibreFusible,
            section: e.sectionPh,
            nbConducteurs: e.nbPh,
            ame: e.ame,
            tensionPhN: e.tensionPhN,
            tensionPhPh: e.tensionPhPh,
          )
        : longueurMaxFusibleSphDiffSpe(
            type: e.typeFusible,
            calibre: e.calibreFusible,
            sectionPh: e.sectionPh,
            nbPh: e.nbPh,
            sectionPe: e.sectionPe,
            nbPe: e.nbPe,
            ame: e.ame,
            tensionPhN: e.tensionPhN,
            tensionPhPh: e.tensionPhPh,
          );

    final avertissements = <String>[];
    if (!e.sphEgalSpe && e.regime == RegimeNeutre.itsn) {
      avertissements.add(
          'Régime ITSN avec Sph ≠ Spe : la formule du classeur ne contient ni '
          'le courant de fusion Ia ni la section de phase. Le résultat est '
          'repris tel quel mais n\'est pas cohérent avec le cas Sph = Spe : '
          'à vérifier avant de l\'utiliser.');
    }
    if (!e.sphEgalSpe && e.typeFusible == TypeFusible.am) {
      avertissements.add(
          'Fusible aM avec Sph ≠ Spe : le classeur applique 1,88 pour les '
          'circuits de distribution (1,53 avec Sph = Spe et dans le calcul de '
          'la résistance du PE). Valeur reprise telle quelle, à vérifier.');
    }
    return ContactsVue(
      longueurs: r.terminaux,
      coefficientDistribution: r.coefficientDistribution,
      avertissements: avertissements,
    );
  } on ArgumentError catch (ex) {
    return ContactsVue(erreur: ex.message?.toString());
  }
});
