import 'package:flutter/foundation.dart';

class AppEvents {
  static final ValueNotifier<int> refreshKaryawanNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> refreshCutiNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<int> refreshAbsensiNotifier = ValueNotifier<int>(0);

  static void triggerRefreshKaryawan() {
    refreshKaryawanNotifier.value++;
  }

  static void triggerRefreshCuti() {
    refreshCutiNotifier.value++;
  }

  static void triggerRefreshAbsensi() {
    refreshAbsensiNotifier.value++;
  }
}
