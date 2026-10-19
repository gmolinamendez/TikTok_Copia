import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/config/theme/app_theme.dart';
import 'package:toktok/firebase_options.dart';
import 'package:toktok/infrastructure/datasources/firestore_video_posts_datasource.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
import 'package:toktok/presentation/screens/auth/login_screen.dart';
import 'package:toktok/presentation/screens/discover/discover_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( options: DefaultFirebaseOptions.currentPlatform );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'TokTik',
        debugShowCheckedModeBanner: false,
        theme: AppTheme().getTheme(),
        // Permite deslizar entre videos con el mouse (web / escritorio), no solo con el dedo
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}


// Si no hay sesión muestra el login; si hay, el feed de videos de ese usuario
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {

    final user = context.watch<AuthProvider>().user;
    if ( user == null ) return const LoginScreen();

    return ChangeNotifierProvider(
      key: ValueKey( user.uid ),
      create: (_) => DiscoverProvider(
        videosDatasource: FirestoreVideoPostsDatasource(),
        userId: user.uid,
      )..loadNextPage(),
      child: const DiscoverScreen(),
    );
  }
}
