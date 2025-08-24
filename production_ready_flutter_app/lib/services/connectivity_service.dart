
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _conn = Connectivity();
  Stream<ConnectivityResult> get onStatusChange => _conn.onConnectivityChanged;
  Future<ConnectivityResult> check() => _conn.checkConnectivity();
}
