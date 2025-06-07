import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bt_classic/bt_classic.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BT Classic Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BluetoothDemo(),
    );
  }
}

class BluetoothDemo extends StatefulWidget {
  const BluetoothDemo({super.key});

  @override
  State<BluetoothDemo> createState() => _BluetoothDemoState();
}

class _BluetoothDemoState extends State<BluetoothDemo>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Services
  late BluetoothClientService _clientService;
  late BluetoothHostService _hostService;

  // State
  bool _isBluetoothEnabled = false;
  bool _isServerRunning = false;
  bool _isConnected = false;
  String _deviceName = 'Unknown Device';
  String _connectedAddress = '';

  // UI Controllers
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  final List<BluetoothDevice> _discoveredDevices = [];
  final List<BluetoothDevice> _pairedDevices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeServices();
    _checkBluetoothStatus();
  }

  void _initializeServices() {
    _clientService = BluetoothClientService();
    _hostService = BluetoothHostService();

    // Client callbacks
    _clientService.onDeviceFound = (device) {
      setState(() {
        if (!_discoveredDevices.any((d) => d.address == device.address)) {
          _discoveredDevices.add(device);
        }
      });
    };

    _clientService.onDiscoveryFinished = () {
      _showSnackBar('Discovery finished');
    };

    _clientService.onConnected = (address) {
      setState(() {
        _isConnected = true;
        _connectedAddress = address;
      });
      _showSnackBar('Connected to $address');
    };

    _clientService.onDisconnected = () {
      setState(() {
        _isConnected = false;
        _connectedAddress = '';
      });
      _showSnackBar('Disconnected');
    };

    _clientService.onMessageReceived = (message) {
      setState(() {
        _messages.add('Received: $message');
      });
    };

    _clientService.onFileReceived = (fileName, fileData) {
      setState(() {
        _messages.add('Received file: $fileName (${fileData.length} bytes)');
      });
    };

    _clientService.onError = (error) {
      _showSnackBar('Client Error: $error');
    };

    // Host callbacks
    _hostService.onClientConnected = (address) {
      setState(() {
        _isConnected = true;
        _connectedAddress = address;
      });
      _showSnackBar('Client connected: $address');
    };

    _hostService.onClientDisconnected = () {
      setState(() {
        _isConnected = false;
        _connectedAddress = '';
      });
      _showSnackBar('Client disconnected');
    };

    _hostService.onMessageReceived = (message) {
      setState(() {
        _messages.add('Received: $message');
      });
    };

    _hostService.onFileReceived = (fileName, fileData) {
      setState(() {
        _messages.add('Received file: $fileName (${fileData.length} bytes)');
      });
    };

    _hostService.onError = (error) {
      _showSnackBar('Host Error: $error');
    };
  }

  Future<void> _checkBluetoothStatus() async {
    final isEnabled = await _clientService.isBluetoothEnabled();
    final deviceName = await _hostService.getDeviceName();

    setState(() {
      _isBluetoothEnabled = isEnabled;
      _deviceName = deviceName;
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await _clientService.requestPermissions();
    if (granted) {
      _showSnackBar('Permissions granted');
      _checkBluetoothStatus();
    } else {
      _showSnackBar('Permissions denied');
    }
  }

  Future<void> _startDiscovery() async {
    _discoveredDevices.clear();
    final started = await _clientService.startDiscovery();
    if (started) {
      _showSnackBar('Discovery started');
    }
  }

  Future<void> _getPairedDevices() async {
    final devices = await _clientService.getPairedDevices();
    setState(() {
      _pairedDevices.clear();
      _pairedDevices.addAll(devices);
    });
  }

  Future<void> _connectToDevice(String address) async {
    final connected = await _clientService.connectToDevice(address);
    if (!connected) {
      _showSnackBar('Failed to connect');
    }
  }

  Future<void> _makeDiscoverable() async {
    final success = await _hostService.makeDiscoverable();
    if (success) {
      _showSnackBar('Device is now discoverable');
    }
  }

  Future<void> _startServer() async {
    final started = await _hostService.startServer();
    if (started) {
      setState(() {
        _isServerRunning = true;
      });
      _showSnackBar('Server started');
    }
  }

  Future<void> _stopServer() async {
    final stopped = await _hostService.stopServer();
    if (stopped) {
      setState(() {
        _isServerRunning = false;
      });
      _showSnackBar('Server stopped');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final sent = _tabController.index == 0
        ? await _clientService.sendMessage(message)
        : await _hostService.sendMessage(message);

    if (sent) {
      setState(() {
        _messages.add('Sent: $message');
        _messageController.clear();
      });
    } else {
      _showSnackBar('Failed to send message');
    }
  }

  Future<void> _sendTestFile() async {
    // Create a test file
    final testData =
        utf8.encode('This is a test file content from bt_classic package!');

    final sent = _tabController.index == 0
        ? await _clientService.sendFile(
            Uint8List.fromList(testData), 'test.txt')
        : await _hostService.sendFile(Uint8List.fromList(testData), 'test.txt');

    if (sent) {
      setState(() {
        _messages.add('Sent file: test.txt (${testData.length} bytes)');
      });
    } else {
      _showSnackBar('Failed to send file');
    }
  }

  Future<void> _disconnect() async {
    if (_tabController.index == 0) {
      await _clientService.disconnect();
    } else {
      await _hostService.disconnect();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BT Classic Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Client', icon: Icon(Icons.smartphone)),
            Tab(text: 'Host', icon: Icon(Icons.router)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.all(16),
            color: _isBluetoothEnabled
                ? Colors.green.shade100
                : Colors.red.shade100,
            child: Row(
              children: [
                Icon(
                  _isBluetoothEnabled
                      ? Icons.bluetooth
                      : Icons.bluetooth_disabled,
                  color: _isBluetoothEnabled ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Device: $_deviceName | ${_isBluetoothEnabled ? 'Enabled' : 'Disabled'} | ${_isConnected ? 'Connected to $_connectedAddress' : 'Not connected'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClientTab(),
                _buildHostTab(),
              ],
            ),
          ),

          // Messages section
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      const Text('Messages',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _messages.clear()),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        dense: true,
                        title: Text(_messages[index]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Message input
          if (_isConnected)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _sendTestFile,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClientTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _requestPermissions,
            child: const Text('Request Permissions'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _startDiscovery,
                  child: const Text('Start Discovery'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _getPairedDevices,
                  child: const Text('Get Paired'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Discovered Devices:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: _discoveredDevices.length + _pairedDevices.length,
              itemBuilder: (context, index) {
                BluetoothDevice device;
                bool isPaired = false;

                if (index < _pairedDevices.length) {
                  device = _pairedDevices[index];
                  isPaired = true;
                } else {
                  device = _discoveredDevices[index - _pairedDevices.length];
                }

                return ListTile(
                  leading: Icon(
                    isPaired ? Icons.bluetooth_connected : Icons.bluetooth,
                    color: isPaired ? Colors.blue : Colors.grey,
                  ),
                  title: Text(device.name),
                  subtitle: Text(device.address),
                  trailing: ElevatedButton(
                    onPressed: () => _connectToDevice(device.address),
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
          ),
          if (_isConnected)
            ElevatedButton(
              onPressed: _disconnect,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disconnect'),
            ),
        ],
      ),
    );
  }

  Widget _buildHostTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: _requestPermissions,
            child: const Text('Request Permissions'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _makeDiscoverable,
            child: const Text('Make Discoverable'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isServerRunning ? _stopServer : _startServer,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isServerRunning ? Colors.red : Colors.green,
            ),
            child: Text(_isServerRunning ? 'Stop Server' : 'Start Server'),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Server Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Running: ${_isServerRunning ? 'Yes' : 'No'}'),
                  Text('Connected: ${_isConnected ? 'Yes' : 'No'}'),
                  if (_isConnected) Text('Client: $_connectedAddress'),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (_isConnected)
            ElevatedButton(
              onPressed: _disconnect,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Disconnect Client'),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
