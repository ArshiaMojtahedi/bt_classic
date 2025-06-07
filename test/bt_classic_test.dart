import 'package:flutter_test/flutter_test.dart';
import 'package:bt_classic/bt_classic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BT Classic', () {
    test('BluetoothDevice creation', () {
      const device = BluetoothDevice(
        name: 'Test Device',
        address: '00:11:22:33:44:55',
      );

      expect(device.name, 'Test Device');
      expect(device.address, '00:11:22:33:44:55');
      expect(device.toString(), 'Test Device (00:11:22:33:44:55)');
    });

    test('BluetoothDevice equality', () {
      const device1 = BluetoothDevice(
        name: 'Device 1',
        address: '00:11:22:33:44:55',
      );

      const device2 = BluetoothDevice(
        name: 'Device 2',
        address: '00:11:22:33:44:55',
      );

      const device3 = BluetoothDevice(
        name: 'Device 1',
        address: '00:11:22:33:44:66',
      );

      expect(device1, device2); // Same address
      expect(device1, isNot(device3)); // Different address
    });

    test('BluetoothDevice fromMap', () {
      final device = BluetoothDevice.fromMap({
        'name': 'Test Device',
        'address': '00:11:22:33:44:55',
      });

      expect(device.name, 'Test Device');
      expect(device.address, '00:11:22:33:44:55');
    });

    test('BluetoothDevice toMap', () {
      const device = BluetoothDevice(
        name: 'Test Device',
        address: '00:11:22:33:44:55',
      );

      final map = device.toMap();
      expect(map['name'], 'Test Device');
      expect(map['address'], '00:11:22:33:44:55');
    });

    test('BluetoothClientService instantiation', () {
      final service = BluetoothClientService();
      expect(service, isNotNull);
    });

    test('BluetoothHostService instantiation', () {
      final service = BluetoothHostService();
      expect(service, isNotNull);
    });
  });
}
