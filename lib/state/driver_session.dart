import 'package:flutter/foundation.dart';

/// Tracks which driver is "logged in" to the mobile app, plus the
/// online/offline connectivity toggle used to demo offline-first capture.
class DriverSession extends ChangeNotifier {
  String driverId;
  bool isOnline = true;

  DriverSession(this.driverId);

  void switchDriver(String id) {
    driverId = id;
    notifyListeners();
  }

  void setOnline(bool value) {
    isOnline = value;
    notifyListeners();
  }
}
