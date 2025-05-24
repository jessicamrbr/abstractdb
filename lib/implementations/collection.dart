import 'dart:async';

import 'package:abstractdb/abstractions/collection_context.dart';
import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/abstractions/fetch_adapter.dart';
import 'package:abstractdb/abstractions/index_provider.dart';
import 'package:abstractdb/abstractions/persistence_adapter.dart';
import 'package:abstractdb/abstractions/reactivity_adapter.dart';
import 'package:abstractdb/abstractions/sync_adapter.dart';
import 'package:abstractdb/abstractions/types.dart';
import 'package:abstractdb/implementations/cursor.dart';
import 'package:abstractdb/implementations/fetchs/memory_fetch_adapter.dart';
import 'package:abstractdb/utils/types.dart';
import 'package:collql/collql.dart';
import 'package:initializable/initializable.dart';

/// [I] is the type of ID of the documents in collection.
/// [E] is the type of the item EXPOSED by collection after transformation.
class Collection<I, E> with InitializableMixin {
  /// The Collection's name for identification in adapters.
  final String name;

  /// A [FetchAdapter] for manager items and query engine, default is [MemoryFetchAdapter] manager itens in memory.
  late final FetchAdapter<I, E> _finder;

  /// An [IndexProvider] objects for creating indices on the collection.
  final List<IndexProvider<I>> indexes;

  /// A [PersistenceAdapter] for enabling persistent storage.
  late final PersistenceAdapter? _persistence;

  /// A [SyncAdapter] for enabling synchronization.
  late final SyncAdapter? _synchronizer;

  /// A [ReactivityAdapter] for enabling reactivity.
  final List<ReactivityAdapter> reactivities;

  /// A transformation function to be applied to items.
  /// 
  /// The document that should be transformed is passed as the only parameter. 
  /// The function should return the transformed document.
  late final Document Function(E) _transformIn;
  late final E Function(Document) _transformOut;

  /// Factory for creating a collection with specified documents, and especified id type.
  /// 
  /// [I] is the type of ID of the documents in collection.
  /// [E] is the type of the item EXPOSED by collection after transformation.
  static Collection<I, E> typed<I, E>({
    required String name,
    required Document Function(E) transformIn,
    required E Function(Document) transformOut,
    List<IndexProvider<I>> indexes = const[],
    PersistenceAdapterFactory<I, E>? persistence,
    SyncAdapterFactory<I, E>? synchronizer,
    List<ReactivityAdapter> reactivities = const[],
    FetchAdapterFactory<I, E>? finder,
  }) => Collection<I, E>._internal(
    name: name,
    transformIn: transformIn,
    transformOut: transformOut,
    indexes: indexes,
    persistence: persistence,
    synchronizer: synchronizer,
    reactivities: reactivities,
    finder: finder,
  );

  /// Factory for creating a collection with JSON documents, and custom id type.
  /// 
  /// [I] is the type of ID of the documents in collection.
  static Collection<I, Map<String, dynamic>> json<I>({
    required String name,
    List<IndexProvider<I>> indexes = const[],
    PersistenceAdapterFactory<I, Map<String, dynamic>>? persistence,
    SyncAdapterFactory<I, Map<String, dynamic>>? synchronizer,
    List<ReactivityAdapter> reactivities = const[],
    FetchAdapterFactory<I, Map<String, dynamic>>? finder,
  }) => Collection<I, Map<String, dynamic>>._internal(
    name: name,
    indexes: indexes,
    persistence: persistence,
    synchronizer: synchronizer,
    reactivities: reactivities,
    finder: finder,
    transformIn: (obj) => Document(obj),
    transformOut: (obj) => obj.toJsonMap(),
  );

  /// Factory for creating a collection with JSON documents, and custom id type.
  static Collection<String, Map<String, dynamic>> basic({
    required String name,
    List<IndexProvider<String>> indexes = const[],
    PersistenceAdapterFactory<String, Map<String, dynamic>>? persistence,
    SyncAdapterFactory<String, Map<String, dynamic>>? synchronizer,
    List<ReactivityAdapter> reactivities = const[],
    FetchAdapterFactory<String, Map<String, dynamic>>? finder,
  }) => Collection<String, Map<String, dynamic>>._internal(
    name: name,
    indexes: indexes,
    persistence: persistence,
    synchronizer: synchronizer,
    reactivities: reactivities,
    finder: finder,
    transformIn: (obj) => Document(obj),
    transformOut: (obj) => obj.toJsonMap(),
  );

  /// @nodoc
  Collection._internal({
    required this.name,
    this.indexes = const[],
    PersistenceAdapterFactory<I, E>? persistence,
    SyncAdapterFactory<I, E>? synchronizer,
    this.reactivities = const[],
    FetchAdapterFactory<I, E>? finder,
    Document Function(E)? transformIn,
    E Function(Document)? transformOut,
  }){
    final context = contextFactory();
    _finder = (finder != null) ? finder(context) : MemoryFetchAdapter<I, E>(context);
    _persistence = (persistence != null) ? persistence(context) : null;
    _synchronizer = (synchronizer != null) ? synchronizer(context) : null;
    this._transformIn = transformIn ?? (obj) => obj as Document;
    this._transformOut = transformOut ?? (obj) => obj as E;
    initialize();
  }

  /// @nodoc
  static final Map<String, Collection> _collections = {};

  /// @nodoc
  static bool _debugModeActive = false;

  /// @nodoc
  static void Function(Collection collection) _onCreation = (Collection collection) {};

  /// @nodoc
  static void Function(Collection collection) _onDispose = (Collection collection) {};

  /// Enables or disables field tracking for all collections. 
  /// See Field-Level Reactivity for more information.
  // static void setFieldTracking(bool enable) { }

  /// If you need to execute many operations at once in multiple collections, 
  /// you can use the global Collection.batch() method. This method will execute 
  /// all operations inside the callback without rebuilding the indexs, affecting 
  /// the reactivity, persisting the changes, or triggering the events on every change.
  static void batchCollections(VoidCallback fn, List<String> collectionsNames) {
    bool matchACollection = false; 
    void Function(VoidCallback)? chainBatchs;

    _collections.forEach((name, collection) {
      if (collectionsNames.contains(name)) {
        matchACollection = true;
        chainBatchs = (chainBatchs == null)
          ? (inputFn) => collection.batch(inputFn)
          : (inputFn) => chainBatchs!(() => collection.batch(inputFn))  
        ;
      }
    });

    if (!matchACollection) return;
    chainBatchs!(fn);
  }

  /// Returns an array of all collections that have been created.
  static List<Collection> get collections => _collections.values.toList();

  /// Registers a callback that will be called whenever a new collection is created. 
  /// The callback will receive the newly created collection as an argument.
  static set onCreation(void Function(Collection collection) fn) => _onCreation = fn;

  /// Registers a callback that will be called whenever a new collection is created. 
  /// The callback will receive the newly created collection as an argument.
  static set onDispose(void Function(Collection collection) fn) => _onDispose = fn;

  /// Enables debug mode for all collections. This will enable measurements 
  /// for query timings and other debug information.
  static void toggleDebugMode() { _debugModeActive = !_debugModeActive; }

  /// @nodoc
  final _eventController = StreamController<CollectionEvent>.broadcast();

  /// @nodoc
  final Map<VoidCallback, StreamSubscription> _listeners = {};

  /// @nodoc
  @override
  Future<void> onInit() async {
    await _loadFromPersistence();
    _activateListenersOnComponents();
  }

  /// @nodoc
  @override
  Future<void> onReady() async {
    Collection._collections[name] = this;
    Collection._onCreation(this);
  }

  /// Resolves when the adapters finished initializing and the collection is ready to be used. 
  /// 
  /// This is useful when you need to wait for the collection to be ready before executing any 
  /// operations directly after creating it.
  @override
  // ignore: unnecessary_overrides
  Future<bool> get isReady => super.isReady;

  /// Returns a [Cursor] object for the items in the collection that match a given [Filter] and [Options]. 
  Future<Cursor<I, E>> find(Filter? filter, { CursorOptions? options }) async {
    final cursor = _find<E>(
      filter,
      this._transformOut,
      options: options,
    );
    return cursor;
  }

  Future<Cursor<I, F>> _find<F>(Filter? filter, F Function(Document) transformOut, { CursorOptions? options }) async {
    final cursor = Cursor<I, F>(
      _finder.optimisticGet,
      _finder.processQuery,
      transformOut,
      filter: filter,
      options: options,
    );
    return cursor;
  }

  /// Returns a [Cursor] object for all items in the collection.
  Future<Cursor<I, E>> findAll({ CursorOptions? options }) async => find(null, options: options);

  /// Insert/Replace an item into the collection and returns the result [Document].
  /// 
  /// With ID of the newly inserted item, when without one in source [Document].
  Future<E> save(E data, { String? sourceRequestId }) async {
    final Document item = _transformIn(data);
    
    if (item.id == null) item.generateId();
    Document? itemBefore = await _finder.get(item.id!);
    final dataTransfer = DataTransfer.emptyForChanges();
    if (itemBefore == null) {
      dataTransfer.changes!.added.add(item);
    } else {
      dataTransfer.changes!.modified.add(item);
    }

    if (_persistence != null) {
      for (final index in indexes) {
        await index.checkIntegrity(dataTransfer);
      }
      await _persistence.save(dataTransfer);
    }

    final saveEvent = SaveOnCollection(item, sourceRequestId: sourceRequestId);
    late final WriteInCollection addOrChangeEvent;
    emitEvent(saveEvent);
    if (itemBefore == null) {
      addOrChangeEvent = AddedInCollection(item, sourceRequestId: sourceRequestId);
      emitEvent(addOrChangeEvent);
    } else {
      addOrChangeEvent = ChangedInCollection(itemBefore, item, null, sourceRequestId: sourceRequestId);
      emitEvent(addOrChangeEvent);
    }

    await Future.wait([
      saveEvent.ack.future,
      addOrChangeEvent.ack.future,
    ]);

    return _transformOut(item);
  }

  /// Updates multiple items in the collection that match a given [Filter] with the specified [Modifier]s.
  Future<int> update(Filter filter, List<Modifier> modifier, { String? sourceRequestId }) async {
    throw UnimplementedError('update() has not been implemented.');
  }

  /// Updates all items in the collection with the specified [Modifier]s.
  Future<int> updateAll(List<Modifier> modifier, { String? sourceRequestId }) async {
    throw UnimplementedError('updateAll() has not been implemented.');
  }

  /// Removes multiple items from the collection that match a given [Filter].
  Future<void> remove(Filter filter, { String? sourceRequestId }) async {
    final cursor = await _find(filter, (d) => d);
    final docs = await cursor.fetch();

    final dataTransfer = DataTransfer.emptyForChanges();
    for (final doc in docs) { dataTransfer.changes!.removed.add(doc); }    
    if (_persistence != null) { await _persistence.save(dataTransfer); }


    for (final doc in docs) {
      final removedInCollectionEvent = RemovedInCollection(doc, sourceRequestId: sourceRequestId);
      emitEvent(removedInCollectionEvent);
      await removedInCollectionEvent.ack.future;
    }
    
    final removeEvent = RemoveOnCollection(filter, sourceRequestId: sourceRequestId);
    emitEvent(removeEvent);
    await removeEvent.ack.future;
  }

  /// Removes all items from the collection.
  Future<void> clear({ String? sourceRequestId }) async {
    throw UnimplementedError('clear() has not been implemented.');
  }

  /// If you need to execute many operations at once, things can get slow as the index would be rebuild 
  /// on every change to the collection. To prevent this, you can use the .batch() method.
  /// 
  /// This method will execute all operations inside the callback without rebuilding the index/caches on every change. 
  /// If you need to batch updates of multiple collections, you can use the global Collection.batch() method.
  void batch(VoidCallback fn) {
    throw UnimplementedError('batch() has not been implemented.');
    // TODO: pause reactivity, persistence, and index updates
    fn();
    // TODO: resume reactivity, persistence, and index updates
  }

  emitEvent(CollectionEvent event, { String? sourceRequestId }) {
    _eventController.add(event);
  }

  /// Register a closure to be called when the object notifies its listeners.
  void addListener(VoidCallback listener) {
    if (_listeners.keys.contains(listener)) return;
    final streamSubscription = _eventController.stream.listen((event) async {
      if (event is WriteInCollection) await event.ack.future;
      listener();
    });
    _listeners.putIfAbsent(listener, () => streamSubscription);
  }

  /// Remove a previously registered closure from the list of closures that the
  /// object notifies.
  void removeListener(VoidCallback listener) {
    if (!_listeners.keys.contains(listener)) return;
    _listeners[listener]!.cancel();
    _listeners.remove(listener);
  }

  /// Disposes the collection and all its resources.
  /// 
  /// This will unregister the adapters and clean up all internal data structures.
  void dispose() async {
    _eventController.close();
    Collection._onDispose(this);
    // TODO: unregister/dispose adapters;
    Collection._collections.remove(name);
  }

  /// @nodoc
  /// Load the data from the persistence adapter to fetch adapter, listen for new external changes in persistence,
  /// and prepare index for first use.
  Future<void> _loadFromPersistence() async {
    if (_persistence == null) return;

    await _persistence.isReady;
    final initData = await _persistence.load();

    await _finder.load(initData.items ?? []);

    //TODO: Implement the use this feature
    // _persistence.onChangeData = _onChangeDataInPersistence;

    for (final index in indexes) {
      await index.build(initData.items ?? []);
    }
  }
  
  void _activateListenersOnComponents() {
    _eventController.stream.listen((event) async {
      if (_persistence != null) await _persistence.onCollectionEvent(event);
      await _finder.onCollectionEvent(event);
      for (final index in indexes) { await index.onCollectionEvent(event); }
      if (_synchronizer != null) await _synchronizer.onCollectionEvent(event);
      if (event is WriteInCollection) event.ack.complete();
    });
  }

  CollectionContext<I, E> contextFactory() {
    return (
      getName: () => name,
      getIndexes: () => indexes,
      find: find,
      save: save,
      update: update,
      updateAll: updateAll,
      remove: remove,
      clear: clear,
      batch: batch,
      emitEvent: emitEvent,
    );
  }
}