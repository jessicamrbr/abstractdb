---
label: Introduction
icon: home
order: 100
---

# AbstractDB

AbstractDB is a local-first database abstraction solution for Dart applications with the following features:

- **Schemaless**: Flexible document storage without rigid schemas
- **Persistence**: Multiple storage backends support
- **Reactive**: Real-time data updates
- **Synchronization**: Built-in sync capabilities

## Installation

Add AbstractDB to your `pubspec.yaml`:

```yaml
dependencies:
  abstractdb: ^1.0.0
```

## Quick Start

```dart
// Create a collection
final posts = Collection<dynamic, dynamic>(name: 'posts');

// Wait for initialization
await posts.isReady;

// Save some documents
await posts.save(Document({"id": "1", "title": "Hello World"}));

// Query documents
final cursor = await posts.find('title'.equals('Hello World'));
final docs = await cursor.fetch();
```

## Features

### Local-First

AbstractDB prioritizes local data storage and operations, ensuring your application works offline while providing synchronization capabilities when needed.

### Type Safety

Utilize Dart's type system with generic collections:

```dart
// Typed collection
final posts = Collection<StringDocumentId, PostData>(name: 'posts');
```

### Flexible Storage

Choose from multiple storage backends:

- In-memory (default)
- Hive
- Custom storage adapters