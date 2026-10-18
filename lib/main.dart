import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/config/theme/app_theme.dart';
import 'package:toktok/firebase_options.dart';
import 'package:toktok/infrastructure/datasources/firestore_video_posts_datasource.dart';
import 'package:toktok/presentation/providers/discover_provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false,
          create: (_) => DiscoverProvider( videosDatasource: FirestoreVideoPostsDatasource() )..loadNextPage()
        ),
      ],
      child: MaterialApp(
        title: 'TokTik',
        debugShowCheckedModeBanner: false,
        // Permite deslizar entre videos con el mouse (web / escritorio), no solo con el dedo
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: PointerDeviceKind.values.toSet(),
        ),
        theme: AppTheme().getTheme(),
        home: const DiscoverScreen()
      ),
    );
  }
}
