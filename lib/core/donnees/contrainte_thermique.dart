/// Valeurs de k pour la contrainte thermique des conducteurs actifs.
library;

import 'types.dart';

/// Position du conducteur de protection par rapport aux conducteurs actifs.
enum CanalisationPe {
  meme('Phase et PE dans la même canalisation'),
  differentes('Phase et PE dans des canalisations différentes');

  const CanalisationPe(this.libelle);
  final String libelle;
}

/// Nature de l'isolant (ou PE nu) pour le choix de k.
enum IsolantContrainte {
  pvcJusqua300('PVC ≤ 300 mm²'),
  pvcAudessus300('PVC > 300 mm²'),
  prEpr('PR / EPR'),
  peNu('Câble PE nu'),
  peNuBe23('Câble PE nu + risque BE2/BE3');

  const IsolantContrainte(this.libelle);
  final String libelle;
}

/// Isolants proposés selon la position du PE (le PE nu n'existe que si le
/// PE est dans une autre canalisation).
List<IsolantContrainte> isolantsContrainte(CanalisationPe c) =>
    c == CanalisationPe.meme
        ? const [
            IsolantContrainte.pvcJusqua300,
            IsolantContrainte.pvcAudessus300,
            IsolantContrainte.prEpr,
          ]
        : IsolantContrainte.values;

// Édition 2024 (NF C 15-100-1) : même canalisation = tableau 43.1 / 54A.4,
// PVC 70 °C et PR/EPR 90 °C ; canalisations différentes = tableaux 54A.2A
// (isolés), 54A.6A (nu : conditions normales / risque d'incendie).
// (cuivre, aluminium)
const Map<IsolantContrainte, (double, double)> _kMeme2024 = {
  IsolantContrainte.pvcJusqua300: (111, 75),
  IsolantContrainte.pvcAudessus300: (99, 67),
  IsolantContrainte.prEpr: (138, 93),
};

const Map<IsolantContrainte, (double, double)> _kDifferentes2024 = {
  IsolantContrainte.pvcJusqua300: (138, 93),
  IsolantContrainte.pvcAudessus300: (128, 87),
  IsolantContrainte.prEpr: (169, 114),
  IsolantContrainte.peNu: (153, 103),
  IsolantContrainte.peNuBe23: (133, 90),
};

// Édition 2013 (classeur CLAUREG, P7:S18) : (cuivre, aluminium)
const Map<IsolantContrainte, (double, double)> _kMeme = {
  IsolantContrainte.pvcJusqua300: (115, 76),
  IsolantContrainte.pvcAudessus300: (103, 68),
  IsolantContrainte.prEpr: (143, 94),
};

const Map<IsolantContrainte, (double, double)> _kDifferentes = {
  IsolantContrainte.pvcJusqua300: (143, 95),
  IsolantContrainte.pvcAudessus300: (133, 88),
  IsolantContrainte.prEpr: (176, 116),
  IsolantContrainte.peNu: (159, 105),
  IsolantContrainte.peNuBe23: (138, 91),
};

/// Coefficient k. Lève [ArgumentError] pour une combinaison absente de la table.
///
/// [edition] : `normeActuelle` = NF C 15-100-1 (2024), `norme2013` = classeur.
double kContrainteThermique(
    Ame ame, IsolantContrainte isolant, CanalisationPe canalisation,
    {EditionNorme edition = EditionNorme.normeActuelle}) {
  final ancienne = edition == EditionNorme.norme2013;
  final meme = canalisation == CanalisationPe.meme;
  final table = meme
      ? (ancienne ? _kMeme : _kMeme2024)
      : (ancienne ? _kDifferentes : _kDifferentes2024);
  final k = table[isolant];
  if (k == null) {
    throw ArgumentError(
        '${isolant.libelle} : combinaison absente de la table des k');
  }
  return ame == Ame.cuivre ? k.$1 : k.$2;
}
