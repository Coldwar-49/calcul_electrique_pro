/// Sections et résistivités utilisées par le classeur CLAUREG.
library;

import 'types.dart';

/// Réactance linéique par défaut : 0,08 mΩ/m (en Ω/m).
const double reactanceLineique = 0.00008;

/// Sections usuelles en mm² (liste proposée dans l'interface).
const List<double> sectionsUsuelles = [
  1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300, 400,
  500, 630,
];

/// Correctif du classeur : la section 50 mm² est remplacée par 47,5.
double corrigerSection(double section) => section == 50 ? 47.5 : section;

/// Résistivité (Ω·mm²/m) pour la chute de tension, Ik min, règle du triangle.
double rhoChuteTension(Ame ame) => ame == Ame.cuivre ? 0.023 : 0.037;

/// Résistivité pour le calcul de Ik max.
double rhoIkMax(Ame ame) => ame == Ame.cuivre ? 0.01851 : 0.0294;

/// Résistivité pour la contrainte thermique (protection par fusible).
double rhoContrainteThermique(Ame ame) => ame == Ame.cuivre ? 0.028 : 0.044;

/// Résistivité (Ω·mm²/m) à la température de service normale, pour la chute
/// de tension (NF C 15-100-1, 2024, tableau 52.24). [classeur] garde la valeur
/// unique du classeur CLAUREG (0,023 Cu / 0,037 Al).
enum ResistiviteService {
  classeur('Valeur du classeur (0,023 Cu / 0,037 Al)', 0.023, 0.037),
  caoutchouc60('Caoutchouc 60 °C', 0.0215, 0.0341),
  pvc70('PVC 70 °C', 0.0222, 0.0353),
  pvc90('PVC 90 °C', 0.0237, 0.0376),
  pr90('PR 90 °C', 0.0237, 0.0376),
  pr120('PR 120 °C', 0.0259, 0.0412);

  const ResistiviteService(this.libelle, this.cuivre, this.aluminium);
  final String libelle;
  final double cuivre;
  final double aluminium;

  double pour(Ame ame) => ame == Ame.cuivre ? cuivre : aluminium;
}
