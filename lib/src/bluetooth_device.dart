/// Represents a Bluetooth device with name and address
class BluetoothDevice {
  /// The display name of the Bluetooth device
  final String name;

  /// The MAC address of the Bluetooth device
  final String address;

  const BluetoothDevice({
    required this.name,
    required this.address,
  });

  /// Creates a BluetoothDevice from a map (typically from platform code)
  factory BluetoothDevice.fromMap(Map<String, dynamic> map) {
    return BluetoothDevice(
      name: map['name']?.toString() ?? 'Unknown Device',
      address: map['address']?.toString() ?? '',
    );
  }

  /// Converts the BluetoothDevice to a map for platform communication
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
    };
  }

  @override
  String toString() => '$name ($address)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothDevice && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}
