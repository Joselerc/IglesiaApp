import 'package:flutter_bloc/flutter_bloc.dart';

enum NavigationState { home, ministries, profile }

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.home);

  void navigateTo(NavigationState state) => emit(state);
} 