import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/authentication/domain/entities/app_user.dart';
import 'package:coach_app_mobile/features/authentication/presentation/providers/auth_state_provider.dart';
import 'package:coach_app_mobile/features/coach/data/datasources/firebase_coach_datasource.dart';
import 'package:coach_app_mobile/features/coach/data/repositories/coach_profile_repository_impl.dart';
import 'package:coach_app_mobile/features/coach/domain/entities/coach_profile.dart';
import 'package:coach_app_mobile/features/coach/domain/repositories/coach_profile_repository.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_profile_provider.dart';
import 'package:coach_app_mobile/features/coach/presentation/pages/coach_profile_page.dart';
import 'package:coach_app_mobile/features/profile/domain/entities/client_profile.dart';
import 'package:coach_app_mobile/features/profile/presentation/pages/profile_provider.dart';

void main() {
  group('Firestore profile creation', () {
    test('creates an unavailable unverified profile for a coach', () async {
      final firestore = _TransactionFirestore()
        ..documents['users/coach-1'] = {'role': 'coach'};
      final source = FirebaseCoachDataSource(firestore: firestore);

      await source.createCoachProfileIfMissing('coach-1');

      expect(firestore.documents['coaches/coach-1'], {
        'coachId': 'coach-1',
        'specialties': <String>[],
        'experienceYears': 0,
        'hourlyRate': 0.0,
        'rating': 0.0,
        'verified': false,
        'bio': null,
        'address': null,
        'location': null,
        'available': false,
      });
    });

    test('preserves a profile created before the transaction', () async {
      final existing = <String, dynamic>{
        'specialties': ['Yoga'],
        'rating': 5,
      };
      final firestore = _TransactionFirestore()
        ..documents['coaches/coach-1'] = existing;
      final source = FirebaseCoachDataSource(firestore: firestore);

      await source.createCoachProfileIfMissing('coach-1');

      expect(firestore.documents['coaches/coach-1'], same(existing));
    });

    test('does not create a profile for a client or missing user', () async {
      for (final userData in [
        <String, dynamic>{'role': 'client'},
        null,
      ]) {
        final firestore = _TransactionFirestore();
        if (userData != null) {
          firestore.documents['users/coach-1'] = userData;
        }
        final source = FirebaseCoachDataSource(firestore: firestore);

        await expectLater(
          source.createCoachProfileIfMissing('coach-1'),
          throwsStateError,
        );
        expect(firestore.documents, isNot(contains('coaches/coach-1')));
      }
    });
  });

  group('professional profile initialization', () {
    test(
      'creates a missing profile and returns the persisted result',
      () async {
        final source = _FakeDataSource();
        final repository = CoachProfileRepositoryImpl(dataSource: source);

        final profile = await repository.getOrCreateOwnProfile('coach-1');

        expect(source.createCalls, 1);
        expect(profile.coachId, 'coach-1');
        expect(profile.specialties, isEmpty);
        expect(profile.available, isFalse);
      },
    );

    test('does not replace an existing professional profile', () async {
      final source = _FakeDataSource()
        ..coachData = {
          'specialties': ['Yoga'],
          'experienceYears': 7,
          'hourlyRate': 250,
          'rating': 4.5,
          'verified': true,
          'available': true,
        };
      final repository = CoachProfileRepositoryImpl(dataSource: source);

      final profile = await repository.getOrCreateOwnProfile('coach-1');

      expect(source.createCalls, 0);
      expect(profile.specialties, ['Yoga']);
      expect(profile.experienceYears, 7);
      expect(profile.verified, isTrue);
    });

    test('propagates failure to create a profile', () async {
      final source = _FakeDataSource()..createError = StateError('offline');
      final repository = CoachProfileRepositoryImpl(dataSource: source);

      await expectLater(
        repository.getOrCreateOwnProfile('coach-1'),
        throwsStateError,
      );
    });

    test('reads the public name from newly registered user fields', () async {
      final source = _FakeDataSource()
        ..userData = {
          'firstName': 'Roberto',
          'lastName': 'Valenzo',
          'displayName': 'Roberto Valenzo',
        };
      final repository = CoachProfileRepositoryImpl(dataSource: source);

      final identity = await repository.getPublicIdentity('coach-1');

      expect(identity.name, 'Roberto Valenzo');
    });
  });

  group('own profile provider', () {
    testWidgets('shows the professional profile for a registered coach', (
      tester,
    ) async {
      final source = _FakeDataSource();
      final repository = CoachProfileRepositoryImpl(dataSource: source);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(
                const AppUser(id: 'coach-1', email: '', role: 'coach'),
              ),
            ),
            coachProfileRepositoryProvider.overrideWithValue(repository),
            profileProvider.overrideWith(_FakeProfileNotifier.new),
          ],
          child: const MaterialApp(home: CoachProfilePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Roberto Valenzo'), findsOneWidget);
      expect(find.text('Información profesional'), findsOneWidget);
      expect(find.text('Sin especialidades registradas.'), findsOneWidget);
      expect(find.text('No disponible'), findsOneWidget);
      expect(source.createCalls, 1);
    });

    test(
      'allows the authenticated coach to initialize their own profile',
      () async {
        final repository = _FakeRepository();
        final container = _container(
          const AppUser(id: 'coach-1', email: '', role: 'coach'),
          repository,
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          ownCoachProfileProvider('coach-1'),
          (previous, next) {},
        );
        addTearDown(subscription.close);

        final profile = await container.read(
          ownCoachProfileProvider('coach-1').future,
        );

        expect(profile.coachId, 'coach-1');
        expect(repository.calls, 1);
      },
    );

    test('does not initialize a client or another coach profile', () async {
      for (final user in [
        const AppUser(id: 'coach-1', email: '', role: 'client'),
        const AppUser(id: 'other', email: '', role: 'coach'),
      ]) {
        final repository = _FakeRepository();
        final container = _container(user, repository);
        addTearDown(container.dispose);
        final subscription = container.listen(
          ownCoachProfileProvider('coach-1'),
          (previous, next) {},
        );
        addTearDown(subscription.close);

        await expectLater(
          container.read(ownCoachProfileProvider('coach-1').future),
          throwsStateError,
        );
        expect(repository.calls, 0);
      }
    });
  });
}

ProviderContainer _container(AppUser user, _FakeRepository repository) {
  return ProviderContainer(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(user)),
      coachProfileRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

class _FakeRepository implements CoachProfileRepository {
  int calls = 0;

  @override
  Future<CoachProfile> getOrCreateOwnProfile(String coachId) async {
    calls++;
    return CoachProfile(
      coachId: coachId,
      specialties: const [],
      experienceYears: 0,
      hourlyRate: 0,
      rating: 0,
      verified: false,
      available: false,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileNotifier extends ProfileNotifier {
  @override
  Future<ClientProfile?> build() async {
    return ClientProfile(
      uid: 'coach-1',
      email: 'coach@example.com',
      name: 'Roberto Valenzo',
      role: 'coach',
      status: 'active',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }
}

class _FakeDataSource extends FirebaseCoachDataSource {
  _FakeDataSource() : super(firestore: _FakeFirestore());

  Map<String, dynamic>? coachData;
  Map<String, dynamic>? userData;
  Object? createError;
  int createCalls = 0;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getCoachDocument(
    String id,
  ) async {
    return _Snapshot(id, coachData);
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getCoachUserDocument(
    String id,
  ) async {
    return _Snapshot(id, userData);
  }

  @override
  Future<void> createCoachProfileIfMissing(String coachId) async {
    createCalls++;
    if (createError != null) throw createError!;
    coachData ??= {'coachId': coachId, 'available': false};
  }
}

class _FakeFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TransactionFirestore implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _Collection(collectionPath);
  }

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    return transactionHandler(_Transaction(documents));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test double for the Firestore collection API.
// ignore: subtype_of_sealed_class
class _Collection implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.path);

  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return _Reference('${this.path}/$path');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test double for the Firestore document API.
// ignore: subtype_of_sealed_class
class _Reference implements DocumentReference<Map<String, dynamic>> {
  _Reference(this.path);

  @override
  final String path;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transaction implements Transaction {
  _Transaction(this.documents);
  final Map<String, Map<String, dynamic>> documents;

  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async {
    return _Snapshot(reference.path.split('/').last, documents[reference.path])
        as DocumentSnapshot<T>;
  }

  @override
  Transaction set<T>(
    DocumentReference<T> reference,
    T data, [
    SetOptions? options,
  ]) {
    documents[reference.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Test double for Firestore snapshots without requiring Firebase initialization.
// ignore: subtype_of_sealed_class
class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
