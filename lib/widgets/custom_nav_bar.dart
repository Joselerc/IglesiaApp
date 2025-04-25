import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../cubits/navigation_cubit.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../main.dart'; // Importar para acceder a navigationCubit global

class CustomNavBar extends StatelessWidget {
  const CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    return BlocBuilder<NavigationCubit, NavigationState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _getIndex(state),
            onTap: (index) {
              final cubit = navigationCubit;
              if (index == 0) {
                cubit.navigateTo(NavigationState.home);
              } else if (index == 1) {
                cubit.navigateTo(NavigationState.notifications);
              } else if (index == 2) {
                cubit.navigateTo(NavigationState.calendar);
              } else if (index == 3) {
                cubit.navigateTo(NavigationState.videos);
              } else {
                cubit.navigateTo(NavigationState.profile);
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: StreamBuilder<int>(
                  stream: notificationService.getUnreadNotificationsCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Badge(
                      isLabelVisible: count > 0,
                      backgroundColor: AppColors.primary,
                      label: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      child: const Icon(Icons.notifications_outlined),
                    );
                  },
                ),
                activeIcon: const Icon(Icons.notifications),
                label: 'Notifica...',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month_outlined),
                activeIcon: Icon(Icons.calendar_month),
                label: 'Calend...',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.video_library_outlined),
                activeIcon: Icon(Icons.video_library),
                label: 'Vídeos',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            elevation: 0,
          ),
        );
      },
    );
  }

  int _getIndex(NavigationState state) {
    switch (state) {
      case NavigationState.home:
        return 0;
      case NavigationState.notifications:
        return 1;
      case NavigationState.calendar:
        return 2;
      case NavigationState.videos:
        return 3;
      case NavigationState.profile:
        return 4;
      default:
        return 0;
    }
  }
} 