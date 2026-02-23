import 'package:flutter/material.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';
import 'package:safecampus/widgets/custom_text_field.dart';
import 'package:safecampus/widgets/primary_button.dart';

class NouveauTrajetGroupePage extends StatefulWidget {
  const NouveauTrajetGroupePage({super.key});

  @override
  State<NouveauTrajetGroupePage> createState() =>
      _NouveauTrajetGroupePageState();
}

class _NouveauTrajetGroupePageState extends State<NouveauTrajetGroupePage> {
  final _departController = TextEditingController();
  final _arriveeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _departController.dispose();
    _arriveeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submit() {
    if (_departController.text.isEmpty || _arriveeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text("Veuillez remplir les lieux de départ et d'arrivée."),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Navigator.pop(context, {
      'depart': _departController.text.trim(),
      'arrivee': _arriveeController.text.trim(),
      'date': finalDateTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        "${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}";
    final timeStr =
        "${_selectedTime.hour.toString().padLeft(2, '0')}h${_selectedTime.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: "Nouveau trajet"),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              controller: _departController,
              labelText: "Lieu de départ",
              prefixIcon: Icons.my_location,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _arriveeController,
              labelText: "Lieu d'arrivée",
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 30),
            Text("Date et Heure de départ",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today),
                    label: Text(dateStr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectTime(context),
                    icon: const Icon(Icons.access_time),
                    label: Text(timeStr),
                  ),
                ),
              ],
            ),
            const Spacer(),
            PrimaryButton(text: "Créer le trajet", onPressed: _submit),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
