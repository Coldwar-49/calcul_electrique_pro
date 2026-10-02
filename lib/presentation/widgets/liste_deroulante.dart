import 'package:flutter/material.dart';

/// Liste déroulante générique : [options] associe valeur -> libellé.
/// [valeur] doit toujours figurer dans [options].
class ListeDeroulante<T> extends StatelessWidget {
  const ListeDeroulante({
    super.key,
    required this.label,
    required this.valeur,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T valeur;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // Recrée le champ si la valeur ou la liste change depuis l'extérieur.
      key: ValueKey('$valeur|${options.length}'),
      initialValue: valeur,
      isExpanded: true,
      borderRadius: BorderRadius.circular(14),
      decoration: InputDecoration(labelText: label),
      items: [
        for (final e in options.entries)
          DropdownMenuItem<T>(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
