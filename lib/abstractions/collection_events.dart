import 'dart:async';

import 'package:abstractdb/abstractions/types.dart';
import 'package:abstractdb/implementations/cursor.dart';
import 'package:collql/collql.dart';

sealed class CollectionEvent<T> {}

class WriteInCollection extends CollectionEvent {
  final Completer<void> ack;
  final String? sourceRequestId;
  WriteInCollection({ this.sourceRequestId }) : ack = Completer<void>();
}

/// Triggered when a new item is added to the collection. 
/// 
/// The event handler receives the added item as an argument.
class AddedInCollection extends WriteInCollection {
  final Document document;
  AddedInCollection(this.document, { super.sourceRequestId });
}  

/// Fired when an existing item in the collection undergoes modification. 
/// 
/// The event handler is passed the modified item.
class ChangedInCollection extends WriteInCollection {
  final Document itemBefore;
  final Document document;
  final Modifier? modifier;
  ChangedInCollection(this.itemBefore, this.document, this.modifier, { super.sourceRequestId });
}  

/// Signaled when an item is removed or deleted from the collection. 
/// 
/// The event handler receives the removed item.
class RemovedInCollection extends WriteInCollection {
  final Document document;
  RemovedInCollection(this.document, { super.sourceRequestId });
}

/// Triggered when the save method is called. 
/// 
/// The event handler receives the selector, options and the returned item as arguments.
class SaveOnCollection extends WriteInCollection {
  final Document document;
  SaveOnCollection(this.document, { super.sourceRequestId });
}

/// Triggered when the update method is called. 
/// 
/// The event handler receives the selector and the modifier as arguments.
class UpdateOnCollection extends WriteInCollection {
  final Filter filter;
  final Modifier modifier;
  UpdateOnCollection(this.filter, this.modifier, { super.sourceRequestId });
}

/// Emitted when the updateAll method is called. 
/// 
/// The event handler receives the selector and the modifier as arguments.
class UpdateAllOnCollection extends WriteInCollection {
  final Modifier modifier;
  UpdateAllOnCollection(this.modifier, { super.sourceRequestId });
}

/// Triggered when the removeOne method is called. 
/// 
/// The event handler receives the selector as an argument.
class RemoveOnCollection extends WriteInCollection {
  final Filter filter;
  RemoveOnCollection(this.filter, { super.sourceRequestId });
}

/// Emitted when the removeMany method is called. 
/// 
/// The event handler receives the selector as an argument.
class ClerCollection extends WriteInCollection {}

/// A read operation is executed on the collection.
class ReadInCollection extends CollectionEvent {}

/// Emitted when the find method is called. 
/// 
/// The event handler receives the selector, options and the cursor as arguments.
class FindOnCollection extends ReadInCollection {
  final Filter? filter;
  final CursorOptions? options;
  final Cursor cursor;
  FindOnCollection(this.filter, this.options, this.cursor);
}

// --------------------------------------------------------------
// Persistence Events
// --------------------------------------------------------------
/// A event that is triggered when try Read or Write data from [PersistenceAdapter].
sealed class PersistenceEvents extends CollectionEvent {}

/// Marks the initialization of the persistence adapter.
class PersistenceStart extends PersistenceEvents {}

/// Signifies the reception of data from the persistence adapter.
class PersistenceReceived extends PersistenceEvents {}

/// Triggered after successfully transmitting data to the persistence adapter.
class PersistenceTransmitted extends PersistenceEvents {}

/// Indicates an error during persistence operations. 
/// 
/// The event handler receives an Error object describing the error.
class PersistenceError extends PersistenceEvents {
  final Error error;
  PersistenceError(this.error);
}

// --------------------------------------------------------------
// Sync Events
// --------------------------------------------------------------
/// A event that is triggered when try sync a [Collection].
sealed class SyncEvents extends CollectionEvent {}

/// Initiates the synchronization process.
class SyncStart extends SyncEvents {}

/// Indicates the completion of the synchronization process.
class SyncEnd extends SyncEvents {}

/// The Sync Status of adapter is changed.
class SyncStateChanged extends SyncEvents {
  final SyncStatus status;
  final Error? error;
  SyncStateChanged(this.status, this.error);
}

/// Indicates a conflict during synchronization on [Document].
class ConflictOnSync extends SyncEvents {
  final Document document;
  final String? detail;
  ConflictOnSync(this.document, {this.detail});
}

/// Indicates a failure during synchronization on [Document].
class FailOnSync extends SyncEvents {
  final dynamic error;
  FailOnSync(this.error);
}
