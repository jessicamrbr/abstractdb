import 'dart:async';

import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/abstractions/types.dart';
import 'package:collql/collql.dart';

class IndexMatchInfo<I>{
  /// The name of the index. It must be unique in the collection.
  String indexName;

  /// The list of document properties that are indexed.
  List<String> documentProperties;

  /// The [Filter] operation that this index react.
  FilterOperation filterOperation;

  /// The filter expression that this index react.
  String filterExpression;

  /// An [List] of all matched position's of items in the memory adapter.
  List<I> itemPointers;

  IndexMatchInfo({
    required this.indexName,
    required this.documentProperties,
    required this.filterOperation,
    required this.filterExpression,
    List<I>? initItemPointers,
  }) : 
    assert(indexName.isNotEmpty, 'Index name cannot be empty'),
    itemPointers = initItemPointers ?? const[];
}

abstract class IndexProvider<I> {
  /// The name of the index. It must be unique in the collection.
  String indexName;

  /// The list of document properties that are indexed.
  List<String> documentProperties;

  /// The [FilterOperation] operation that this index react.
  FilterOperation operation;

  IndexProvider(
    this.indexName,
    this.documentProperties,
    this.operation,
  ) : 
    assert(indexName.isNotEmpty, 'Index name cannot be empty'),
    assert(documentProperties.isNotEmpty, 'Document properties cannot be empty')
  ;

  /// Listen to changes in the collection.
  Future<void> onCollectionEvent(CollectionEvent event);

  IndexMatchInfo<I> createIndexMatchInfo(List<I>? initItemPointers, Filter filter) => IndexMatchInfo(
    indexName: indexName,
    documentProperties: documentProperties,
    filterOperation: operation,
    filterExpression: filter.toString(),
    initItemPointers: initItemPointers,
  );

  /// Receives a leaf [Filter] (exclude logical filter and, or or nor). Returns info 
  /// about match documents ([IndexMatchInfo]) by index implementation.
  Future<IndexMatchInfo<I>> query(Filter leafFilter);

  /// Rebuild the index and save the array indices
  Future<void> build(List<Document> items);

  /// Validate if write operations are valid for this index.
  Future<void> checkIntegrity(DataTransfer dataTransfer) async { }
}