# AbstractDB

AbstractDB é uma solução local-first para abstração de banco de dados em aplicações Dart, com suporte a múltiplos backends de armazenamento, reatividade e sincronização.

## Recursos

- **Schemaless**: Armazenamento flexível de documentos sem esquemas rígidos.
- **Persistência**: Suporte a múltiplos backends (memória, Hive, customizável).
- **Reatividade**: Atualizações de dados em tempo real.
- **Sincronização**: Sincronização integrada com adaptadores customizáveis.

# Uso

Exemplo Rápido

```dart
import 'package:abstractdb/abstractdb.dart';

void main() async {
  // Crie uma coleção
  final posts = Collection<dynamic, dynamic>(name: 'posts');

  // Aguarde a inicialização
  await posts.isReady;

  // Salve alguns documentos
  await posts.save(Document({"id": "1", "title": "Hello World"}));

  // Consulte documentos
  final cursor = await posts.find('title'.equals('Hello World'));
  final docs = await cursor.fetch();
  print(docs);
}
```

## Tipos de Coleção
Coleção Básica
```dart
final posts = Collection<dynamic, dynamic>(name: 'posts');
```

Coleção Tipada
```dart
class Post implements DocumentData {
  final String title;
  final String content;

  Post({required this.title, required this.content});

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
  };
}

final posts = Collection<StringDocumentId, Post>(name: 'posts');
```

Persistência
Habilite armazenamento persistente usando Hive:
```dart
final posts = Collection<StringDocumentId, Post>(
  name: 'posts',
  persistence: (context) => HivePersistence(
    context,
    hivePath: './data',
  ),
);
```

Sincronização
Sincronize dados usando Supabase:
```dart
final posts = Collection<StringDocumentId, Post>(
  name: 'posts',
  synchronizer: (context) => SupabasePgmqSync(
    context,
    supabaseUrl: 'YOUR_SUPABASE_URL',
    supabaseKey: 'YOUR_SUPABASE_KEY',
  ),
);
```

Reatividade
Receba atualizações reativas usando sinais:
```dart
final posts = Collection<StringDocumentId, Post>(
  name: 'posts',
  reactivities: [SignalReactivity()],
);

final cursor = posts.find('author'.equals('John'));
final signal = cursor.asSignal();

signal.listen((docs) {
  print('Documents updated: ${docs.length}');
});
```

Eventos de Mudança
```dart
posts.on<CollectionChangeEvent>().listen((event) {
  print('Adicionados: ${event.added.length}');
  print('Modificados: ${event.modified.length}');
  print('Removidos: ${event.removed.length}');
});
```