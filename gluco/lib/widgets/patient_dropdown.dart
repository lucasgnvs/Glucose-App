import 'package:flutter/material.dart';
import 'package:gluco/extensions/buildcontext/loc.dart';
import 'package:gluco/models/patient.dart';

class PatientDropdown extends StatelessWidget {
  const PatientDropdown({
    Key? key,
    required this.controller,
    required this.entries,
    this.shadow = false,
    this.onSelected,
  }) : super(key: key);

  final TextEditingController controller;
  final List<Patient> entries;
  final bool shadow;
  final Function(Patient?)? onSelected;

  @override
  Widget build(BuildContext context) {
    Patient? initial;
    try {
      initial = entries.first;
    } catch (_) {}
    return Card(
      elevation: shadow ? 4.0 : 0.0,
      margin: EdgeInsets.zero,
      child: DropdownMenu<Patient>(
        label: Text(context.loc.patient),
        controller: controller,
        // enableFilter: true,
        expandedInsets: EdgeInsets.zero,
        initialSelection: controller.text.isEmpty ? initial : null,
        onSelected: onSelected,
        textStyle: const TextStyle(color: Colors.black),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: UnderlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide.none,
          ),
        ),
        dropdownMenuEntries: entries.map((e) {
          return DropdownMenuEntry<Patient>(
            value: e,
            label: e.serviceNumber,
          );
        }).toList(),
      ),
    );
  }
}
