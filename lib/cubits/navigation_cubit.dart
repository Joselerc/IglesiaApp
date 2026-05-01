import 'package:flutter_bloc/flutter_bloc.dart';

enum NavigationState { home, profile, videos, notifications, calendar }

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(NavigationState.home);
  NavigationState? _pendingReturnState;

  void navigateTo(NavigationState state) {
    if (state == this.state) return;
    emit(state);
  }

  void setPendingReturn(NavigationState state) {
    _pendingReturnState = state;
  }

  NavigationState? consumePendingReturn() {
    final pending = _pendingReturnState;
    _pendingReturnState = null;
    return pending;
  }
} 
