import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/abstractions/fetch_adapter.dart';
import 'package:abstractdb/abstractions/index_provider.dart';
import 'package:collql/collql.dart';

///
/// [I] is the type of ID of the documents in collection.
class MemoryFetchAdapter<I, E> extends FetchAdapter<I, E> {
  ///
  Map<int, IndexMatchInfo> memo = {};

  /// @nodoc
  final Map<I, Document> _store;

  MemoryFetchAdapter(super.context, {
    Map<I, Document>? store, 
    super.purgeDelay = null,
  }) : _store = store ?? <I, Document>{};


  @override
  Future<void> onCollectionEvent(CollectionEvent event) async {
    if (event is RemovedInCollection) {
      _store.remove(event.document.id);
    }

    if (event is ChangedInCollection) {
      _store[event.document.id] = event.document;
    }
    
    if (event is AddedInCollection) {
      _store[event.document.id] = event.document;
    }
  }

  /// @nodoc
  @override
  Future<void> load(List<Document> data) async {
    for (final item in data) { _store[item.id] = item; }   
  }

  /// @nodoc
  @override
  Future<Document?> get(I id, { Map<String, bool>? projection }) async => _store[id];

  /// @nodoc
  @override
  Future<Document> optimisticGet(I id, { Map<String, bool>? projection }) async => _store[id]!;

  /// @nodoc
  @override
  Future<List<I>> processQuery(
    Filter? filter
  ) async {
    if (filter == null) return _store.keys.toList();

    int leafIdentity = filter.toString().hashCode;

    if (memo.containsKey(leafIdentity)) return memo[leafIdentity]!.itemPointers as List<I>;

    if (filter.name == FilterOperation.and.name) {
      Set<I> intersectionSet = Set<I>.from(
        List<I>.generate(_store.keys.length, (i) => _store.keys.elementAt(i))
      );
      
      memo[leafIdentity] = IndexMatchInfo(
        indexName: leafIdentity.toString(),
        documentProperties: [],
        filterOperation: FilterOperation.and,
        filterExpression: filter.toString(),
        initItemPointers: null,
      );

      // TODO: implement composite index
      for (Filter childFilter in (filter as LogicalFilter).filters) {
        List<I> childResult = await processQuery(childFilter);
        // Short circuitins strategy on AND flow      
        if (childResult.isEmpty) { 
          memo[leafIdentity]!.itemPointers = childResult;
          return childResult;
        }
        intersectionSet = intersectionSet.intersection(childResult.toSet());
        if (intersectionSet.isEmpty) { 
          memo[leafIdentity]!.itemPointers = intersectionSet.toList();
          return intersectionSet.toList();
        }
      }
      
      return intersectionSet.toList();
    } else if (filter.name == FilterOperation.or.name) {
      Set<I> unionSet = {};
 
      memo[leafIdentity] = IndexMatchInfo(
        indexName: leafIdentity.toString(),
        documentProperties: [],
        filterOperation: FilterOperation.or,
        filterExpression: filter.toString(),
        initItemPointers: null,
      );
 
      for (Filter childFilter in (filter as LogicalFilter).filters) {
        List<I> childResult = await processQuery(childFilter);
        // Short circuitins strategy on OR flow  
        if (childResult.length == _store.keys.length) {
          memo[leafIdentity]!.itemPointers = childResult;
          return childResult;
        }
        unionSet.addAll(childResult);
        if (unionSet.length == _store.keys.length) { 
          memo[leafIdentity]!.itemPointers = unionSet.toList();
          return unionSet.toList();
        }
      }

      return unionSet.toList();
    } else if (filter.name == FilterOperation.not.name) {
      Set<I> differenceSet = Set<I>.from(
        List<I>.generate(_store.keys.length, (i) => _store.keys.elementAt(i))
      );
      List<I> childResult = await processQuery((filter as NotFilter).filter);
      differenceSet = differenceSet.difference(childResult.toSet());
      memo[leafIdentity] = IndexMatchInfo(
        indexName: leafIdentity.toString(),
        documentProperties: [],
        filterOperation: FilterOperation.not,
        filterExpression: filter.toString(),
        initItemPointers: differenceSet.toList(),
      );
      return differenceSet.toList();
    } else if (filter is FieldBasedFilter) {
      IndexProvider? useThisIndex = context.getIndexes().where(
        (i) => i.operation.name == filter.name
        && i.documentProperties.contains(filter.field)
      ).firstOrNull;

      return (useThisIndex != null) 
        ? (memo[leafIdentity] = await useThisIndex.query(filter)).itemPointers as List<I>
        : _store.values.where((d) => filter.apply(d)).map((d) => d.id as I).toList()
      ;
    } else {
      throw Exception('Filter type not supported: ${filter.runtimeType}');
    }
  }
}