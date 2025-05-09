import 'dart:collection';

import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/abstractions/index_provider.dart';
import 'package:abstractdb/abstractions/types.dart';
import 'package:abstractdb/implementations/filters/filter_operation.dart';
import 'package:collql/collql.dart' hide FilterOperation;

/// [I] is the type of ID of the documents in collection.
class UniqueEqualityIndex<I> extends IndexProvider<I> {
  final LinkedHashMap<dynamic, I> _valueToId = LinkedHashMap.from({});

  UniqueEqualityIndex(String indexName, List<String> documentProperties)
    : 
      assert(documentProperties.length == 1, 'UniqueEqualityIndex requires exactly one property'),
      super(indexName, documentProperties, FilterOperation.eq)
    ;

  @override
  Future<void> build(List<Document> items) async {
    _valueToId.clear();
    for (var item in items) {
      final value = item[documentProperties.first];
      if (value == null) continue;
      if (_valueToId.containsKey(value)) {
        throw Exception('''Unique value equality index violation for "$indexName". 
          Duplicate value "$value" in Document "${item.id}", already exists in Document "${_valueToId[value]}".''');
      }
      _valueToId[value] = item.id;
    }
  }

  @override
  Future<void> onCollectionEvent(CollectionEvent event) async {
    final field = documentProperties.first;

    if (event is RemovedInCollection) {
      final value = event.document[field];
      _valueToId.remove(value);
    }

    if (event is AddedInCollection) {
      final item = event.document;
      final value = item[field];

      if (value == null) return;
      if (_valueToId.containsKey(value)) {
        throw Exception('''Unique value equality index violation for "$indexName". 
          Duplicate value "$value" in Document "${item.id}", already exists in Document "${_valueToId[value]}".''');
      }
      
      _valueToId[value] = item.id;
    }

    if (event is ChangedInCollection) {
      final item = event.document;
      final value = item[field];

      if (value == null) return;
      if (_valueToId.containsKey(value) && _valueToId[value] != item.id) {
        throw Exception('''Unique value equality index violation for "$indexName". 
          Duplicate value "$value" in Document "${item.id}", already exists in Document "${_valueToId[value]}".''');
      }
      
      _valueToId[value] = item.id;
    }
  }

  @override
  Future<IndexMatchInfo<I>> query(Filter leafFilter) async {
    leafFilter = leafFilter as FieldBasedFilter;

    final value = leafFilter.value;
    final id = _valueToId[value];

    final List<I> matches = id != null ? [id] : [];
    return createIndexMatchInfo(matches, leafFilter);
  }

  @override
  Future<void> checkIntegrity(DataTransfer dataTransfer) async {
    final field = documentProperties.first;

    for (final item in dataTransfer.changes?.added ?? <Document>[]) {
      final value = item[field];

      if (value == null) return;
      if (_valueToId.containsKey(value)) {
        throw Exception('''Unique value equality index violation for "$indexName". 
          Duplicate value "$value" in Document "${item.id}", already exists in Document "${_valueToId[value]}".''');
      }
    }

    for (final item in dataTransfer.changes?.modified ?? <Document>[]) {
      final value = item[field];

      if (value == null) return;
      if (_valueToId.containsKey(value) && _valueToId[value] != item.id) {
        throw Exception('''Unique value equality index violation for "$indexName". 
          Duplicate value "$value" in Document "${item.id}", already exists in Document "${_valueToId[value]}".''');
      }
    }
  }
}
