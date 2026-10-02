import 'package:flutter/material.dart';

import '../formats.dart';
import 'champ_nombre.dart';
import 'liste_deroulante.dart';

/// Liste de valeurs usuelles avec, en dernier choix, « Autre valeur… » qui
/// fait apparaître un champ de saisie libre.
class ChoixOuAutre extends StatefulWidget {
  const ChoixOuAutre({
    super.key,
    required this.label,
    required this.valeur,
    required this.choix,
    required this.unite,
    required this.onChanged,
    this.minimum,
  });

  final String label;
  final double valeur;
  final List<double> choix;

  /// Unité affichée après chaque valeur (« kVA », « % », « V »).
  final String unite;
  final ValueChanged<double> onChanged;
  final double? minimum;

  @override
  State<ChoixOuAutre> createState() => _ChoixOuAutreState();
}

class _ChoixOuAutreState extends State<ChoixOuAutre> {
  static const double _autre = -1;
  late bool _personnalise = !widget.choix.contains(widget.valeur);

  String _texte(double v) => widget.unite == '%'
      ? '${fmtCompact(v)} %'
      : '${fmtCompact(v)} ${widget.unite}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListeDeroulante<double>(
          label: widget.label,
          valeur: _personnalise ? _autre : widget.valeur,
          options: {
            for (final c in widget.choix) c: _texte(c),
            _autre: 'Autre valeur…',
          },
          onChanged: (v) {
            if (v == _autre) {
              setState(() => _personnalise = true);
            } else {
              setState(() => _personnalise = false);
              widget.onChanged(v);
            }
          },
        ),
        if (_personnalise) ...[
          const SizedBox(height: 10),
          ChampNombre(
            label: 'Valeur personnalisée',
            suffixe: widget.unite,
            valeurInitiale: fmtCompact(widget.valeur),
            minimum: widget.minimum,
            onValide: widget.onChanged,
          ),
        ],
      ],
    );
  }
}
