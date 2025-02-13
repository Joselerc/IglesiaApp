import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/navigation_cubit.dart';
import '../widgets/custom_nav_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return Scaffold(
          body: _buildBody(state),
          bottomNavigationBar: const CustomNavBar(),
        );
      },
    );
  }

  Widget _buildBody(NavigationState state) {
    switch (state) {
      case NavigationState.home:
        return const HomeScreen();
      case NavigationState.profile:
        return const ProfileScreen();
      default:
        return const HomeScreen();
    }
  }
} 