import 'dart:typed_data';

// Kept for compatibility with the stable Flutter SDK.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/book_repository.dart';
import '../services/cloudinary_service.dart';

class BookFormPage extends StatefulWidget {
  const BookFormPage({super.key, required this.repository, this.book});

  final BookRepository repository;
  final Book? book;

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.book?.title ?? '');
  late final _author = TextEditingController(text: widget.book?.author ?? '');
  late final _genre = TextEditingController(text: widget.book?.genre ?? '');
  late final _description = TextEditingController(
    text: widget.book?.description ?? '',
  );
  Uint8List? _imageBytes;
  String? _imageName;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _genre.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      if (!mounted) return;
      final name = picked.name.toLowerCase();
      if (!(name.endsWith('.jpg') ||
          name.endsWith('.jpeg') ||
          name.endsWith('.png') ||
          name.endsWith('.webp'))) {
        setState(() => _error = 'Selecciona una imagen JPG, PNG o WebP.');
        return;
      }
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 10 * 1024 * 1024) {
        setState(() => _error = 'La imagen debe pesar 10 MB o menos.');
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo elegir la imagen: $error');
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null && widget.book == null) {
      setState(() => _error = 'Selecciona una imagen para el libro.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final imageUrl = _imageBytes == null
          ? widget.book!.imageUrl
          : await CloudinaryService().uploadImage(_imageBytes!, _imageName!);
      if (widget.book == null) {
        await widget.repository.create(
          title: _title.text.trim(),
          author: _author.text.trim(),
          genre: _genre.text.trim(),
          description: _description.text.trim(),
          imageUrl: imageUrl,
        );
      } else {
        await widget.repository.update(
          widget.book!.id,
          title: _title.text.trim(),
          author: _author.text.trim(),
          genre: _genre.text.trim(),
          description: _description.text.trim(),
          imageUrl: imageUrl,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = 'No se pudo guardar: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _required(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Este campo es obligatorio.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.book == null ? 'Nuevo libro' : 'Editar libro'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Datos del libro',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _title,
                      maxLength: 120,
                      decoration: const InputDecoration(labelText: 'Título'),
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _author,
                      maxLength: 100,
                      decoration: const InputDecoration(labelText: 'Autor'),
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _genre,
                      maxLength: 60,
                      decoration: const InputDecoration(labelText: 'Género'),
                      validator: _required,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _description,
                      maxLength: 500,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Portada',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    if (_imageBytes != null)
                      Image.memory(
                        _imageBytes!,
                        height: 190,
                        fit: BoxFit.contain,
                      )
                    else if (widget.book != null)
                      Image.network(
                        widget.book!.imageUrl,
                        height: 190,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined, size: 80),
                      )
                    else
                      const SizedBox(
                        height: 120,
                        child: Center(
                          child: Icon(Icons.image_outlined, size: 64),
                        ),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _chooseImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        widget.book == null
                            ? 'Elegir imagen'
                            : 'Cambiar imagen',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar libro'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
