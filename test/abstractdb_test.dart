// import 'dart:convert';

import 'dart:async';

import 'package:abstractdb/abstractdb.dart';
// import 'package:abstractdb/abstractions/collection_context.dart';
// import 'package:abstractdb/implementations/synchronizers/supabase_pgmq_sync_adapter.dart';
// import 'package:http/http.dart' as http;
// import 'package:supabase/supabase.dart';
// import 'package:hive/hive.dart';
import 'package:test/test.dart';

void main() {
  group('Getting Started\n', () {    
    test('Simple collection in memory, with default manipulation types (id as String, data as Map<String, dynamic>)', () async {
      final employees = Collection.basic(name: 'employees');
      await employees.isReady;
      await employees.save({"id": "1", "name": "John Doe"});
      await employees.save({"id": "2", "name": "Jane Doe"});
      await employees.save({"id": "3", "name": "John Smith"});
      await employees.save({"id": "4", "name": "Jane Smith"});

      await Future.delayed(Duration(seconds: 1));

      final cursor = await employees.find('name'.regex('John*'));
      int count = 0;
      for (final doc in await cursor.fetch()){
        expect(doc['name'], startsWith('John'));
        count++;
      }
      expect(count, 2);
    });

    test('Simple collection in memory, with id in Collection as int and data as JSON (Map<String, dynamic>)', () async {
      final employees = Collection.json<int>(name: 'employees');
      await employees.isReady;
      await employees.save({"id": 1, "name": "John Doe"});
      await employees.save({"id": 2, "name": "Jane Doe"});
      await employees.save({"id": 3, "name": "John Smith"});
      await employees.save({"id": 4, "name": "Jane Smith"});

      await Future.delayed(Duration(seconds: 1));

      final cursor = await employees.find('name'.regex('John*'));
      int count = 0;
      for (final doc in await cursor.fetch()){
        expect(doc['name'], startsWith('John'));
        count++;
      }
      expect(count, 2);
    });

    test('Simple collection in memory, with custom types for id and data', () async {
      final employees = Collection.typed<int, Employee>(
        name: 'posts', 
        transformIn: (employee) => Document({"id": employee.id, "name": employee.name}), 
        transformOut: (doc) => Employee(doc['id'], doc['name'])
      );
      await employees.isReady;
      await employees.save(Employee(1, "John Doe"));
      await employees.save(Employee(2, "Jane Doe"));
      await employees.save(Employee(3, "John Smith"));
      await employees.save(Employee(4, "Jane Smith"));

      await Future.delayed(Duration(seconds: 1));

      final cursor = await employees.find('name'.regex('John*'));
      int count = 0;
      for (final emp in await cursor.fetch()){
        expect(emp.name, startsWith('John'));
        count++;
      }
      expect(count, 2);
    });

    // test('Simple collection with persistence in hive with encrypt', () async {
    //   // Generate a secure key for the Hive box
    //   // print(base64UrlEncode(Hive.generateSecureKey())); // kBAZDkdH9bZ_gilHq1ZYBMDG5ivJVXdpuw3lf1slwnc=

    //   final posts = Collection<dynamic, String, dynamic>(
    //     name: 'posts', 
    //     // persistence: (context) => HivePersistence<String>(
    //     //   context,
    //     //   hiveBoxSecret: "kBAZDkdH9bZ_gilHq1ZYBMDG5ivJVXdpuw3lf1slwnc=",
    //     // ),
    //   );
    //   await posts.isReady;
    //   await posts.save(Document({"id": "1", "name": "John Doe"}));
    //   await posts.save(Document({"id": "2", "name": "Jane Doe"}));
    //   await posts.save(Document({"id": "3", "name": "John Smith"}));
    //   await posts.save(Document({"id": "4", "name": "Jane Smith"}));

    //   final cursor = await posts.find('name'.regex('John*'));
    //   int count = 0;
    //   for (final doc in await cursor.fetch()){
    //     expect(doc['/name'], startsWith('John'));
    //     count++;
    //   }
    //   expect(count, 2);
    // });

    test('Fulltext indexed collection in memory', () async {
      final employees = Collection.basic(
        name: 'employees',
        indexes: [
          TextIndexProvider<String>('textOnName', ['name']),
        ],
      );
      await employees.isReady;
      await employees.save({"id": "1", "name": "John Doe"});
      await employees.save({"id": "2", "name": "Jane Doe"});
      await employees.save({"id": "3", "name": "John Smith"});
      await employees.save({"id": "4", "name": "Jane Smith"});

      final cursor = await employees.find('name'.text('smit'));
      int count = 0;
      for (final doc in await cursor.fetch()){
        expect(doc['name'], endsWith('Smith'));
        count++;
      }
      expect(count, 2);
    });

    // test('Collection in memory, synced with supabase, persistence of logs', () async {
    //   final client = SupabaseClient(
    //     // 'https://xyzcompany.supabase.co',
    //     'https://aonjcaskowsvtpqlwhsd.supabase.co',
    //     // 'public-anon-key',
    //     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvbmpjYXNrb3dzdnRwcWx3aHNkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzA4MjgxODksImV4cCI6MjA0NjQwNDE4OX0.SNWDVInCM4g8tG84HEtn8tIWoqc1Yc3rjeuejb3na54',
    //   );
    //   // await client.auth.verifyOTP(
    //   //   email: 'jessica_moura@outlook.com',
    //   //   token: '417022',
    //   //   type: OtpType.email,
    //   // );

    //   late final SupabaseSyncAdapter<String> adapter;

    //   adapterFactory<I>(CollectionContext context, String name) {
    //     adapter = SupabaseSyncAdapter<String>(
    //       context, client: client,
    //       localQueueLog: Collection<dynamic, String, dynamic>(
    //         name: '${name}_queue_log',
    //         indexes: [
    //           UniqueEqualityIndexProvider('id', ['id']),
    //         ],
    //         // persistence: (context) => HivePersistence<String>(
    //         //   context,
    //         //   hiveBoxSecret: "kBAZDkdH9bZ_gilHq1ZYBMDG5ivJVXdpuw3lf1slwnc=",
    //         // ),
    //       ),
    //       hasConnection: () => checkConnection('https://google.com'),
    //     );
    //     return adapter;
    //   }

    //   final name = 'barton_resources';
    //   final posts = Collection<dynamic, String, dynamic>(
    //     name: name,
    //     synchronizer: (context) => adapterFactory<String>(context, name),
    //   );
    //   await posts.isReady;
    //   // await posts.save(Document({"id": "11", "name": "John Doe", "meta": { "versionId": '${Xid()};${Xid()}', "lastUpdated": DateTime.now().toIso8601String(), }}));
    //   // await posts.save(Document({"id": "21", "name": "Jane Doe", "meta": { "versionId": '${Xid()};${Xid()}', "lastUpdated": DateTime.now().toIso8601String(), }}));
    //   // await posts.save(Document({"id": "31", "name": "John Smith", "meta": { "versionId": '${Xid()};${Xid()}', "lastUpdated": DateTime.now().toIso8601String(), }}));
    //   // await posts.save(Document({"id": "21", "name": "Jane Osborn", "meta": { "versionId": '${Xid()};${Xid()}', "lastUpdated": DateTime.now().toIso8601String(), }}));
    //   // await posts.save(Document({"id": "41", "name": "Jane Smith", "meta": { "versionId": '${Xid()};${Xid()}', "lastUpdated": DateTime.now().toIso8601String(), }}));

    //   // final cursor = await posts.find('name'.regex('John*'));
    //   // int count = 0;
    //   // for (final doc in await cursor.fetch()){
    //   //   expect(doc['name'], startsWith('John'));
    //   //   count++;
    //   // }
    //   // expect(count, 2);

    //   await Future.delayed(Duration(seconds: 5));
    //   await adapter.sync();
    //   await Future.delayed(Duration(seconds: 5));
    //   await adapter.sync();
    //   await Future.delayed(Duration(seconds: 5));
    //   await adapter.sync();
    //   await Future.delayed(Duration(seconds: 5));
    //   await adapter.sync();
    // });
  });
}

class Employee {
  final int id;
  final String name;
  Employee(this.id, this.name);
}

// Future<bool> checkConnection(String url) async {
//   try {
//     final response = await http.head(Uri.parse(url),);
//     return response.statusCode >= 200 && response.statusCode < 400;
//   } catch (e) {
//     return false;
//   }
// }
