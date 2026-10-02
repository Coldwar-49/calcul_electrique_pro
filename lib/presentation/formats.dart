/// Mise en forme des nombres à la française (virgule décimale).
String fmt(double v, [int decimales = 2]) =>
    v.toStringAsFixed(decimales).replaceAll('.', ',');

/// Courant en kA : 3 décimales sous 1 kA, sinon 2.
String fmtKa(double v) => fmt(v, v < 1 ? 3 : 2);

/// Résistance en mΩ : 1 décimale à partir de 100 mΩ, sinon 2.
String fmtMohm(double v) => fmt(v, v >= 100 ? 1 : 2);

/// Entier sans décimale si la valeur est ronde, sinon la valeur telle quelle.
String fmtCompact(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');
