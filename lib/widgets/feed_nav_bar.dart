import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String groupId;
  final List<DocumentReference> groupAdmin;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.groupId,
    required this.groupAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box_outlined),
          label: 'Crear',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}