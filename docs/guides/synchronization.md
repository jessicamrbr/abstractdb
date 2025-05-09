---
label: Synchronization
icon: repo-sync
order: 70
---

# Synchronization

AbstractDB supports data synchronization through various adapters.

## Supabase Integration

```dart
final posts = Collection<StringDocumentId, Post>(
  name: 'posts',
  synchronizer: (context) => SupabasePgmqSync(
    context,
    supabaseUrl: 'YOUR_SUPABASE_URL',
    supabaseKey: 'YOUR_SUPABASE_KEY',
  ),
);
```

## Custom Sync Adapters

Implement your own sync adapter by extending `SyncAdapter`:

```dart
class CustomSync extends SyncAdapter {
  @override
  Future<void> initialize() async {
    // Setup sync
  }
  
  @override
  Future<void> sync() async {
    // Perform sync
  }
}
```