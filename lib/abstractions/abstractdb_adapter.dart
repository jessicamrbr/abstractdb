import 'package:abstractdb/abstractions/collection_context.dart';
import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:xid/xid.dart';

/// [I] is the type of ID of the documents in collection.
/// [E] is the type of the item EXPOSED by collection after transformation.]
abstract class AbstractdbAdapter<I, E> {
  /// A unique identifier for the adapter.
  /// 
  /// Is useful for debugging and last change origin tracker.
  final String adapterId = 'Adapter-${Xid()}';

  /// The context of the collection.
  ///
  /// This is used to access the collection and its methods.
  final CollectionContext<I, E> context;

  /// Listen to changes in the collection.
  Future<void> onCollectionEvent(CollectionEvent event);

  AbstractdbAdapter(this.context);
}

typedef AbstractdbAdapterFactory<I, E> = AbstractdbAdapter Function(CollectionContext<I, E>);