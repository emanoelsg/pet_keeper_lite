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
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_text_styles.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    // Redirecionamento baseado no estado de autenticação será implementado aqui
    return null; // Não redireciona, permite navegação normal
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
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
    GoRoute(
      path: '/edit-pet/:petId',
      builder: (context, state) {
        final petId = state.pathParameters['petId']!;
        return EditPetScreen(petId: petId);
      },
    ),
    GoRoute(
      path: '/add-task/:petId',
      builder: (context, state) {
        final petId = state.pathParameters['petId']!;
        return AddTaskScreen(petId: petId);
      },
    ),
    GoRoute(
      path: '/edit-task/:taskId',
      builder: (context, state) {
        final taskId = state.pathParameters['taskId']!;
        return EditTaskScreen(taskId: taskId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/family-settings',
      builder: (context, state) => const FamilySettingsScreen(),
    ),
  ],
);

// Placeholder screens - serão implementadas nas próximas etapas
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (isLoggedIn) {
      context.go('/home');
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetKeeper Lite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: const Center(child: Text('Tela inicial - Em desenvolvimento')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/add-pet'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditPetScreen extends StatelessWidget {
  final String petId;

  const EditPetScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Pet')),
      body: Center(child: Text('Editar pet $petId - Em desenvolvimento')),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  final String petId;

  const AddTaskScreen({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Tarefa')),
      body: Center(
        child: Text('Adicionar tarefa para pet $petId - Em desenvolvimento'),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final String taskId;

  const EditTaskScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Tarefa')),
      body: Center(child: Text('Editar tarefa $taskId - Em desenvolvimento')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: const Center(child: Text('Perfil do usuário - Em desenvolvimento')),
    );
  }
}

class FamilySettingsScreen extends StatelessWidget {
  const FamilySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações da Família')),
      body: const Center(
        child: Text('Configurações da família - Em desenvolvimento'),
      ),
    );
  }
}
