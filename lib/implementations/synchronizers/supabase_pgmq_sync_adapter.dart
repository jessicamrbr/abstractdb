import 'dart:async';
import 'dart:collection';

import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/abstractions/sync_adapter.dart';
import 'package:abstractdb/abstractions/types.dart';
import 'package:abstractdb/implementations/collection.dart';
import 'package:abstractdb/utils/types.dart';
import 'package:collql/collql.dart';
import 'package:embed_annotation/embed_annotation.dart';
import 'package:supabase/supabase.dart';

part 'supabase_pgmq_sync_adapter.g.dart';

/// Preconditions:
/// 
/// - Supabase need corresponding table with the name as [pgmqTableName] or [Collection].[name] + '_queue_log'.
/// 
/// -- The table must have the following columns conforming to [dbChangeEventJsonSchema];
/// 
/// -- Trigger has create to conflict handler;
/// 
/// - Documents in AbstractDB collection must have properties [id], [versionIdPath], [updatedAtPath];
/// 
/// - The value of [versionIdPath] must be a string, containing the old version ID and new version ID of the document.
/// separated by a semicolon char. E.g. '123;124'.
///
/// [I] is the type of ID of the documents in collection.
/// [E] is the type of the documents in collection.
class SupabaseSyncAdapter<I, E> extends SyncAdapter<I, E> {
  final SupabaseClient client;
  final Collection localQueueLog;

  final String _pgmqSchemaName;
  late final String _pgmqTableName;
  
  final Future<bool> Function()? hasConnection;

  SupabaseSyncAdapter(super.context, {
    required this.client,
    required this.localQueueLog,
    String? pgmqSchemaName,
    String? pgmqTableName,
    this.hasConnection,
  }) : _pgmqSchemaName = pgmqTableName ?? 'public' {
    _pgmqTableName = (pgmqTableName != null) ? pgmqTableName : '${context.getName()}_queue_log';
  }

  late RealtimeChannel? _channel;
  String? _adapterId;

  @override
  String get adapterId => _adapterId ?? super.adapterId;

  String get _user => client.auth.currentUser?.id ?? 'anonymous';

  DateTime since = DateTime.now().toUtc();

  @override
  Future<void> onInit() async {
    await localQueueLog.isReady;
    await _setUsedAdapterId();
    since = await _getLastSuccessPullDate();

    _channel = client
      .channel(adapterId)
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: _pgmqSchemaName,
        table: _pgmqTableName,
        callback: _onForeignEvent,
      )
      .subscribe();

    Timer.periodic(Duration(seconds: 30), (timer) { cancelTimer = timer.cancel; sync(); });
  }

  VoidCallback cancelTimer = () {};

  Future<void> sync() async {
    if (status == SyncStatus.syncing) return;
    if (
      status == SyncStatus.synced 
      && (since.toIso8601String().compareTo(DateTime.now().toUtc().subtract(Duration(minutes: 5)).toIso8601String()) == -1)
    ) { status = SyncStatus.unsynced; }
    if (status != SyncStatus.unsynced) return;

    status = SyncStatus.syncing;
    final newSince = DateTime.now().toUtc();

    await _pullForeignChangesSince(since);
    await _pushUnsyncedCollectionChanges();

    since = await _setLastSuccessPullDate(newSince);
    status = SyncStatus.synced;
  }

  Future<void> _setUsedAdapterId() async {
    final cursor = await localQueueLog.find('id'.eq('meta::adapterId'));
    final document = (await cursor.fetch()).firstOrNull;
    if (document == null) {
      await localQueueLog.save(Document({
        'id': 'meta::adapterId',
        'adapterId': adapterId,
      }));
    } else {
      _adapterId = document['adapterId'];
    }
  }

  Future<DateTime> _getLastSuccessPullDate() async {
    final cursor = await localQueueLog.find('id'.eq('meta::lastPullDate'));
    final document = (await cursor.fetch()).firstOrNull;
    if (document != null) {
      return DateTime.parse(document['lastPullDate']);
    } else {
      return _setLastSuccessPullDate(DateTime.fromMillisecondsSinceEpoch(0));
    }
  }

  Future<DateTime> _setLastSuccessPullDate(DateTime date) async {
    final document = Document({
      'id': 'meta::lastPullDate',
      'lastPullDate': date.toIso8601String(),
    });
    await localQueueLog.save(document);
    return DateTime.parse(document['lastPullDate']);
  } 

  /// Receive events from the [Collection], apply changes on Supabase foreign service.
  /// 
  /// ⚡️ Stream sync mode (Reactive), ➡️ Push Collection >> Foreign
  @override
  Future<void> onCollectionEvent(CollectionEvent event) async {
    await isReady;
    late Map<String, dynamic>? operation;
    operation = switch (event) {
      AddedInCollection _ => _convertToOperation(event.document, DbChangeEventType.insert),
      ChangedInCollection _ => _convertToOperation(event.document, DbChangeEventType.update),
      RemovedInCollection _ => _convertToOperation(event.document, DbChangeEventType.delete),
      _ => null
    };
    if (operation == null) return;
    if ((event as WriteInCollection).sourceRequestId == adapterId) return;

    status = SyncStatus.unsynced;
    bool isConnected = hasConnection != null ? (await hasConnection!()) : true;

    final logItem = Document({
      ...operation, 
      "mode": EventSyncMode.stream.toString(),
      "way": EventSyncWay.push.toString(),
      "status": EventSyncStatus.pending.toString(),
    });
    logItem.generateId();

    try {
      if(isConnected) {
        await _sendToForeignService([
          logItem.toJsonMap()..remove('mode')..remove('way')..remove('status')
        ]);
        logItem["status"] = EventSyncStatus.commit.toString();
      }
    } on PostgrestException catch (e) {
      if (e.message.contains('CONFLICT_EXCEPTION')) {
        logItem["status"] = EventSyncStatus.conflict.toString();
        context.emitEvent(ConflictOnSync(logItem, detail: e.message));      
      } else {
        logItem["status"] = EventSyncStatus.failed.toString();
        context.emitEvent(FailOnSync(e));
      }
    } catch (e) {
      logItem["status"] = EventSyncStatus.failed.toString();
      context.emitEvent(FailOnSync(e));
    }

    final isValid = logItem.validate('', dbChangeStoreEventJsonSchema);
    if (!isValid) throw FormatException("DbChangeEvent not is valid");

    if (logItem['status'] != EventSyncStatus.commit.toString()) {
      await localQueueLog.save(logItem, sourceRequestId: adapterId);
    }
  }

  /// Query local stage queue for changes since the last sync, and apply them to the foreign service.
  /// 
  /// 🔃 Flush sync sode, ➡️ Push Collection >> Foreign
  Future<void> _pushUnsyncedCollectionChanges() async {
    await isReady;
    final db = await localQueueLog.findAll();
    print('rloc: ${(await db.map<String>((d) async => d.toJsonString())).toList()}');
    
    final localQueueLogResult = await localQueueLog.find(or([
      'status'.eq('pending'),
      'status'.eq('failed'),
    ]));
    final localQueueLogItems = (await localQueueLogResult.fetch()).map(
        (d) => d.toJsonMap()..remove('mode')..remove('way')..remove('status')
    ).toList();    
    if(localQueueLogItems.isEmpty) return;

    for (final localQueueLogItem in localQueueLogItems) {
      try {
        await _sendToForeignService([]);
      } finally {
        await localQueueLog.remove('id'.eq(localQueueLogItem['id']));
      }
    }
  }

  Future<void> _sendToForeignService(List<Map<String, dynamic>> operations) async {
    await isReady;

    await client.schema(_pgmqSchemaName).from(_pgmqTableName)
      .upsert(operations)
      .select();
  }

  Map<String, dynamic> _convertToOperation(Document resource, DbChangeEventType operationType) {
    final dbChangeEvent = Document({
      "d": resource.toJsonMap(),
      "nvid": resource[versionIdPath]?.toString().split(";").lastOrNull,
      "o": operationType.toString(),
      "ovid": resource[versionIdPath]?.toString().split(";").firstOrNull,
      "rid": (resource.id ?? resource.generateId()).toString(),
      "sid": adapterId,
      "uid": _user,
    });
    final isValid = dbChangeEvent.validate('', dbChangeSentEventJsonSchema);
    if (!isValid) {
      throw FormatException("DbChangeEvent not is valid");
    }
    return dbChangeEvent.toJsonMap();
  }

  /// Receive events from the foreign service, apply changes on collection.
  /// 
  /// ⚡️ Stream sync mode (Reactive), ⬅️ Pull Foreign >> Collection
  void _onForeignEvent(event) {
    event as PostgresChangePayload;
    status = SyncStatus.unsynced;
    _processForeignChange(event.newRecord);
  }

  /// Query the foreign service for changes since the last sync, and apply them to the collection.
  /// 
  /// 🔃 Flush sync mode, ⬅️ Pull Foreign >> Collection
  Future<void> _pullForeignChangesSince(DateTime since) async {
    final dataFromForeignService = await client.schema(_pgmqSchemaName).from(_pgmqTableName)
      .select()
      .gte('ts', since.toIso8601String());

    for (final event in dataFromForeignService) {
      _processForeignChange(event);
    }
  }

  void _processForeignChange(Map<String, dynamic> eventDataMap) {
    final eventDataDoc = Document(eventDataMap);
    if (!eventDataDoc.validate('', dbChangeReceivedEventJsonSchema)) {
      context.emitEvent(FailOnSync(AssertionError("Foreign event not is DbChangeEvent")));
      return;
    }

    if(eventDataDoc['sid'] == adapterId) return;

    // DELETED
    if (eventDataDoc['o'] == "d") context.remove(eventDataDoc['rid'], sourceRequestId: adapterId);
    // INSERTED
    if (eventDataDoc['o'] == "i") context.save(eventDataDoc['d'], sourceRequestId: adapterId);
    // UPDATED
    if (eventDataDoc['o'] == "u") context.save(eventDataDoc['d'], sourceRequestId: adapterId);
  }

  @override
  Future<void> dispose() async {
    cancelTimer();
    if (_channel != null) await client.removeChannel(_channel!);
  }
}

@EmbedStr("./db_change_received_event.schema.json", raw: true)
const String dbChangeReceivedEventJsonSchema = _$dbChangeReceivedEventJsonSchema;
@EmbedStr("./db_change_sent_event.schema.json", raw: true)
const String dbChangeSentEventJsonSchema = _$dbChangeSentEventJsonSchema;
@EmbedStr("./db_change_store_event.schema.json", raw: true)
const String dbChangeStoreEventJsonSchema = _$dbChangeStoreEventJsonSchema;

enum DbChangeEventType {
  insert("i"),
  update("u"),
  delete("d");

  final String _raw;
  const DbChangeEventType(this._raw);

  @override
  String toString() => _raw;
}

enum EventSyncMode {
  stream("stream"),
  flush("flush");

  final String _raw;
  const EventSyncMode(this._raw);

  @override
  String toString() => _raw;
}

enum EventSyncWay {
  pull("pull"),
  push("push");

  final String _raw;
  const EventSyncWay(this._raw);

  @override
  String toString() => _raw;
}

enum EventSyncStatus {
  pending("pending"),
  commit("commit"),
  failed("failed"),
  conflict("conflict");

  final String _raw;
  const EventSyncStatus(this._raw);

  @override
  String toString() => _raw;
}