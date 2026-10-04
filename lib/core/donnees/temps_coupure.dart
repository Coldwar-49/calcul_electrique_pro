/// Temps de coupure maximal des circuits terminaux (NF C 15-100-1, 2024-08,
/// art. 411.3.2.2, tableau 41.1), en secondes.
library;

enum SchemaTemps { tn, tt }

/// Temps de coupure maximal pour la tension simple [u0] (V), ou `null` si
/// U0 ≤ 50 V (hors tableau). [continu] : courant continu lissé.
///
/// En schéma IT, au deuxième défaut, ce sont les temps du TN ou du TT selon
/// le mode de mise à la terre des masses (art. 411.6.4).
double? tempsCoupureMax(double u0, SchemaTemps schema,
    {bool continu = false}) {
  if (u0 <= 50) return null;
  final colonne = u0 <= 120 ? 0 : (u0 <= 230 ? 1 : (u0 <= 400 ? 2 : 3));
  const tnAlternatif = [0.8, 0.4, 0.2, 0.1];
  const tnContinu = [5.0, 5.0, 0.4, 0.1];
  const ttAlternatif = [0.3, 0.2, 0.07, 0.04];
  const ttContinu = [5.0, 0.4, 0.2, 0.1];
  final table = switch ((schema, continu)) {
    (SchemaTemps.tn, false) => tnAlternatif,
    (SchemaTemps.tn, true) => tnContinu,
    (SchemaTemps.tt, false) => ttAlternatif,
    (SchemaTemps.tt, true) => ttContinu,
  };
  return table[colonne];
}
