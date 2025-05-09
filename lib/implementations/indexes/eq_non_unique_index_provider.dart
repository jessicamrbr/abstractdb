import 'dart:collection';

import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/abstractions/index_provider.dart';
import 'package:abstractdb/implementations/filters/filter_operation.dart';
import 'package:collql/collql.dart' hide FilterOperation;

/// [I] is the type of ID of the documents in collection.
class NonUniqueEqualityIndex<I> extends IndexProvider<I> {
  final LinkedHashMap<dynamic, Set<I>> _valueToIds = LinkedHashMap.from({});

  NonUniqueEqualityIndex(String indexName, List<String> documentProperties)
    :
      assert(documentProperties.length == 1, 'EqualsIndexProvider requires exactly one property'),
      super(indexName, documentProperties, FilterOperation.eq)
    ;

  @override
  Future<void> build(List<Document> items) async {
    _valueToIds.clear();
    final field = documentProperties.first;

    for (var item in items) {
      final value = item[field];
      if (value == null) continue;

      _valueToIds.putIfAbsent(value, () => <I>{});
      _valueToIds[value]!.add(item.id);
    }
  }

  @override
  Future<void> onCollectionEvent(CollectionEvent event) async {
    final field = documentProperties.first;

    if (event is RemovedInCollection) {
      final value = event.document[field];
      _valueToIds[value]?.remove(event.document.id);
      if (_valueToIds[value]?.isEmpty ?? false) {
        _valueToIds.remove(value);
      }
    }

    if (event is AddedInCollection) {
      final value = event.document[field];
      if (value == null) return;

      _valueToIds.putIfAbsent(value, () => <I>{});
      _valueToIds[value]!.add(event.document.id);
    }

    if (event is ChangedInCollection) {
      final value = event.document[field];
      if (value == null) return;

      _valueToIds.forEach((key, ids) => ids.remove(event.document.id));
      _valueToIds.removeWhere((key, ids) => ids.isEmpty);

      _valueToIds.putIfAbsent(value, () => <I>{});
      _valueToIds[value]!.add(event.document.id);
    }
  }

  @override
  Future<IndexMatchInfo<I>> query(Filter leafFilter) async {
    leafFilter = leafFilter as FieldBasedFilter;

    final value = leafFilter.value;
    final Set<I>? ids = _valueToIds[value];

    return createIndexMatchInfo(ids?.toList() ?? [], leafFilter);
  }
}
