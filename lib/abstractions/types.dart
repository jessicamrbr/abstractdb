import 'package:collql/collql.dart';

typedef Changeset = ({
  List<Document> added,
  List<Document> modified,
  List<Document> removed,
});

class DataTransfer {
  /// Either info to replacing all of its items beetween adapters, 
  /// or applying the [Changeset] to make differential changes, respectively
  List<Document>? items;

  /// Either info to replacing all of its items beetween adapters, 
  /// or applying the [Changeset] to make differential changes, respectively
  Changeset? changes;

  DataTransfer({
    this.items,
    this.changes,
  }) : assert(items != null || changes!= null, 'Either items or changes must be provided');

  DataTransfer.emptyForChanges()
      : items = null,
        changes = (
          added: [],
          modified: [],
          removed: [],
        );
}

enum SyncStatus {
  /// The local queue is empty or not has items with status != "synced" on window sync time, process not need.
  synced,
  /// The sync process is in progress.
  syncing,
  /// The local queue is not empty and has items with status != "synced", but the sync process is not in progress.
  unsynced,
  /// The local queue has item with conflict status.
  conflict,
  /// The local queue has item with fail status.
  fail,
  /// The sync loop is paused.
  paused,
}