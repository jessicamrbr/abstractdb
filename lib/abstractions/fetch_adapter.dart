import 'package:abstractdb/abstractions/abstractdb_adapter.dart';
import 'package:abstractdb/abstractions/collection_context.dart';
import 'package:collql/collql.dart';

///
/// [I] is the type of ID of the documents in collection.
abstract class FetchAdapter<I, E> extends AbstractdbAdapter<I, E> {
  @override
  String get adapterId => 'Fetch${super.adapterId}';

  /// Specifie the cache duration's, the time after which the data will be
  /// purged from the cache after the query is not used anymore.
  Duration? purgeDelay;
  
  FetchAdapter(super.context, {
    this.purgeDelay = const Duration(seconds: 10),
  });

  /// 
  Future<void> load(List<Document> data);

  /// 
  Future<Document?> get(I position, { Map<String, bool>? projection });

  /// 
  Future<Document> optimisticGet(I position, { Map<String, bool>? projection });

  /// Fetching data from the service.
  /// 
  /// The [Filter] parameter is the query that is executed on the collection.
  /// Use this to fetch only the data that is needed for the query.
  /// Also make sure that the returned data matches the query to avoid inconsistencies  
  Future<List<I>> processQuery(Filter? filter);
}

typedef FetchAdapterFactory<I, E> = FetchAdapter<I, E> Function(CollectionContext<I, E>);