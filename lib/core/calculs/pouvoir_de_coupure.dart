/// Vérification d'un pouvoir de coupure (Pdc) face à un courant de
/// court-circuit présumé, avec les tables du classeur.
library;

import '../donnees/fusibles.dart';
import '../donnees/pouvoir_de_coupure.dart';

/// Le pouvoir de coupure est suffisant s'il est au moins égal au courant.
bool pdcSuffisant(double pdcKa, double ikKa) => pdcKa >= ikKa;

/// Tailles de fusibles cylindriques proposées pour [type] et [calibre] (A).
List<TailleFusible> taillesPourCalibre(TypeFusible type, double calibre) => [
      for (final t in taillesFusibles)
        if (t.plage(type).contient(calibre)) t,
    ];
