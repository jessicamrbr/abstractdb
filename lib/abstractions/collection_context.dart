import 'package:abstractdb/abstractdb.dart';
import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/abstractions/index_provider.dart';
import 'package:abstractdb/implementations/cursor.dart';

import '../utils/types.dart';

/// [I] is the type of ID of the documents in collection.
/// [E] is the type of the item EXPOSED by collection after transformation.
typedef CollectionContext<I, E> = ({
  CollectionName getName,
  CollectionIdexes<I> getIndexes,
  CollectionFind<I, E> find,
  CollectionSave<E> save,
  CollectionUpdate update,
  CollectionUpdateAll updateAll,
  CollectionRemove remove,
  CollectionClear clear,
  CollectionBatch batch,
  CollectionEmitEvent emitEvent,
});

typedef CollectionName = String Function();
typedef CollectionIdexes<I> = List<IndexProvider<I>> Function();
typedef CollectionFind<I, E> = Future<Cursor<I, E>> Function(Filter? filter, { CursorOptions? options });
typedef CollectionSave<E> = Future<E> Function(E item, { String? sourceRequestId });
typedef CollectionUpdate = Future<int> Function(Filter filter, List<Modifier> modifier, { String? sourceRequestId });
typedef CollectionUpdateAll = Future<int> Function(List<Modifier> modifier, { String? sourceRequestId });
typedef CollectionRemove = Future<void> Function(Filter filter, { String? sourceRequestId });
typedef CollectionClear = Future<void> Function({ String? sourceRequestId });
typedef CollectionBatch = void Function(VoidCallback fn);
typedef CollectionEmitEvent = void Function(CollectionEvent event, { String? sourceRequestId });