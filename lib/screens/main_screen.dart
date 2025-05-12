import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/navigation_cubit.dart';
import '../widgets/custom_nav_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'videos/videos_screen.dart';
import 'notifications/notifications_screen.dart';
import 'calendar/calendar_screen.dart';
import '../widgets/menu_item.dart';
import './work_invites/work_invites_screen.dart';
import './statistics_services/services_stats_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart'; // Importar para acceder a navigationCubit global
import '../services/auth_service.dart'; // Importar para verificar si es invitado

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Usar el BlocBuilder con la instancia global explícitamente
    return BlocBuilder<NavigationCubit, NavigationState>(
      bloc: navigationCubit, // Especificar el bloc explícitamente
      builder: (context, state) {
        return Scaffold(
          body: _buildBody(state),
          bottomNavigationBar: const CustomNavBar(),
          drawer: _buildDrawer(context),
        );
      },
    );
  }

  Widget _buildBody(NavigationState state) {
    switch (state) {
      case NavigationState.home:
        return const HomeScreen();
      case NavigationState.notifications:
        return const NotificationsScreen();
      case NavigationState.calendar:
        return const CalendarScreen();
      case NavigationState.videos:
        return const VideosScreen();
      case NavigationState.profile:
        return const ProfileScreen();
    }
  }
  
  Widget _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final authService = AuthService();
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Usuário');
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                
                // Si el usuario es anónimo, mostrar "Invitado"
                if (user?.isAnonymous == true || userData?['isGuest'] == true) {
                  return const Text('Convidado');
                }
                
                return Text(userData?['name'] ?? 'Usuário');
              },
            ),
            accountEmail: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // Si el usuario es anónimo, mostrar mensaje informativo
                if (user?.isAnonymous == true) {
                  return const Text('Acesso limitado', style: TextStyle(fontStyle: FontStyle.italic));
                }
                
                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                if (userData?['isGuest'] == true) {
                  return const Text('Acesso limitado', style: TextStyle(fontStyle: FontStyle.italic));
                }
                
                return Text(user?.email ?? '');
              },
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : const AssetImage('assets/default_profile.png') as ImageProvider,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          
          // Opción para crear cuenta si es usuario invitado
          StreamBuilder<bool>(
            stream: Stream.fromFuture(authService.isCurrentUserGuest()),
            builder: (context, isGuestSnapshot) {
              if (isGuestSnapshot.hasData && isGuestSnapshot.data == true) {
                return Column(
                  children: [
                    MenuItem(
                      title: 'Criar conta',
                      icon: Icons.person_add,
                      onTap: () {
                        Navigator.pop(context); // Cerrar el drawer
                        Navigator.pushNamed(context, '/register');
                      },
                    ),
                    const Divider(),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // Invitaciones de trabajo (solo para usuarios registrados)
          StreamBuilder<bool>(
            stream: Stream.fromFuture(authService.isCurrentUserGuest()),
            builder: (context, isGuestSnapshot) {
              // No mostrar esta opción para invitados
              if (isGuestSnapshot.hasData && isGuestSnapshot.data == true) {
                return const SizedBox.shrink();
              }
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('work_invites')
                    .where('userId', isEqualTo: FirebaseFirestore.instance.collection('users').doc(user?.uid))
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  int pendingCount = 0;
                  if (snapshot.hasData) {
                    pendingCount = snapshot.data!.docs.length;
                  }
                  
                  return MenuItem(
                    title: 'Convites de Trabalho',
                    icon: Icons.work,
                    badgeCount: pendingCount,
                    onTap: () {
                      Navigator.pop(context); // Cerrar el drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkInvitesScreen(),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          
          // Estadísticas de Servicios (solo para usuarios con roles específicos)
          StreamBuilder<bool>(
            stream: Stream.fromFuture(authService.isCurrentUserGuest()),
            builder: (context, isGuestSnapshot) {
              // No mostrar esta opción para invitados
              if (isGuestSnapshot.hasData && isGuestSnapshot.data == true) {
                return const SizedBox.shrink();
              }
              
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>?;
                    final userRole = userData?['role'] as String? ?? '';
                    
                    // Solo mostrar esta opción para administradores y pastores
                    if (userRole == 'admin' || userRole == 'pastor') {
                      return MenuItem(
                        title: 'Estadísticas de Servicios',
                        icon: Icons.analytics,
                        onTap: () {
                          Navigator.pop(context); // Cerrar el drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ServicesStatsScreen(),
                            ),
                          );
                        },
                      );
                    }
                  }
                  
                  return const SizedBox.shrink();
                },
              );
            },
          ),
          
          const Divider(),
          
          // Cerrar sesión
          MenuItem(
            title: 'Sair',
            icon: Icons.logout,
            onTap: () async {
              await AuthService().forceSignOut();
              // Usar la instancia global del NavigationCubit
              navigationCubit.navigateTo(NavigationState.home);
              // Redirigir a la pantalla de login
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
    );
  }
} 