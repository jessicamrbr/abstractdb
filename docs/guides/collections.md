---
label: Collections
icon: database
order: 90
---

# Working with Collections

Collections are the primary way to store and manage data in AbstractDB.

## Creating Collections

### Basic Collection

```dart
final posts = Collection<dynamic, dynamic>(name: 'posts');
```

### Typed Collection

```dart
class Post implements DocumentData {
  final String title;
  final String content;
  
  Post({required this.title, required this.content});
  
  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
  };
}

final posts = Collection<StringDocumentId, Post>(name: 'posts');
```

## Querying

### Basic Queries

```dart
// Find by exact match
final cursor = posts.find('title'.equals('Hello World'));

// Regular expression
final cursor = posts.find('title'.regex('Hello.*'));

// Complex queries
final cursor = posts.find(
  'title'.equals('Hello World').and('author'.exists())
);
```

### Using Cursors

```dart
// Fetch all documents
final docs = await cursor.fetch();

// Iterate over documents
await cursor.forEach((doc) {
  print(doc['title']);
});

// Count documents
final count = await cursor.count();
```

## Persistence

Enable persistent storage using Hive:

```dart
final posts = Collection<StringDocumentId, Post>(
  name: 'posts',
  persistence: (context) => HivePersistence(
    context,
    hivePath: './data',
  ),
);
```