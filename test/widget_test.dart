import 'package:flutter_test/flutter_test.dart';
import 'package:switcher_gps/services/app_update_service.dart';

void main() {
  test('normaliza versionCode split-per-abi', () {
    expect(AppUpdateService.logicalVersionCode(1), 1);
    expect(AppUpdateService.logicalVersionCode(2001), 1);
    expect(AppUpdateService.logicalVersionCode(9001), 1);
  });
}
