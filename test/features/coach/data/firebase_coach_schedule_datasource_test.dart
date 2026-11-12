import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/coach/data/datasources/firebase_coach_schedule_datasource.dart';

void main() {
  test('updates an available schedule atomically to blocked', () async {
    final firestore = _FakeFirestore({'status': 'available'});
    final source = FirebaseCoachScheduleDataSource(firestore: firestore);

    await source.updateSchedule(
      scheduleId: 'schedule',
      date: DateTime(2026, 11, 13),
      startTime: '08:00',
      endTime: '10:00',
      status: 'blocked',
    );

    expect(firestore.data?['status'], 'blocked');
    expect(firestore.data?['startTime'], '08:00');
    expect(firestore.data?['endTime'], '10:00');
  });

  test('does not overwrite a schedule reserved while editing', () async {
    final firestore = _FakeFirestore({'status': 'reserved'});
    final source = FirebaseCoachScheduleDataSource(firestore: firestore);

    await expectLater(
      source.updateSchedule(
        scheduleId: 'schedule',
        date: DateTime(2026, 11, 13),
        startTime: '08:00',
        endTime: '10:00',
        status: 'blocked',
      ),
      throwsStateError,
    );
    expect(firestore.data, {'status': 'reserved'});
  });

  test('does not allow setting reserved from the editor', () async {
    final firestore = _FakeFirestore({'status': 'available'});
    final source = FirebaseCoachScheduleDataSource(firestore: firestore);

    expect(
      () => source.updateSchedule(
        scheduleId: 'schedule',
        date: DateTime(2026, 11, 13),
        startTime: '08:00',
        endTime: '10:00',
        status: 'reserved',
      ),
      throwsStateError,
    );
    expect(firestore.data, {'status': 'available'});
  });
}

class _FakeFirestore implements FirebaseFirestore {
  _FakeFirestore(this.data);
  Map<String, dynamic>? data;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection();

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) => transactionHandler(_Transaction(this));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _Reference();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Reference implements DocumentReference<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transaction implements Transaction {
  _Transaction(this.firestore);
  final _FakeFirestore firestore;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async => _Snapshot(firestore.data) as DocumentSnapshot<T>;

  @override
  Transaction update(
    DocumentReference<Object?> reference,
    Map<Object, Object?> data,
  ) {
    firestore.data!.addAll(Map<String, dynamic>.from(data));
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this._data);
  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
