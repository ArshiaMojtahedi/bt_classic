# bt_classic

A Flutter plugin for Bluetooth Classic communication with host/server functionality, text messaging, and file transfer capabilities.

## Features

- 🔍 **Device Discovery**: Scan for nearby Bluetooth devices
- 📱 **Client Mode**: Connect to Bluetooth hosts/servers
- 🖥️ **Host Mode**: Create Bluetooth servers and accept connections
- 💬 **Text Messaging**: Send and receive text messages
- 📁 **File Transfer**: Send and receive files between devices
- 🔐 **Permissions**: Automatic permission handling for different Android versions
- 🔄 **Auto-reconnect**: Server automatically accepts new connections

## Platform Support

| Platform | Support |
| -------- | ------- |
| Android  | ✅      |
| iOS      | ❌      |
| Web      | ❌      |
| Windows  | ❌      |
| macOS    | ❌      |
| Linux    | ❌      |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  bt_classic: ^1.0.0
```

## Android Setup

### Permissions

The plugin automatically handles permission requests, but you need to declare them in your `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Bluetooth permissions for API level 30 and below -->
<uses-permission android:name="android.permission.BLUETOOTH"
    android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"
    android:maxSdkVersion="30" />

<!-- Bluetooth permissions for API level 31 and above -->
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />

<!-- Location permissions for device discovery -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Bluetooth hardware feature -->
<uses-feature
    android:name="android.hardware.bluetooth"
    android:required="true" />
```

### Minimum SDK Version

Set the minimum SDK version to 21 in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

## Usage

### Import the package

```dart
import 'package:bt_classic/bt_classic.dart';
```

### Client Mode (Connect to a server)

```dart
class BluetoothClientExample extends StatefulWidget {
  @override
  _BluetoothClientExampleState createState() => _BluetoothClientExampleState();
}

class _BluetoothClientExampleState extends State<BluetoothClientExample> {
  late BluetoothClientService _clientService;
  List<BluetoothDevice> _devices = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  void _initializeClient() {
    _clientService = BluetoothClientService();

    // Set up callbacks
    _clientService.onDeviceFound = (device) {
      setState(() {
        _devices.add(device);
      });
    };

    _clientService.onConnected = (address) {
      setState(() {
        _isConnected = true;
      });
      print('Connected to $address');
    };

    _clientService.onDisconnected = () {
      setState(() {
        _isConnected = false;
      });
      print('Disconnected');
    };

    _clientService.onMessageReceived = (message) {
      print('Received message: $message');
    };

    _clientService.onFileReceived = (fileName, fileData) {
      print('Received file: $fileName (${fileData.length} bytes)');
    };

    _clientService.onError = (error) {
      print('Error: $error');
    };
  }

  Future<void> _requestPermissions() async {
    final granted = await _clientService.requestPermissions();
    if (!granted) {
      print('Permissions denied');
    }
  }

  Future<void> _startDiscovery() async {
    _devices.clear();
    final started = await _clientService.startDiscovery();
    if (started) {
      print('Discovery started');
    }
  }

  Future<void> _connectToDevice(String address) async {
    final connected = await _clientService.connectToDevice(address);
    if (!connected) {
      print('Failed to connect');
    }
  }

  Future<void> _sendMessage(String message) async {
    if (_isConnected) {
      final sent = await _clientService.sendMessage(message);
      if (sent) {
        print('Message sent: $message');
      }
    }
  }

  Future<void> _sendFile(Uint8List fileData, String fileName) async {
    if (_isConnected) {
      final sent = await _clientService.sendFile(fileData, fileName);
      if (sent) {
        print('File sent: $fileName');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Client')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _requestPermissions,
            child: Text('Request Permissions'),
          ),
          ElevatedButton(
            onPressed: _startDiscovery,
            child: Text('Start Discovery'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  onTap: () => _connectToDevice(device.address),
                );
              },
            ),
          ),
          if (_isConnected)
            ElevatedButton(
              onPressed: () => _sendMessage('Hello from client!'),
              child: Text('Send Message'),
            ),
        ],
      ),
    );
  }
}
```

### Host Mode (Create a server)

```dart
class BluetoothHostExample extends StatefulWidget {
  @override
  _BluetoothHostExampleState createState() => _BluetoothHostExampleState();
}

class _BluetoothHostExampleState extends State<BluetoothHostExample> {
  late BluetoothHostService _hostService;
  bool _isServerRunning = false;
  bool _isClientConnected = false;
  String _connectedClientAddress = '';

  @override
  void initState() {
    super.initState();
    _initializeHost();
  }

  void _initializeHost() {
    _hostService = BluetoothHostService();

    // Set up callbacks
    _hostService.onClientConnected = (address) {
      setState(() {
        _isClientConnected = true;
        _connectedClientAddress = address;
      });
      print('Client connected: $address');
    };

    _hostService.onClientDisconnected = () {
      setState(() {
        _isClientConnected = false;
        _connectedClientAddress = '';
      });
      print('Client disconnected');
    };

    _hostService.onMessageReceived = (message) {
      print('Received message: $message');
    };

    _hostService.onFileReceived = (fileName, fileData) {
      print('Received file: $fileName (${fileData.length} bytes)');
    };

    _hostService.onError = (error) {
      print('Error: $error');
    };
  }

  Future<void> _requestPermissions() async {
    final granted = await _hostService.requestPermissions();
    if (!granted) {
      print('Permissions denied');
    }
  }

  Future<void> _makeDiscoverable() async {
    final success = await _hostService.makeDiscoverable();
    if (success) {
      print('Device is now discoverable');
    }
  }

  Future<void> _startServer() async {
    final started = await _hostService.startServer();
    if (started) {
      setState(() {
        _isServerRunning = true;
      });
      print('Server started');
    }
  }

  Future<void> _stopServer() async {
    final stopped = await _hostService.stopServer();
    if (stopped) {
      setState(() {
        _isServerRunning = false;
        _isClientConnected = false;
      });
      print('Server stopped');
    }
  }

  Future<void> _sendMessage(String message) async {
    if (_isClientConnected) {
      final sent = await _hostService.sendMessage(message);
      if (sent) {
        print('Message sent: $message');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Host')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _requestPermissions,
            child: Text('Request Permissions'),
          ),
          ElevatedButton(
            onPressed: _makeDiscoverable,
            child: Text('Make Discoverable'),
          ),
          ElevatedButton(
            onPressed: _isServerRunning ? _stopServer : _startServer,
            child: Text(_isServerRunning ? 'Stop Server' : 'Start Server'),
          ),
          Text('Server Running: $_isServerRunning'),
          Text('Client Connected: $_isClientConnected'),
          if (_isClientConnected)
            Text('Connected Client: $_connectedClientAddress'),
          if (_isClientConnected)
            ElevatedButton(
              onPressed: () => _sendMessage('Hello from host!'),
              child: Text('Send Message'),
            ),
        ],
      ),
    );
  }
}
```

## API Reference

### BluetoothDevice

Represents a Bluetooth device with name and address.

```dart
class BluetoothDevice {
  final String name;
  final String address;

  const BluetoothDevice({
    required this.name,
    required this.address,
  });
}
```

### BluetoothClientService

Service for Bluetooth client functionality.

#### Methods

- `Future<bool> requestPermissions()` - Request Bluetooth permissions
- `Future<bool> isBluetoothEnabled()` - Check if Bluetooth is enabled
- `Future<bool> startDiscovery()` - Start discovering nearby devices
- `Future<bool> stopDiscovery()` - Stop device discovery
- `Future<List<BluetoothDevice>> getPairedDevices()` - Get paired devices
- `Future<bool> connectToDevice(String address)` - Connect to a device
- `Future<bool> sendMessage(String message)` - Send a text message
- `Future<bool> sendFile(Uint8List fileData, String fileName)` - Send a file
- `Future<bool> disconnect()` - Disconnect from device
- `Future<bool> isConnected()` - Check connection status

#### Callbacks

- `Function(BluetoothDevice)? onDeviceFound` - Called when a device is discovered
- `Function()? onDiscoveryFinished` - Called when discovery finishes
- `Function(String)? onConnected` - Called when connected to a device
- `Function()? onDisconnected` - Called when disconnected
- `Function(String)? onMessageReceived` - Called when a message is received
- `Function(String, Uint8List)? onFileReceived` - Called when a file is received
- `Function(String)? onError` - Called when an error occurs

### BluetoothHostService

Service for Bluetooth host/server functionality.

#### Methods

- `Future<bool> requestPermissions()` - Request Bluetooth permissions
- `Future<bool> isBluetoothEnabled()` - Check if Bluetooth is enabled
- `Future<bool> makeDiscoverable()` - Make device discoverable
- `Future<bool> startServer()` - Start the Bluetooth server
- `Future<bool> stopServer()` - Stop the Bluetooth server
- `Future<bool> isServerRunning()` - Check if server is running
- `Future<String> getDeviceName()` - Get device name
- `Future<bool> sendMessage(String message)` - Send a text message
- `Future<bool> sendFile(Uint8List fileData, String fileName)` - Send a file
- `Future<bool> disconnect()` - Disconnect from client
- `Future<bool> isConnected()` - Check connection status

#### Callbacks

- `Function(String)? onClientConnected` - Called when a client connects
- `Function()? onClientDisconnected` - Called when client disconnects
- `Function(String)? onMessageReceived` - Called when a message is received
- `Function(String, Uint8List)? onFileReceived` - Called when a file is received
- `Function(String)? onError` - Called when an error occurs

## Example App

The package includes a comprehensive example app that demonstrates both client and host functionality. To run the example:

```bash
cd example
flutter run
```

The example app features:

- Tabbed interface for client and host modes
- Device discovery and connection
- Real-time messaging
- File transfer capabilities
- Connection status monitoring

## Troubleshooting

### Common Issues

1. **Permissions not granted**: Make sure to call `requestPermissions()` before using other methods.

2. **Connection fails**: Ensure both devices have Bluetooth enabled and are within range.

3. **Discovery doesn't find devices**: Check that location permissions are granted and the target device is discoverable.

4. **File transfer fails**: Large files may take time to transfer. The plugin automatically handles Base64 encoding.

### Debug Tips

- Enable verbose logging to see detailed Bluetooth operations
- Check that both devices support Bluetooth Classic (not just BLE)
- Ensure the target device is not already connected to another device
- Try pairing devices manually through system settings first

## Author

**Arshia Motjahedi**

- Website: [https://motjahedi.me](https://motjahedi.me)
- GitHub: [@arshiamoj](https://github.com/arshiamoj)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request at [https://github.com/arshiamoj/bt_classic](https://github.com/arshiamoj/bt_classic).

## License

This project is licensed under the MIT License - see the LICENSE file for details.
# bt_classic
# bt_classic
