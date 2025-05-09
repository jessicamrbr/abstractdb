import 'dart:async';
import 'dart:collection';

import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/utils/change_notifier.dart';
import 'package:async/async.dart';
import 'package:collql/collql.dart';
import 'package:initializable/initializable.dart';

/// [I] is the type of ID of the documents in collection.
/// [F] is the type of the item EXPOSED by collection after transformation.
class Cursor<I, F> extends ChangeNotifier with InitializableMixin {
  List<I> positions = [];

  final Future<Document> Function(I position, {Map<String, bool> projection}) _getter;
  final Future<List<I>> Function(Filter? filter) _processQuery;
  final F Function(Document) transformOut;
  final Filter? filter;
  CursorOptions? options;

  Completer<bool> _queried = Completer<bool>();
  StreamQueue<Document>? _activeQueue;
  Future<bool> _iterationCancelled = Future.value(false);

  Cursor(this._getter, this._processQuery, this.transformOut, {
    this.filter,
    this.options,
  }) {
    initialize();
  }

  @override
  Future<void> onInit() async {
    await _query();
  }

  @override
  Future<bool> get isReady async {
    await super.isReady;
    return _queried.future;
  }

  Future<void> _query() async {
    _queried = Completer<bool>();
    positions = await _processQuery(filter);
    _queried.complete(true);
    _onCollectionEventAffectedPositions();
  }

  void onCollectionEvent(CollectionEvent event) async {
    if (event is RemovedInCollection) {
      positions.remove(event.document.id);
      _onCollectionEventAffectedPositions();
      return;
    }

    if (event is ChangedInCollection) {
      if ((filter?.apply(event.document) ?? true)) {
        if (!positions.contains(event.document.id)) {
          positions.add(event.document.id);
          _onCollectionEventAffectedPositions();
          return;
        }
      } else {
        positions.remove(event.document.id);
        _onCollectionEventAffectedPositions();
        return;
      }
    }

    if (event is AddedInCollection) {
      if (filter?.apply(event.document) ?? true) {
        if (!positions.contains(event.document.id)) {
          positions.add(event.document.id);
          _onCollectionEventAffectedPositions();
          return;
        }
      }
    }
  }

  void _onCollectionEventAffectedPositions() {
    _invalidateQueue();
    _cancelIteration();
    notifyListeners();
  }

  void _cancelIteration() {
    _iterationCancelled = Future.value(true);
    _iterationCancelled = Future.value(false);
  }

  Future<List<F>> fetch() async {
    final docs = await map((doc) async => doc);
    List result = _applyPagination(docs.toList());
    return result.map((doc) => transformOut(doc)).toList();
  }

  Future<void> forEach(FutureOr<void> Function(Document item) callback) async {
    final queue = await _getQueue();
    final docs = <Document>[];
    while (await queue.hasNext) {
      if ((await _iterationCancelled) == true) return;
      final doc = await queue.next;
      docs.add(doc);
    }
    final sorted = _applySort(docs);
    final projected = _applyProjection(sorted);
    for (final doc in projected) {
      if ((await _iterationCancelled) == true) return;
      await callback(doc);
    }
  }

  Future<Iterable<U>> map<U>(Future<U> Function(Document item) callback) async {
    final results = <U>[];
    await forEach((doc) async {
      results.add(await callback(doc));
    });
    return results;
  }

  Future<int> count() async {
    await isReady;
    return positions.length;
  }

  Future<void> requery() async {
    await _query();
  }

  Future<StreamQueue<Document>> _getQueue() async {
    await isReady;
    _activeQueue ??= StreamQueue(_streamDocuments());
    return _activeQueue!;
  }

  Stream<Document> _streamDocuments() async* {
    final projectionInstruct = _mergedProjectionAndSortInstruct();
    for (final id in positions) {
      yield await _getter(id, projection: projectionInstruct);
    }
  }

  void _invalidateQueue() {
    _activeQueue?.cancel();
    _activeQueue = null;
  }

  Map<String, bool> _mergedProjectionAndSortInstruct() {
    final all = Map<String, bool>.from(options?.projection ?? {});
    if (all.isEmpty || (options?.sort ?? {}).keys.isEmpty) return all;

    all.addEntries(options!.sort!.entries.map((e) => MapEntry(e.key, true)));
    return all;
  }

  List<Document> _applySort(List<Document> docs) {
    if ((options?.sort ?? {}).keys.isEmpty) return docs;
    final sorted = [...docs];
    sorted.sort((a, b) {
      for (final sortEntry in options!.sort!.entries) {
        final aValue = a.get(sortEntry.key);
        final bValue = b.get(sortEntry.key);
        final cmp = Comparable.compare(aValue, bValue);
        if (cmp != 0) return sortEntry.value == Sort.ascending ? cmp : -cmp;
      }
      return 0;
    });
    return sorted;
  }

  List<Document> _applyProjection(List<Document> docs) {
    if ((options?.projection ?? {}).keys.isEmpty) return docs;
    List<Document> projected = [];
    for (final doc in docs) {
      final projectedDoc = Document({doc.idPath: doc.id});
      for (final entry in options!.projection!.entries) {
        projectedDoc.set(entry.key, doc.get(entry.key));
      }
      projected.add(projectedDoc);
    }
    return projected;
  }

  List<Document> _applyPagination(List<Document> docs) {
    final skip = options?.skip ?? 0;
    final limit = options?.limit;
    final skipped = docs.skip(skip);
    return limit != null ? skipped.take(limit).toList() : skipped.toList();
  }

  @override
  void dispose() {
    _invalidateQueue();
    _cancelIteration();
    super.dispose();
  }
}

class CursorOptions {
  int? skip;
  int? limit;
  LinkedHashMap<String, Sort>? sort;
  Map<String, bool>? projection;

  CursorOptions({
    this.skip,
    this.limit,
    this.sort,
    this.projection,
  });
}

enum Sort {
  ascending,
  descending,
}
