import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coach_app_mobile/features/profile/domain/entities/client_profile.dart';
import 'package:coach_app_mobile/features/profile/presentation/pages/profile_page.dart';
import 'package:coach_app_mobile/features/profile/presentation/pages/profile_provider.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo:
/// test/features/profile/presentation/profile_page_test.dart
///
/// CK-009.7.7 - Pruebas funcionales automatizadas del avatar.
///
/// Estas pruebas verifican:
/// A01 - Perfil sin fotografía.
/// A02 - Perfil con fotografía.
/// A03 - Cambio de fotografía.
/// A04 - Cancelación de eliminación.
/// A05 - Confirmación de eliminación.
/// A06 - Bloqueo durante procesamiento.
///
/// IMPORTANTE:
/// - No utiliza Firebase.
/// - No utiliza Internet.
/// - No requiere dominio.
/// - No modifica código productivo.
/// - Las imágenes de prueba se colocan directamente en ImageCache.
///
/// Las pruebas reales contra Firebase Storage y Firestore se realizarán
/// posteriormente en el emulador.
/// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CK-009.7.7 - Avatar de perfil', () {
    testWidgets(
      'CK-009.7.7-A01 - muestra Agregar foto cuando no existe fotografía',
      (tester) async {
        final notifier = _FakeProfileNotifier(_buildProfile());

        await tester.pumpWidget(_testApp(notifier));

        await tester.pump();
        await tester.pump();

        expect(find.text('Agregar foto'), findsOneWidget);

        expect(find.text('Eliminar'), findsNothing);

        expect(find.byIcon(Icons.person), findsOneWidget);
      },
    );

    testWidgets(
      'CK-009.7.7-A02 - muestra Cambiar foto y Eliminar cuando existe fotografía',
      (tester) async {
        // Colocamos la imagen directamente en la caché.
        //
        // De esta forma NetworkImage no intenta conectarse a Internet.
        await _cacheTestImage(tester, _testPhotoUrl);

        final notifier = _FakeProfileNotifier(
          _buildProfile(photoUrl: _testPhotoUrl),
        );

        await tester.pumpWidget(_testApp(notifier));

        await tester.pump();
        await tester.pump();

        expect(find.text('Cambiar foto'), findsOneWidget);

        expect(find.text('Eliminar'), findsOneWidget);

        expect(find.byType(CircleAvatar), findsOneWidget);
      },
    );

    testWidgets('CK-009.7.7-A03 - cambiar fotografía actualiza photoUrl', (
      tester,
    ) async {
      await _cacheTestImage(tester, _testPhotoUrl);

      final notifier = _FakeProfileNotifier(
        _buildProfile(photoUrl: _testPhotoUrl),
      );

      await tester.pumpWidget(_testApp(notifier));

      await tester.pump();
      await tester.pump();

      expect(find.text('Cambiar foto'), findsOneWidget);

      // Simula la selección y carga de una nueva fotografía.
      await tester.tap(find.text('Cambiar foto'));

      await tester.pump();

      expect(notifier.changePhotoCalled, isTrue);

      expect(notifier.state.value?.photoUrl, _newTestPhotoUrl);
    });

    testWidgets(
      'CK-009.7.7-A04 - cancelar eliminación conserva la fotografía',
      (tester) async {
        await _cacheTestImage(tester, _testPhotoUrl);

        final notifier = _FakeProfileNotifier(
          _buildProfile(photoUrl: _testPhotoUrl),
        );

        await tester.pumpWidget(_testApp(notifier));

        await tester.pump();
        await tester.pump();

        // Abrimos el diálogo de confirmación.
        await tester.tap(find.text('Eliminar'));

        await tester.pump();

        expect(find.text('Eliminar fotografía'), findsOneWidget);

        expect(
          find.text('¿Deseas eliminar tu fotografía de perfil?'),
          findsOneWidget,
        );

        // Cancelamos la eliminación.
        await tester.tap(find.text('Cancelar'));

        await tester.pump();

        expect(notifier.removePhotoCalled, isFalse);

        expect(notifier.state.value?.photoUrl, _testPhotoUrl);

        // El usuario permanece en Mi perfil.
        expect(find.text('Mi perfil'), findsOneWidget);

        // La opción de eliminar continúa disponible.
        expect(find.text('Eliminar'), findsOneWidget);
      },
    );

    testWidgets('CK-009.7.7-A05 - confirmar eliminación elimina photoUrl', (
      tester,
    ) async {
      await _cacheTestImage(tester, _testPhotoUrl);

      final notifier = _FakeProfileNotifier(
        _buildProfile(photoUrl: _testPhotoUrl),
      );

      await tester.pumpWidget(_testApp(notifier));

      await tester.pump();
      await tester.pump();

      // Abrimos el diálogo.
      await tester.tap(find.text('Eliminar'));

      await tester.pump();

      expect(find.text('Eliminar fotografía'), findsOneWidget);

      // El diálogo utiliza FilledButton para confirmar.
      final deleteButton = find.widgetWithText(FilledButton, 'Eliminar');

      expect(deleteButton, findsOneWidget);

      // Confirmamos la eliminación.
      await tester.tap(deleteButton);

      await tester.pump();
      await tester.pump();

      expect(notifier.removePhotoCalled, isTrue);

      // Después de eliminar, photoUrl debe ser null.
      expect(notifier.state.value?.photoUrl, isNull);

      // La UI debe regresar al estado sin fotografía.
      expect(find.text('Agregar foto'), findsOneWidget);

      expect(find.text('Eliminar'), findsNothing);
    });

    testWidgets(
      'CK-009.7.7-A06 - durante procesamiento las acciones quedan deshabilitadas',
      (tester) async {
        await _cacheTestImage(tester, _testPhotoUrl);

        final notifier = _FakeProfileNotifier(
          _buildProfile(photoUrl: _testPhotoUrl),
        );

        await tester.pumpWidget(_testApp(notifier, imageProcessing: true));

        await tester.pump();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Cambiar foto debe estar deshabilitado.
        final changeButton = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.text('Cambiar foto'),
            matching: find.byType(OutlinedButton),
          ),
        );

        expect(changeButton.onPressed, isNull);

        // Eliminar debe estar deshabilitado.
        final removeButton = tester.widget<TextButton>(
          find.ancestor(
            of: find.text('Eliminar'),
            matching: find.byType(TextButton),
          ),
        );

        expect(removeButton.onPressed, isNull);
      },
    );
  });
}

/// ---------------------------------------------------------------------------
/// Imagen de prueba
/// ---------------------------------------------------------------------------

/// URL ficticia.
///
/// NO corresponde a ningún dominio real.
/// Solamente representa el valor de photoUrl durante el test.
const String _testPhotoUrl = 'https://test.local/profile.jpg';

/// URL ficticia utilizada después de cambiar la fotografía.
const String _newTestPhotoUrl = 'https://test.local/new-profile.jpg';

/// Imagen PNG mínima de 1x1 píxel.
///
/// Se utiliza exclusivamente para que NetworkImage tenga una imagen válida
/// en la caché de Flutter durante las pruebas.
final Uint8List _testPngBytes = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xD7,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0xF0,
  0x1F,
  0x00,
  0x05,
  0x00,
  0x01,
  0xFF,
  0x89,
  0x99,
  0x3D,
  0x1D,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

/// Coloca una imagen válida directamente en ImageCache.
///
/// Esto evita completamente cualquier conexión HTTP.
Future<void> _cacheTestImage(WidgetTester tester, String url) async {
  final imageProvider = NetworkImage(url);

  final configuration = createLocalImageConfiguration(
    tester.element(find.byType(MaterialApp)),
  );

  final key = await imageProvider.obtainKey(configuration);

  final codec = await ui.instantiateImageCodec(_testPngBytes);

  final completer = MultiFrameImageStreamCompleter(
    codec: Future<ui.Codec>.value(codec),
    scale: 1.0,
  );

  PaintingBinding.instance.imageCache.putIfAbsent(key, () => completer);
}

/// ---------------------------------------------------------------------------
/// Perfil utilizado por las pruebas
/// ---------------------------------------------------------------------------

ClientProfile _buildProfile({String? photoUrl}) {
  final now = DateTime(2026, 1, 1);

  return ClientProfile(
    uid: 'test-user',
    email: 'test@example.com',
    name: 'Usuario de prueba',
    phone: null,
    role: 'client',
    photoUrl: photoUrl,
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

/// ---------------------------------------------------------------------------
/// Aplicación de prueba
/// ---------------------------------------------------------------------------

Widget _testApp(_FakeProfileNotifier notifier, {bool imageProcessing = false}) {
  return ProviderScope(
    overrides: [
      // Sustituimos únicamente ProfileNotifier durante el test.
      profileProvider.overrideWith(() => notifier),

      // Controlamos el estado de procesamiento.
      profileImageProcessingProvider.overrideWith((ref) => imageProcessing),
    ],
    child: const MaterialApp(home: ProfilePage()),
  );
}

/// ---------------------------------------------------------------------------
/// ProfileNotifier falso
/// ---------------------------------------------------------------------------
///
/// Este notifier NO se utiliza en producción.
/// Solo permite probar ProfilePage sin conectarse a Firebase.

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._initialProfile);

  final ClientProfile _initialProfile;

  bool changePhotoCalled = false;
  bool removePhotoCalled = false;

  @override
  Future<ClientProfile?> build() async {
    return _initialProfile;
  }

  /// Simula una carga correcta de una nueva fotografía.
  @override
  Future<void> pickAndUploadProfileImage() async {
    changePhotoCalled = true;

    state = AsyncData(
      ClientProfile(
        uid: _initialProfile.uid,
        email: _initialProfile.email,
        name: _initialProfile.name,
        phone: _initialProfile.phone,
        role: _initialProfile.role,
        photoUrl: _newTestPhotoUrl,
        status: _initialProfile.status,
        createdAt: _initialProfile.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Simula una eliminación correcta de la fotografía.
  @override
  Future<void> removeProfileImage() async {
    removePhotoCalled = true;

    state = AsyncData(
      ClientProfile(
        uid: _initialProfile.uid,
        email: _initialProfile.email,
        name: _initialProfile.name,
        phone: _initialProfile.phone,
        role: _initialProfile.role,
        photoUrl: null,
        status: _initialProfile.status,
        createdAt: _initialProfile.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
