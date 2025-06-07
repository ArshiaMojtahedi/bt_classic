import 'package:flutter/services.dart';
import 'bt_classic_platform_interface.dart';

/// Service for Bluetooth host/server functionality
class BluetoothHostService {
  static const MethodChannel _channel = MethodChannel('bt_classic');

  // Event callbacks
  Function(String)? onClientConnected;
  Function()? onClientDisconnected;
  Function(String)? onMessageReceived;
  Function(String, Uint8List)? onFileReceived;
  Function(String)? onError;

  BluetoothHostService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onClientConnected':
          final address = call.arguments['address'] as String;
          onClientConnected?.call(address);
          break;
        case 'onClientDisconnected':
          onClientDisconnected?.call();
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

  /// Make the device discoverable to other Bluetooth devices
  Future<bool> makeDiscoverable() async {
    try {
      return await BtClassicPlatform.instance.makeDiscoverable();
    } catch (e) {
      onError?.call('Failed to make device discoverable: $e');
      return false;
    }
  }

  /// Start the Bluetooth server to accept incoming connections
  Future<bool> startServer() async {
    try {
      return await BtClassicPlatform.instance.startServer();
    } catch (e) {
      onError?.call('Failed to start server: $e');
      return false;
    }
  }

  /// Stop the Bluetooth server
  Future<bool> stopServer() async {
    try {
      return await BtClassicPlatform.instance.stopServer();
    } catch (e) {
      onError?.call('Failed to stop server: $e');
      return false;
    }
  }

  /// Check if the server is currently running
  Future<bool> isServerRunning() async {
    try {
      return await BtClassicPlatform.instance.isServerRunning();
    } catch (e) {
      return false;
    }
  }

  /// Get the name of this device
  Future<String> getDeviceName() async {
    try {
      return await BtClassicPlatform.instance.getDeviceName();
    } catch (e) {
      onError?.call('Failed to get device name: $e');
      return 'Unknown Device';
    }
  }

  /// Send a text message to the connected client
  Future<bool> sendMessage(String message) async {
    try {
      return await BtClassicPlatform.instance.sendMessage(message);
    } catch (e) {
      onError?.call('Failed to send message: $e');
      return false;
    }
  }

  /// Send a file to the connected client
  Future<bool> sendFile(Uint8List fileData, String fileName) async {
    try {
      return await BtClassicPlatform.instance.sendFile(fileData, fileName);
    } catch (e) {
      onError?.call('Failed to send file: $e');
      return false;
    }
  }

  /// Disconnect from the currently connected client
  Future<bool> disconnect() async {
    try {
      return await BtClassicPlatform.instance.disconnect();
    } catch (e) {
      onError?.call('Failed to disconnect: $e');
      return false;
    }
  }

  /// Check if currently connected to a client
  Future<bool> isConnected() async {
    try {
      return await BtClassicPlatform.instance.isConnected();
    } catch (e) {
      return false;
    }
  }
}
