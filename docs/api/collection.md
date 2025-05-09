---
label: Collection API
icon: code
order: 60
---

# Collection API Reference

## Constructor

### Collection<I, E>

```dart
Collection<I, E>({
  required String name,
  List<IndexProvider<I>> indexes = const[],
  PersistenceAdapterFactory<I>? persistence,
  SyncAdapterFactory<I>? synchronizer,
  List<ReactivityAdapter> reactivities = const[],
  Document Function(E)? transformIn,
  E Function(Document)? transformOut,
  FetchAdapterFactory<I>? finder,
})
```

## Properties

| Name | Type | Description |
|------|------|-------------|
| name | String | Collection identifier |
| indexes | List<IndexProvider<I>> | List of index providers |
| reactivities | List<ReactivityAdapter> | List of reactivity adapters |

## Methods

### save

```dart
Future<void> save(Document document)
```

Saves a document to the collection.

### find

```dart
Cursor<E> find(Filter filter)
```

Creates a cursor for querying documents.

### remove

```dart
Future<void> remove(I id)
```

Removes a document by ID.