import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safecampus/models/journal_entry.dart';
import 'package:safecampus/widgets/custom_app_bar.dart';

class NouvelleEntreePage extends StatefulWidget {
  final JournalEntry entry;
  final void Function(String content, DateTime updatedAt) onSave;

  const NouvelleEntreePage(
      {super.key, required this.entry, required this.onSave});

  @override
  State<NouvelleEntreePage> createState() => _NouvelleEntreePageState();
}

class _NouvelleEntreePageState extends State<NouvelleEntreePage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  late DateTime _lastModified;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.entry.content;
    _lastModified = widget.entry.updatedAt ?? widget.entry.date;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // Annule le timer précédent s'il y en a un
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Lance un nouveau timer (pour l'auto save)
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final now = DateTime.now();
      widget.onSave(_controller.text, now);
      if (mounted) {
        setState(() {
          _lastModified = now;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = widget.entry.date;
    final dateStr =
        "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}";
    final updatedStr =
        "${_lastModified.day.toString().padLeft(2, '0')}/${_lastModified.month.toString().padLeft(2, '0')}/${_lastModified.year} à ${_lastModified.hour.toString().padLeft(2, '0')}h${_lastModified.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: const CustomAppBar(title: "Mon journal"),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage des dates
            Text("Créé le : $dateStr",
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            if (widget.entry.updatedAt != null ||
                _lastModified.isAfter(widget.entry.date))
              Text("Modifié le : $updatedStr",
                  style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: "Écrivez ici ce que vous ressentez...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
