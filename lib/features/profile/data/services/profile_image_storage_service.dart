import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// ---------------------------------------------------------------------------
/// Coach App Mobile
///
/// Archivo: profile_image_storage_service.dart
///
/// Servicio responsable de seleccionar, almacenar y eliminar imágenes
/// de perfil en Firebase Storage.
///
/// Compatible con Android, iOS y Flutter Web.
///
/// CK-009.7.6:
/// - Valida la imagen seleccionada.
/// - Limita el tamaño máximo.
/// - Controla formatos permitidos.
/// - Evita operaciones de Firebase indefinidamente pendientes.
/// - Mantiene errores controlables por ProfileNotifier.
/// ---------------------------------------------------------------------------

final class ProfileImageStorageService {
  ProfileImageStorageService({
    FirebaseStorage? storage,
    ImagePicker? imagePicker,
  }) : _storage = storage ?? FirebaseStorage.instance,
       _imagePicker = imagePicker ?? ImagePicker();

  final FirebaseStorage _storage;
  final ImagePicker _imagePicker;

  /// Tamaño máximo permitido para el avatar: 5 MB.
  static const int maxImageSizeBytes = 5 * 1024 * 1024;

  /// Tiempo máximo permitido para operaciones de Storage.
  static const Duration operationTimeout = Duration(seconds: 30);

  /// Obtiene la referencia única de la fotografía del usuario.
  Reference _profileImageReference(String uid) {
    return _storage.ref().child('users/$uid/profile.jpg');
  }

  /// Selecciona una fotografía desde la galería y la sube a Storage.
  ///
  /// Devuelve null si el usuario cancela la selección.
  Future<String?> pickAndUploadProfileImage({required String uid}) async {
    // El selector de imágenes se mantiene independiente de Storage.
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    // Cancelar la selección no representa un error.
    if (image == null) {
      return null;
    }

    return uploadProfileImage(uid: uid, image: image);
  }

  /// Sube una fotografía existente y devuelve su URL de descarga.
  ///
  /// Se utilizan bytes en lugar de dart:io/File para mantener compatibilidad
  /// entre Android, iOS y Flutter Web.
  Future<String> uploadProfileImage({
    required String uid,
    required XFile image,
  }) async {
    // Leemos la imagen como bytes.
    final Uint8List imageBytes = await image.readAsBytes().timeout(
      operationTimeout,
      onTimeout: () {
        throw TimeoutException('La lectura de la fotografía tardó demasiado.');
      },
    );

    // Validamos que la imagen no supere el tamaño máximo.
    if (imageBytes.length > maxImageSizeBytes) {
      throw ProfileImageValidationException(
        'La fotografía supera el tamaño máximo permitido de 5 MB.',
      );
    }

    // Validamos que el archivo tenga un formato compatible.
    final contentType = _contentTypeFromFileName(image.name);

    final reference = _profileImageReference(uid);

    // Subimos los bytes directamente a Firebase Storage.
    await reference
        .putData(imageBytes, SettableMetadata(contentType: contentType))
        .timeout(
          operationTimeout,
          onTimeout: () {
            throw TimeoutException(
              'La carga de la fotografía tardó demasiado.',
            );
          },
        );

    // Obtenemos la URL pública/descargable de Firebase Storage.
    return reference.getDownloadURL().timeout(
      operationTimeout,
      onTimeout: () {
        throw TimeoutException(
          'No fue posible obtener la URL de la fotografía.',
        );
      },
    );
  }

  /// Determina el tipo MIME de la imagen.
  ///
  /// Solo se permiten formatos adecuados para un avatar.
  String _contentTypeFromFileName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;

    switch (extension) {
      case 'png':
        return 'image/png';

      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      default:
        throw ProfileImageValidationException(
          'El formato de la fotografía no es compatible.',
        );
    }
  }

  /// Elimina la fotografía almacenada del usuario.
  ///
  /// Si el archivo no existe, la operación se considera completada.
  Future<void> removeProfileImage({required String uid}) async {
    final reference = _profileImageReference(uid);

    try {
      await reference.delete().timeout(
        operationTimeout,
        onTimeout: () {
          throw TimeoutException(
            'La eliminación de la fotografía tardó demasiado.',
          );
        },
      );
    } on FirebaseException catch (error) {
      // Si no existe el archivo, no hay nada más que eliminar.
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }
  }
}

/// Error específico de validación de fotografías de perfil.
///
/// Permite que ProfileNotifier y la UI distingan errores de validación
/// de errores producidos por Firebase o por la red.
class ProfileImageValidationException implements Exception {
  const ProfileImageValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
