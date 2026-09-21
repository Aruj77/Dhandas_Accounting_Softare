import 'package:drift/drift.dart';

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityTableName => text()();

  TextColumn get recordUuid => text()();

  TextColumn get operation => text()();

  TextColumn get payloadJson => text()();

  DateTimeColumn get queuedAt =>
      dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced =>
      boolean().withDefault(const Constant(false))();
}

class SyncCursors extends Table {
  TextColumn get entityTableName => text()();

  DateTimeColumn get lastPulledAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entityTableName};
}