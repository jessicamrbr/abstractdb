import 'dart:async';

import 'package:abstractdb/abstractions/abstractdb_adapter.dart';
import 'package:abstractdb/abstractions/collection_context.dart';
import 'package:abstractdb/abstractions/types.dart';
import 'package:initializable/initializable.dart';

///
/// [I] is the type of ID of the documents in collection.
abstract class PersistenceAdapter<I, E> extends AbstractdbAdapter<I, E> with InitializableMixin {
  @override
  String get adapterId => 'Persistence${super.adapterId}';

  /// Notifies the collection using the adapter that there has been an external change to the persisted data.
  FutureOr<void> Function(DataTransfer data) onChangeData = (_) => {};

  PersistenceAdapter(super.context);

  /// Is called to load data from the adapter and should return a [DataTransfer]. 
  /// 
  /// The collection will update its internal memory.
  Future<DataTransfer> load();

  /// Is called when data was updated, and should save the data.
  /// 
  /// Both items and changes are provided so you can chose which one you'd like to use.
  Future<void> save(DataTransfer data);

  /// Is called when the dispose method of the collection is called.
  /// 
  /// Allows you to clean up things.
  Future<void>? onDispose();
}

typedef PersistenceAdapterFactory<I, E> = PersistenceAdapter<I, E> Function(CollectionContext<I, E>);