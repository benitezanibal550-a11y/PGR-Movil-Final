import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String author;
  final String genre;
  final String description;
  final String imageUrl;

  factory Book.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Book(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      author: data['author']?.toString() ?? '',
      genre: data['genre']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
    );
  }
}

class BookRepository {
  BookRepository(this.uid);

  final String uid;

  CollectionReference<Map<String, dynamic>> get _books => FirebaseFirestore
      .instance
      .collection('users')
      .doc(uid)
      .collection('books');

  Stream<List<Book>> watchBooks() => _books.snapshots().map((snapshot) {
    final books = snapshot.docs.map(Book.fromDocument).toList();
    books.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return books;
  });

  Future<void> create({
    required String title,
    required String author,
    required String genre,
    required String description,
    required String imageUrl,
  }) async {
    await _books.add({
      'ownerUid': uid,
      'title': title,
      'author': author,
      'genre': genre,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(
    String id, {
    required String title,
    required String author,
    required String genre,
    required String description,
    required String imageUrl,
  }) => _books.doc(id).update({
    'title': title,
    'author': author,
    'genre': genre,
    'description': description,
    'imageUrl': imageUrl,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> delete(String id) => _books.doc(id).delete();
}
