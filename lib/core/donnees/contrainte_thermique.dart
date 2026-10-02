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

// (cuivre, aluminium)
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
double kContrainteThermique(
    Ame ame, IsolantContrainte isolant, CanalisationPe canalisation) {
  final table = canalisation == CanalisationPe.meme ? _kMeme : _kDifferentes;
  final k = table[isolant];
  if (k == null) {
    throw ArgumentError(
        '${isolant.libelle} : combinaison absente de la table des k');
  }
  return ame == Ame.cuivre ? k.$1 : k.$2;
}
