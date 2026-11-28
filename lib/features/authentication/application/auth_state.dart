import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/token_storage.dart';

final authenticatedProvider = NotifierProvider<AuthenticationState, bool>(
  AuthenticationState.new,
);

class AuthenticationState extends Notifier<bool> {
  @override
  bool build() => false;

  void authenticated() => state = true;

  Future<void> clear() async {
    state = false;
    await ref.read(tokenStorageProvider).clear();
  }
}
