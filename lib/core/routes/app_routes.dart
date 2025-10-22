// core/routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:pet_keeper_lite/features/auth/screens/register_screen.dart';
import 'package:pet_keeper_lite/features/pets/screens/add_pet_screen.dart';
import 'package:pet_keeper_lite/features/pets/screens/pet_details_screen.dart';
import 'package:pet_keeper_lite/features/pets/screens/pets_screen.dart';
import 'package:pet_keeper_lite/main.dart';

import '../../features/auth/screens/login_screen.dart';

class AppRoutes {
  // Rotas principais
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String pets = '/pets';
  static const String petDetails = '/pet-details';
  static const String addPet = '/add-pet';
  static const String editPet = '/edit-pet';
  static const String addTask = '/add-task';
  static const String editTask = '/edit-task';
  static const String profile = '/profile';
  static const String familySettings = '/family-settings';
  
  // Gerador de rotas
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      
      case pets:
        return MaterialPageRoute(
          builder: (_) => const PetsScreen(),
          settings: settings,
        );
      
      case petDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PetDetailsScreen(petId: args['petId']),
          settings: settings,
        );
      
      case addPet:
        return MaterialPageRoute(
          builder: (_) => const AddPetScreen(),
          settings: settings,
        );
      
      case editPet:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EditPetScreen(petId: args['petId']),
          settings: settings,
        );
      
      case addTask:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AddTaskScreen(petId: args['petId']),
          settings: settings,
        );
      
      case editTask:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EditTaskScreen(taskId: args['taskId']),
          settings: settings,
        );
      
      case profile:
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
          settings: settings,
        );
      
      case familySettings:
        return MaterialPageRoute(
          builder: (_) => const FamilySettingsScreen(),
          settings: settings,
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundScreen(),
          settings: settings,
        );
    }
  }
}

// Placeholder screens - serão implementadas nas features






class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Home Screen'),
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
      body: Center(
        child: Text('Edit Pet Screen - Pet ID: $petId'),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  final String petId;
  
  const AddTaskScreen({super.key, required this.petId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Add Task Screen - Pet ID: $petId'),
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
      body: Center(
        child: Text('Edit Task Screen - Task ID: $taskId'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}

class FamilySettingsScreen extends StatelessWidget {
  const FamilySettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Family Settings Screen'),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Página não encontrada'),
      ),
    );
  }
}
