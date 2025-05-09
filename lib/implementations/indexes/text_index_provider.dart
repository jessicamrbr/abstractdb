import 'dart:collection';

import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/abstractions/index_provider.dart';
import 'package:abstractdb/implementations/filters/filter_operation.dart';
import 'package:collql/collql.dart' hide FilterOperation;
import 'package:fuzzy/fuzzy.dart';

/// [I] is the type of ID of the documents in collection.
class TextIndexProvider<I> extends IndexProvider<I> {
  final LinkedHashMap<I, String> _sourceValues = LinkedHashMap.from({});
  late Fuzzy _fuse;

  TextIndexProvider(String indexName, List<String> documentProperties) 
    : 
      assert(documentProperties.length == 1, 'Text index only supports/require one document property'),
      super(indexName, documentProperties, FilterOperation.text)
    {
      _rebuildFuse();
    }

  void _rebuildFuse() {
    _fuse = Fuzzy(
      _sourceValues.values.toList(),
      options: FuzzyOptions(findAllMatches: true),
    );
  }

  @override
  Future<void> build(List<Document> items) async {
    _sourceValues.clear();
    for (var item in items) {
      final value = item[documentProperties.first];
      if (value is String) {
        _sourceValues[item.id] = value;
      }
    }
    _rebuildFuse();
  }

  @override
  Future<void> onCollectionEvent(CollectionEvent event) async {
    if (event is RemovedInCollection) {
      _sourceValues.remove(event.document.id);
    }

    if (event is ChangedInCollection) {
      final value = event.document[documentProperties.first];
      if (value is String) {
        _sourceValues[event.document.id] = value;
      }
    }
    
    if (event is AddedInCollection) {
      final value = event.document[documentProperties.first];
      if (value is String) {
        _sourceValues[event.document.id] = value;
      }
    }

    _rebuildFuse();
  }

  @override
  Future<IndexMatchInfo<I>> query(Filter leafFilter) async {
    leafFilter = leafFilter as FieldBasedFilter;
    final result = _fuse.search(leafFilter.value);
    return createIndexMatchInfo(result.map<I>((r) => _sourceValues.entries.elementAt(r.matches.first.arrayIndex).key).toList(), leafFilter);
  }
}