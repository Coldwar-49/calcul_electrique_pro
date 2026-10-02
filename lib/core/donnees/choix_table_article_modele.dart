/// Ligne du tableau d'aide au choix d'une table article (Opale Électricité).
library;

class LigneChoixTable {
  const LigneChoixTable(
    this.regimeNeutre,
    this.eclairageSecurite,
    this.localElectrique,
    this.risqueBe2,
    this.risqueBe3,
    this.doucheBaignoire,
    this.erp,
    this.coupureBt,
    this.hauteTension,
    this.table,
  );

  final String regimeNeutre;
  final String eclairageSecurite;
  final String localElectrique;
  final String risqueBe2;
  final String risqueBe3;
  final String doucheBaignoire;
  final String erp;
  final String coupureBt;
  final String hauteTension;

  /// Numéro de la table article.
  final int table;

  /// Les neuf critères dans l'ordre de [libellesCriteresTable].
  List<String> get criteres => [
        regimeNeutre,
        eclairageSecurite,
        localElectrique,
        risqueBe2,
        risqueBe3,
        doucheBaignoire,
        erp,
        coupureBt,
        hauteTension,
      ];
}

/// Intitulés des neuf critères (en-têtes du classeur).
const List<String> libellesCriteresTable = [
  'Régime du neutre principal',
  'Éclairage de sécurité',
  'Local électrique',
  'Risque BE2',
  'Risque BE3',
  'Douche / Baignoire',
  'ERP',
  'Coupure BT même partielle',
  'Haute tension',
];
