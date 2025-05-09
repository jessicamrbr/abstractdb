---
label: Reactivity
icon: sync
order: 80
---

# Reactivity

AbstractDB supports reactive data updates through various adapters.

## Using Signals

```dart
final posts = Collection<StringDocumentId, Post>(
  name: 'posts',
  reactivities: [SignalReactivity()],
);

// Get reactive cursor
final cursor = posts.find('author'.equals('John'));
final signal = cursor.asSignal();

// React to changes
signal.listen((docs) {
  print('Documents updated: ${docs.length}');
});
```

## Change Events

Collections emit events when data changes:

```dart
posts.on<CollectionChangeEvent>().listen((event) {
  print('Added: ${event.added.length}');
  print('Modified: ${event.modified.length}');
  print('Removed: ${event.removed.length}');
});
```