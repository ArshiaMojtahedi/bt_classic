import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/services.dart';
import 'bluetooth_device.dart';

/// The interface that platform implementations of bt_classic must extend.
abstract class BtClassicPlatform extends PlatformInterface {
  /// Constructs a BtClassicPlatform.
  BtClassicPlatform() : super(token: _token);

  static final Object _token = Object();

  static BtClassicPlatform _instance = BtClassicMethodChannel();

  /// The default instance of [BtClassicPlatform] to use.
  static BtClassicPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BtClassicPlatform] when
  /// they register themselves.
  static set instance(BtClassicPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Client methods
  Future<bool> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  Future<bool> isBluetoothEnabled() {
    throw UnimplementedError('isBluetoothEnabled() has not been implemented.');
  }

  Future<bool> startDiscovery() {
    throw UnimplementedError('startDiscovery() has not been implemented.');
  }

  Future<bool> stopDiscovery() {
    throw UnimplementedError('stopDiscovery() has not been implemented.');
  }

  Future<List<BluetoothDevice>> getPairedDevices() {
    throw UnimplementedError('getPairedDevices() has not been implemented.');
  }

  Future<bool> connectToDevice(String address) {
    throw UnimplementedError('connectToDevice() has not been implemented.');
  }

  Future<bool> sendMessage(String message) {
    throw UnimplementedError('sendMessage() has not been implemented.');
  }

  Future<bool> sendFile(Uint8List fileData, String fileName) {
    throw UnimplementedError('sendFile() has not been implemented.');
  }

  Future<bool> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  Future<bool> isConnected() {
    throw UnimplementedError('isConnected() has not been implemented.');
  }

  // Host methods
  Future<bool> makeDiscoverable() {
    throw UnimplementedError('makeDiscoverable() has not been implemented.');
  }

  Future<bool> startServer() {
    throw UnimplementedError('startServer() has not been implemented.');
  }

  Future<bool> stopServer() {
    throw UnimplementedError('stopServer() has not been implemented.');
  }

  Future<bool> isServerRunning() {
    throw UnimplementedError('isServerRunning() has not been implemented.');
  }

  Future<String> getDeviceName() {
    throw UnimplementedError('getDeviceName() has not been implemented.');
  }
}

/// Method channel implementation of [BtClassicPlatform].
class BtClassicMethodChannel extends BtClassicPlatform {
  static const MethodChannel _channel = MethodChannel('bt_classic');

  @override
  Future<bool> requestPermissions() async {
    final result = await _channel.invokeMethod<bool>('requestPermissions');
    return result ?? false;
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    final result = await _channel.invokeMethod<bool>('isBluetoothEnabled');
    return result ?? false;
  }

  @override
  Future<bool> startDiscovery() async {
    final result = await _channel.invokeMethod<bool>('startDiscovery');
    return result ?? false;
  }

  @override
  Future<bool> stopDiscovery() async {
    final result = await _channel.invokeMethod<bool>('stopDiscovery');
    return result ?? false;
  }

  @override
  Future<List<BluetoothDevice>> getPairedDevices() async {
    final result = await _channel.invokeMethod<List>('getPairedDevices');
    if (result == null) return [];

    return result
        .cast<Map<Object?, Object?>>()
        .map((map) => BluetoothDevice.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  @override
  Future<bool> connectToDevice(String address) async {
    final result = await _channel.invokeMethod<bool>('connectToDevice', {
      'address': address,
    });
    return result ?? false;
  }

  @override
  Future<bool> sendMessage(String message) async {
    final result = await _channel.invokeMethod<bool>('sendMessage', {
      'message': message,
    });
    return result ?? false;
  }

  @override
  Future<bool> sendFile(Uint8List fileData, String fileName) async {
    final result = await _channel.invokeMethod<bool>('sendFile', {
      'fileData': fileData,
      'fileName': fileName,
    });
    return result ?? false;
  }

  @override
  Future<bool> disconnect() async {
    final result = await _channel.invokeMethod<bool>('disconnect');
    return result ?? false;
  }

  @override
  Future<bool> isConnected() async {
    final result = await _channel.invokeMethod<bool>('isConnected');
    return result ?? false;
  }

  @override
  Future<bool> makeDiscoverable() async {
    final result = await _channel.invokeMethod<bool>('makeDiscoverable');
    return result ?? false;
  }

  @override
  Future<bool> startServer() async {
    final result = await _channel.invokeMethod<bool>('startServer');
    return result ?? false;
  }

  @override
  Future<bool> stopServer() async {
    final result = await _channel.invokeMethod<bool>('stopServer');
    return result ?? false;
  }

  @override
  Future<bool> isServerRunning() async {
    final result = await _channel.invokeMethod<bool>('isServerRunning');
    return result ?? false;
  }

  @override
  Future<String> getDeviceName() async {
    final result = await _channel.invokeMethod<String>('getDeviceName');
    return result ?? 'Unknown Device';
  }
}
