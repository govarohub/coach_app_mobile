# CK-019: Calificaciones y reseñas

| SUB-CK | Objetivo | Estado |
| --- | --- | --- |
| **CK-019.1** | Definir reglas funcionales de calificación y reseñas | ✅ COMPLETADO |
| **CK-019.2** | Definir el modelo de datos en Firestore | ✅ COMPLETADO |
| **CK-019.3** | Implementar entidad y validaciones de dominio | ✅ COMPLETADO |
| **CK-019.4** | Implementar datasource y repositorio de reseñas | ✅ COMPLETADO |
| **CK-019.5** | Validar elegibilidad y evitar reseñas duplicadas | ✅ COMPLETADO |
| **CK-019.6** | Crear flujo de captura y edición para el cliente | ✅ COMPLETADO |
| **CK-019.7** | Calcular y mostrar el resumen de calificaciones del coach | ✅ COMPLETADO |
| **CK-019.8** | Mostrar reseñas en el perfil público del coach | ✅ COMPLETADO |
| **CK-019.9** | Proteger reseñas con reglas de seguridad de Firestore | 🟡 EN PROGRESO |
| **CK-019.10** | Añadir pruebas unitarias, de widgets e integración | ✅ COMPLETADO |
| **CK-019.11** | Ejecutar QA y documentar evidencia de cierre | 🟡 EN PROGRESO |

## Documentos

- [CK-019.1: Reglas de calificaciones y reseñas](CK-019.1-reglas-de-calificaciones-y-resenas.md)
- [CK-019.2: Modelo de datos](CK-019.2-modelo-de-datos.md)
- Implementación CK-019.3: `lib/features/reviews/domain/`
- Pruebas CK-019.3: `test/features/reviews/review_business_rules_test.dart`
- Contrato de repositorio: `lib/features/reviews/domain/repositories/review_repository.dart`
- Modelo Firestore: `lib/features/reviews/data/models/review_model.dart`
- Datasource Firestore: `lib/features/reviews/data/datasources/firebase_review_data_source.dart`
- Implementación del repositorio: `lib/features/reviews/data/repositories/review_repository_impl.dart`
- Servicio de elegibilidad y envío: `lib/features/reviews/domain/services/review_service.dart`
- Providers y controller: `lib/features/reviews/presentation/review_providers.dart`
- Pruebas del servicio: `test/features/reviews/review_service_test.dart`
- Pantalla de calificación/edición: `lib/features/reviews/presentation/pages/client_review_page.dart`
- Acceso desde historial: `lib/features/reservation/presentation/pages/reservations_page.dart`
- Widget tests: `test/features/reviews/presentation/client_review_page_test.dart`
- Resumen de calificación: `lib/features/reviews/domain/entities/coach_review_summary.dart`
- Provider de resumen: `coachReviewSummaryProvider` en `lib/features/reviews/presentation/review_providers.dart`
- Índice de reseñas: `firestore.indexes.json`
- Pruebas del resumen: `test/features/reviews/coach_review_summary_test.dart`
- Sección pública de reseñas: `lib/features/reviews/presentation/pages/coach_reviews_section.dart`
- Widget tests de reseñas públicas: `test/features/reviews/presentation/coach_reviews_section_test.dart`
- Reglas de seguridad: `firestore.rules`
- Especificación de seguridad: [CK-019.9](CK-019.9-seguridad-firestore.md)
- Estado CK-019.9: reglas e índices desplegados el 2026-10-16; pendiente confirmar que no haya reseñas legadas con `clientId`.
- Evidencia CK-019.10: 20 pruebas unitarias/widgets pasan; `flutter analyze` no reporta errores; el flujo `integration_test/reviews_flow_test.dart` pasa en Chrome con Auth y Firestore Emulator (`All tests passed`).
- Evidencia QA CK-019.11: [registro de QA](../testing/CK-019.11-evidencia-qa.md); faltan QA manual, consulta real del perfil y verificar datos legados.

## Dependencias

CK-016 y CK-017 están completados. CK-018 permanece pendiente y no bloquea
CK-019; las reseñas se habilitarán por el estado `completed` de la reserva, no
por el estado de pago.