// Smoke test de SIAPP-Acceso.
import 'package:flutter_test/flutter_test.dart';

import 'package:siapp_acceso/main.dart';

void main() {
  testWidgets('La app arranca y muestra el registro', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Sin perfil guardado, la primera pantalla es el registro.
    expect(find.text('Crea tu perfil'), findsOneWidget);
  });
}
