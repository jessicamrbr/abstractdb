// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supabase_pgmq_sync_adapter.dart';

// **************************************************************************
// StrEmbeddingGenerator
// **************************************************************************

const _$dbChangeReceivedEventJsonSchema = r'''
{
   "additionalProperties": false,
   "description": "This schema defines the structure of a database change event received from the foreign service. Keys and values are abbreviated to save space. reference https://maxwells-daemon.io/dataformat/",
   "properties": {
      "d": {
         "additionalProperties": true,
         "description": "The full document data after the change.",
         "properties": {},
         "type": "object"
      },
      "id": {
         "description": "The unique identifier (ID) for the event.",
         "type": "string"
      },
      "nvid": {
         "description": "The new version ID of the document after the change.",
         "type": "string"
      },
      "o": {
         "description": "The operation type that was performed on the collection. This can be one of the following: 'i' (insert), 'u' (update), or 'd' (delete).",
         "enum": [
            "i",
            "u",
            "d"
         ]
      },
      "ovid": {
         "description": "The old version ID of the document before the change. This must have matched with last new version ID in server.",
         "type": "string"
      },
      "rid": {
         "description": "The unique identifier (ID) of the document that was changed.",
         "type": "string"
      },
      "sid": {
         "description": "The unique identifier (ID) of the source where the change occurred.",
         "type": "string"
      },
      "ts": {
         "description": "The timestamp when the change occurred. This is in ISO 8601 format.",
         "type": "string"
      },
      "uid": {
         "description": "The unique identifier (ID) of the user who made the change.",
         "type": "string"
      }
   },
   "required": [
      "d",
      "id",
      "nvid",
      "o",
      "rid",
      "sid",
      "ts",
      "uid"
   ],
   "type": "object"
}
''';

const _$dbChangeSentEventJsonSchema = r'''
{
   "additionalProperties": false,
   "description": "This schema defines the structure of a database change event received from the foreign service. Keys and values are abbreviated to save space. reference https://maxwells-daemon.io/dataformat/",
   "properties": {
      "d": {
         "additionalProperties": true,
         "description": "The full document data after the change.",
         "properties": {},
         "type": "object"
      },
      "nvid": {
         "description": "The new version ID of the document after the change.",
         "type": "string"
      },
      "o": {
         "description": "The operation type that was performed on the collection. This can be one of the following: 'i' (insert), 'u' (update), or 'd' (delete).",
         "enum": [
            "i",
            "u",
            "d"
         ]
      },
      "ovid": {
         "description": "The old version ID of the document before the change. This must have matched with last new version ID in server.",
         "type": "string"
      },
      "rid": {
         "description": "The unique identifier (ID) of the document that was changed.",
         "type": "string"
      },
      "sid": {
         "description": "The unique identifier (ID) of the source where the change occurred.",
         "type": "string"
      },
      "uid": {
         "description": "The unique identifier (ID) of the user who made the change.",
         "type": "string"
      }
   },
   "required": [
      "d",
      "nvid",
      "o",
      "ovid",
      "rid",
      "sid",
      "uid"
   ],
   "type": "object"
}
''';

const _$dbChangeStoreEventJsonSchema = r'''
{
   "additionalProperties": false,
   "description": "This schema defines the structure of a database change event received from the foreign service. Keys and values are abbreviated to save space. reference https://maxwells-daemon.io/dataformat/",
   "properties": {
      "d": {
         "additionalProperties": true,
         "description": "The full document data after the change.",
         "properties": {},
         "type": "object"
      },
      "id": {
         "description": "The unique identifier (ID) of the document that was changed.",
         "type": "string"
      },
      "mode": {
         "description": "The mode of the event propagation.",
         "enum": [
            "stream",
            "flush"
         ]
      },
      "nvid": {
         "description": "The new version ID of the document after the change.",
         "type": "string"
      },
      "o": {
         "description": "The operation type that was performed on the collection. This can be one of the following: 'i' (insert), 'u' (update), or 'd' (delete).",
         "enum": [
            "i",
            "u",
            "d"
         ]
      },
      "ovid": {
         "description": "The old version ID of the document before the change. This must have matched with last new version ID in server.",
         "type": "string"
      },
      "rid": {
         "description": "The unique identifier (ID) of the document that was changed.",
         "type": "string"
      },
      "sid": {
         "description": "The unique identifier (ID) of the source where the change occurred.",
         "type": "string"
      },
      "status": {
         "description": "The status of the event.",
         "enum": [
            "pending",
            "commit",
            "conflict",
            "failed"
         ]
      },
      "uid": {
         "description": "The unique identifier (ID) of the user who made the change.",
         "type": "string"
      },
      "way": {
         "description": "The way the event ocurrence.",
         "enum": [
            "pull",
            "push"
         ]
      }
   },
   "required": [
      "d",
      "id",
      "mode",
      "nvid",
      "o",
      "ovid",
      "rid",
      "sid",
      "status",
      "uid",
      "way"
   ],
   "type": "object"
}
''';
