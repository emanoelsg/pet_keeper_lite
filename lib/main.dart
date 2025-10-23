// main.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_keeper_lite/features/auth/screens/login_screen.dart';
import 'package:pet_keeper_lite/features/auth/screens/register_screen.dart';
import 'package:pet_keeper_lite/features/pets/screens/add_pet_screen.dart';
import 'package:pet_keeper_lite/features/pets/screens/pet_details_screen.dart';
import 'package:pet_keeper_lite/features/pets/screens/pets_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: PetKeeperApp()));
}

class PetKeeperApp extends ConsumerWidget {
  const PetKeeperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PetKeeper Lite',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppColors.surface,
        ),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isLoggingIn =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isLoggedIn && !isLoggingIn && state.matchedLocation != '/') {
      return '/login';
    }

    if (isLoggedIn && isLoggingIn) {
      return '/pets';
    }

    if (state.matchedLocation == '/') {
      return null;
    }

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/pets', builder: (context, state) => const PetsScreen()),
    GoRoute(
      path: '/pet-details/:petId',
      builder: (context, state) {
        final petId = state.pathParameters['petId']!;
        return PetDetailsScreen(petId: petId);
      },
    ),
    GoRoute(
      path: '/add-pet',
      builder: (context, state) => const AddPetScreen(),
    ),
  ],
);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeFirebaseMessaging();
    _navigate();
  }

  Future<void> _initializeFirebaseMessaging() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
          alert: true,
          badge: true,
          provisional: false,
          sound: true,
        );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permissão de notificação concedida');

      final token = await FirebaseMessaging.instance.getToken();
      debugPrint("FCM Token: $token");

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Recebida mensagem em FOREGROUND!');
        debugPrint('Dados da mensagem: ${message.data}');
        if (message.notification != null) {
          debugPrint(
            'Notificação: ${message.notification?.title} - ${message.notification?.body}',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message.notification?.title ??
                    ': ${message.notification!.body!}',
              ),
              action: SnackBarAction(
                label: 'VER',
                onPressed: () {
                  _handleNotificationNavigation(message.data);
                },
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Usuário clicou na notificação (APP ESTAVA EM BACKGROUND)!');
        debugPrint('Dados da mensagem: ${message.data}');
        _handleNotificationNavigation(message.data);
      });

      FirebaseMessaging.instance.getInitialMessage().then((
        RemoteMessage? message,
      ) {
        if (message != null) {
          debugPrint('App iniciado por notificação (APP ESTAVA TERMINATED)!');
          debugPrint('Dados da mensagem: ${message.data}');
          _handleNotificationNavigation(message.data);
        }
      });
    } else {
      debugPrint(
        'Permissão de notificação negada ou pendente. As notificações não funcionarão.',
      );
    }

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'];
    final petId = data['petId'];

    if (petId != null) {
      context.go('/pet-details/$petId');
    } else if (type == 'custom_message') {}
  }

  Future<void> _navigate() async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (isLoggedIn) {
      context.go('/pets');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            Text(
              'PetKeeper Lite',
              style: AppTextStyles.h1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Gerencie seus pets com sua família',
              style: AppTextStyles.bodyLarge.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
