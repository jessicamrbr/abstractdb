import 'package:abstractdb/abstractions/abstractdb_adapter.dart';
import 'package:abstractdb/abstractions/collection_context.dart';
import 'package:abstractdb/abstractions/types.dart';
import 'package:initializable/initializable.dart';

///
/// [I] is the type of ID of the documents in collection.
abstract class SyncAdapter<I> extends AbstractdbAdapter with InitializableMixin {
  final String? _adapterId;
  @override
  String get adapterId => _adapterId ?? 'Sync${super.adapterId}';

  /// The path in document where version control ID is stored.
  final String versionIdPath;

  /// The path in document where version control ID is stored.
  final String updatedAtPath;

  SyncAdapter(super.context, {
    String? adapterId,
    this.versionIdPath = '/meta/versionId',
    this.updatedAtPath = '/meta/lastUpdated',
  }) : _adapterId = adapterId {
    initialize();
  }
  
  /// Initialize the sync adapter
  @override
  Future<void> onInit() async { }

  /// Checks if adapter is ready.
  /// @mustcallsuper
  @override
  Future<bool> get isReady => super.isReady;

  /// The sync status of the adapter.
  SyncStatus status = SyncStatus.unsynced;

  /// Allows the adapter to initiate and manage new synchronization processes.
  void resume() => status = SyncStatus.unsynced;

  /// Prevents the initiation of new synchronization processes for the adapter.
  void pause() => status = SyncStatus.paused;

  /// This method should be called when the sync adapter is no longer needed
  /// or collection is disposed.
  Future<void> dispose();
}

typedef SyncAdapterFactory<I, E> = SyncAdapter<I> Function(CollectionContext<I, E>);