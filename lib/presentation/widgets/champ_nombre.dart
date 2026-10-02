import 'package:flutter/material.dart';

/// Champ numérique (virgule ou point). N'appelle [onValide] que si la valeur
/// est valide, sinon affiche une erreur et conserve la dernière valeur.
class ChampNombre extends StatefulWidget {
  const ChampNombre({
    super.key,
    required this.label,
    required this.valeurInitiale,
    required this.onValide,
    this.entier = false,
    this.minimum,
    this.maximum,
    this.aide,
    this.suffixe,
  });

  final String label;
  final String valeurInitiale;
  final ValueChanged<double> onValide;
  final bool entier;
  final double? minimum;
  final double? maximum;
  final String? aide;
  final String? suffixe;

  @override
  State<ChampNombre> createState() => _ChampNombreState();
}

class _ChampNombreState extends State<ChampNombre> {
  String? _erreur;

  void _changer(String texte) {
    final v = double.tryParse(texte.trim().replaceAll(',', '.'));
    String? erreur;
    if (v == null || (widget.entier && v != v.roundToDouble())) {
      erreur = widget.entier ? 'Entier attendu' : 'Nombre attendu';
    } else if (widget.minimum != null && v < widget.minimum!) {
      erreur = 'Minimum : ${widget.minimum}';
    } else if (widget.maximum != null && v > widget.maximum!) {
      erreur = 'Maximum : ${widget.maximum}';
    }
    setState(() => _erreur = erreur);
    if (erreur == null) widget.onValide(v!);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: widget.valeurInitiale,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.aide,
        helperMaxLines: 2,
        suffixText: widget.suffixe,
        errorText: _erreur,
      ),
      onChanged: _changer,
    );
  }
}
