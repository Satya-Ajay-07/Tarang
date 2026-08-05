import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus { online, offline }

class ConnectivityService extends StateNotifier<ConnectionStatus> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  ConnectivityService() : super(ConnectionStatus.online) {
    _init();
  }

  Future<void> _init() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      state = ConnectionStatus.offline;
    } else {
      state = ConnectionStatus.online;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityService, ConnectionStatus>((ref) {
  return ConnectivityService();
});
