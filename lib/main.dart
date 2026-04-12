import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/supabase_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientación portrait para uso móvil en tienda/restaurante.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Barra de estado oscura sobre fondo claro.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Cargar variables de entorno.
  await dotenv.load(fileName: '.env');

  // Inicializar localización española.
  await initializeDateFormatting('es_ES', null);

  // Inicializar Supabase.
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: CosechaApp(),
    ),
  );
}
