import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// 메모 테이블.
///
/// [hiddenRanges]는 프라이빗 드래그로 가린 범위를 JSON 배열로 저장한다.
/// (2단계에서 사용. 지금 컬럼을 만들어 두어 이후 마이그레이션을 피한다.)
class Notes extends Table {
  TextColumn get id => text()();
  TextColumn get content => text().withDefault(const Constant(''))();
  BoolColumn get privateMode => boolean().withDefault(const Constant(false))();
  TextColumn get hiddenRanges => text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'private_memo'));

  @override
  int get schemaVersion => 1;
}
