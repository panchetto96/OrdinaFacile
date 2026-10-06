import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../repo.dart';
import '../../ui.dart';

/// Ordine scritto a mano ([withPhoto] false) o con la foto di un foglio.
/// Torna l'id dell'ordine inviato.
class FreeOrderScreen extends StatefulWidget {
  const FreeOrderScreen({super.key, this.withPhoto = false});
  final bool withPhoto;

  @override
  State<FreeOrderScreen> createState() => _FreeOrderScreenState();
}

class _FreeOrderScreenState extends State<FreeOrderScreen> {
  final _text = TextEditingController();
  Uint8List? _photo;
  String _photoExt = 'jpg';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Chi sceglie "Carica foto" vuole subito la fotocamera.
    if (widget.withPhoto) WidgetsBinding.instance.addPostFrameCallback((_) => _pick(ImageSource.camera));
  }

  Future<void> _pick(ImageSource source) async {
    try {
      // Ridotta e compressa: un foglio resta leggibile e pesa poche centinaia di KB.
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1400, maxHeight: 1400, imageQuality: 65);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final dot = file.name.lastIndexOf('.');
      setState(() {
        _photo = bytes;
        _photoExt = dot < 0 ? 'jpg' : file.name.substring(dot + 1);
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _send() async {
    if (widget.withPhoto ? _photo == null : _text.text.trim().isEmpty) {
      showMessage(context, widget.withPhoto ? 'Scatta o scegli prima una foto' : 'Scrivi prima cosa ti serve');
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = context.read<Repo>();
      final id = widget.withPhoto
          ? await repo.placeFreeOrder(photo: _photo, photoExt: _photoExt, note: _text.text)
          : await repo.placeFreeOrder(body: _text.text);
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Pulsante grande, facile da toccare anche per chi usa poco il telefono.
  Widget _photoButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return FilledButton.tonalIcon(
      onPressed: _busy ? null : onPressed,
      icon: Icon(icon, size: 32),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(76),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.withPhoto ? 'Foto ordine' : 'Scrivi ordine')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (widget.withPhoto) ...[
          if (_photo != null)
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(_photo!, fit: BoxFit.contain))
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Fotografa il foglio con il tuo ordine.', textAlign: TextAlign.center),
            ),
          const SizedBox(height: 12),
          _photoButton(
            icon: Icons.photo_camera,
            label: _photo == null ? 'Scatta foto' : 'Rifai foto',
            onPressed: () => _pick(ImageSource.camera),
          ),
          const SizedBox(height: 12),
          _photoButton(
            icon: Icons.photo_library,
            label: 'Aggiungi foto dalla galleria',
            onPressed: () => _pick(ImageSource.gallery),
          ),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _text,
          autofocus: !widget.withPhoto,
          minLines: widget.withPhoto ? 1 : 8,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: widget.withPhoto ? 'Note per il magazzino (opzionale)' : 'Cosa ti serve?',
            hintText: widget.withPhoto ? null : 'Es.\n2 kg mozzarella\n1 forma pecorino romano\n3 pz olio 1 lt',
            alignLabelWithHint: true,
          ),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _busy ? null : _send,
            icon: _busy
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Invia ordine'),
          ),
        ),
      ),
    );
  }
}
