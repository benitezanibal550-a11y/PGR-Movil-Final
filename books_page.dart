import 'package:firebase_auth/firebase_auth.dart';
// Kept for compatibility with the stable Flutter SDK.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

import '../services/book_repository.dart';
import 'book_form_page.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key, required this.user});

  final User user;

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  late final BookRepository _repository = BookRepository(widget.user.uid);
  late final Stream<List<Book>> _books = _repository.watchBooks();

  Future<void> _openForm([Book? book]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookFormPage(repository: _repository, book: book),
      ),
    );
    if (mounted && saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(book == null ? 'Libro creado.' : 'Libro actualizado.'),
        ),
      );
    }
  }

  Future<void> _delete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text('¿Eliminar “${book.title}” de tu colección?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(book.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Libro eliminado.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Biblioteca Personal'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            try {
              await FirebaseAuth.instance.signOut();
            } catch (error) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo cerrar sesión: $error')),
                );
              }
            }
          },
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openForm(),
      icon: const Icon(Icons.add),
      label: const Text('Nuevo libro'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi colección',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Sesión iniciada: ${widget.user.email ?? widget.user.uid}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<Book>>(
                  stream: _books,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'No se pudo leer Firestore: ${snapshot.error}',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final books = snapshot.data!;
                    if (books.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.library_books_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aún no tienes libros',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Pulsa “Nuevo libro” para agregar el primero.',
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: books.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final book = books[index];
                        return _BookCard(
                          book: book,
                          onEdit: () => _openForm(book),
                          onDelete: () => _delete(book),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.onEdit,
    required this.onDelete,
  });

  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              book.imageUrl,
              width: 86,
              height: 112,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                width: 86,
                height: 112,
                child: ColoredBox(
                  color: Color(0xFFE9ECE7),
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('${book.author} · ${book.genre}'),
                if (book.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    book.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
