import 'package:flutter/services.dart';
import 'bluetooth_device.dart';
import 'bt_classic_platform_interface.dart';

/// Service for Bluetooth client functionality
class BluetoothClientService {
  static const MethodChannel _channel = MethodChannel('bt_classic');

  // Event callbacks
  Function(BluetoothDevice)? onDeviceFound;
  Function()? onDiscoveryFinished;
  Function(String)? onConnected;
  Function()? onDisconnected;
  Function(String)? onMessageReceived;
  Function(String, Uint8List)? onFileReceived;
  Function(String)? onError;

  BluetoothClientService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onDeviceFound':
          final deviceMap = Map<String, dynamic>.from(call.arguments);
          final device = BluetoothDevice.fromMap(deviceMap);
          onDeviceFound?.call(device);
          break;
        case 'onDiscoveryFinished':
          onDiscoveryFinished?.call();
          break;
        case 'onConnected':
          final address = call.arguments['address'] as String;
          onConnected?.call(address);
          break;
        case 'onDisconnected':
          onDisconnected?.call();
          break;
        case 'onMessageReceived':
          final message = call.arguments['message'] as String;
          onMessageReceived?.call(message);
          break;
        case 'onFileReceived':
          final fileName = call.arguments['fileName'] as String;
          final fileData = call.arguments['fileData'] as Uint8List;
          onFileReceived?.call(fileName, fileData);
          break;
        case 'onError':
          final error = call.arguments['error'] as String;
          onError?.call(error);
          break;
      }
    } catch (e) {
      onError?.call('Error handling method call: $e');
    }
  }

  /// Request Bluetooth permissions from the user
  Future<bool> requestPermissions() async {
    try {
      return await BtClassicPlatform.instance.requestPermissions();
    } catch (e) {
      onError?.call('Failed to request permissions: $e');
      return false;
    }
  }

  /// Check if Bluetooth is enabled on the device
  Future<bool> isBluetoothEnabled() async {
    try {
      return await BtClassicPlatform.instance.isBluetoothEnabled();
    } catch (e) {
      onError?.call('Failed to check Bluetooth status: $e');
      return false;
    }
  }

  /// Start discovering nearby Bluetooth devices
  Future<bool> startDiscovery() async {
    try {
      return await BtClassicPlatform.instance.startDiscovery();
    } catch (e) {
      onError?.call('Failed to start discovery: $e');
      return false;
    }
  }

  /// Stop device discovery
  Future<bool> stopDiscovery() async {
    try {
      return await BtClassicPlatform.instance.stopDiscovery();
    } catch (e) {
      onError?.call('Failed to stop discovery: $e');
      return false;
    }
  }

  /// Get list of previously paired devices
  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await BtClassicPlatform.instance.getPairedDevices();
    } catch (e) {
      onError?.call('Failed to get paired devices: $e');
      return [];
    }
  }

  /// Connect to a Bluetooth device using its MAC address
  Future<bool> connectToDevice(String address) async {
    try {
      return await BtClassicPlatform.instance.connectToDevice(address);
    } catch (e) {
      onError?.call('Failed to connect to device: $e');
      return false;
    }
  }

  /// Send a text message to the connected device
  Future<bool> sendMessage(String message) async {
    try {
      return await BtClassicPlatform.instance.sendMessage(message);
    } catch (e) {
      onError?.call('Failed to send message: $e');
      return false;
    }
  }

  /// Send a file to the connected device
  Future<bool> sendFile(Uint8List fileData, String fileName) async {
    try {
      return await BtClassicPlatform.instance.sendFile(fileData, fileName);
    } catch (e) {
      onError?.call('Failed to send file: $e');
      return false;
    }
  }

  /// Disconnect from the currently connected device
  Future<bool> disconnect() async {
    try {
      return await BtClassicPlatform.instance.disconnect();
    } catch (e) {
      onError?.call('Failed to disconnect: $e');
      return false;
    }
  }

  /// Check if currently connected to a device
  Future<bool> isConnected() async {
    try {
      return await BtClassicPlatform.instance.isConnected();
    } catch (e) {
      return false;
    }
  }
}
