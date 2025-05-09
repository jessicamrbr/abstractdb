import 'dart:convert';

import 'package:abstractdb/abstractions/collection_events.dart';
import 'package:abstractdb/abstractions/persistence_adapter.dart';
import 'package:abstractdb/abstractions/types.dart';
import 'package:collql/implementations/document.dart';
import 'package:hive/hive.dart';

/// [I] is the type of ID of the documents in collection.
class HivePersistence<I> extends PersistenceAdapter {
  /// The name of the collection to be used in the hive box.
  final String hiveBoxName;
  final String? hiveBoxSecret;
  final String hivePath;

  late final LazyBox hiveLazyBox;

  HivePersistence(super.context, {
    String? hiveBoxName,
    this.hiveBoxSecret,
    this.hivePath = './',
  }) :
    hiveBoxName = hiveBoxName ?? 'HB-${context.getName()}'
  {
    initialize();
  }

  @override
  Future<void> onInit() async {
    Hive.init(hivePath);

    HiveAesCipher? encryptionCipher;
    if (hiveBoxSecret != null) {
      encryptionCipher = HiveAesCipher(base64Url.decode(hiveBoxSecret!));
    }
    
    hiveLazyBox = await Hive.openLazyBox(hiveBoxName, encryptionCipher: encryptionCipher);
    print("Hive Loaded: $hiveBoxName");

    // TODO: Implement a way to bind ext changes on hive box, filter changes is only external, map to internal format
    // hiveLazyBox.watch().where(test).map((he) => ).listen(onChangeData);
  }

  /// Listen to changes in the collection.
  @override
  Future<void> onCollectionEvent(CollectionEvent event) async { }

  @override
  Future<DataTransfer> load() async {
    await isReady;
    List<Document> items = [];
    for (final key in hiveLazyBox.keys) {
      final data = await hiveLazyBox.get(key);
      if (data == null) continue;
      items.add(Document(jsonDecode(jsonEncode(data))));
    }
    return DataTransfer(items: items);
  }

  @override
  Future<void> save(DataTransfer data) async {
    await isReady;
    if (data.changes == null) return;
    final (added: addeds, modified: modifieds, removed: removeds) = data.changes!;
    for (final item in addeds) {
      await hiveLazyBox.put(item.id, jsonDecode(item.toJsonString()));
    }
    for (final item in modifieds) {
      await hiveLazyBox.put(item.id, jsonDecode(item.toJsonString()));
    }
    for (final item in removeds) {
      await hiveLazyBox.delete(item.id);
    }
  }

  @override
  Future<void>? onDispose() async {
    await hiveLazyBox.compact();
    await hiveLazyBox.close();
  }
}