## 1.0.1

- 🐛 **Fixed file transfer encoding issues**: Changed from `Base64.DEFAULT` to `Base64.NO_WRAP` to prevent internal newlines in encoded data that were interfering with message parsing
- 🐛 **Improved file processing reliability**: Added better error handling and fallback for malformed file messages
- 🔧 **Enhanced message protocol**: Text messages already included proper newline terminators, ensuring reliable message detection
- 📝 **Better error logging**: Added more detailed logging for debugging file transfer issues

## 1.0.0

- Initial release of bt_classic package
- ✅ Bluetooth Classic communication support for Android
- ✅ Client mode: Connect to Bluetooth hosts/servers
- ✅ Host mode: Create Bluetooth servers and accept connections
- ✅ Device discovery and pairing
- ✅ Text messaging between devices
- ✅ File transfer capabilities with automatic Base64 encoding
- ✅ Automatic permission handling for Android API levels 21-34
- ✅ Auto-reconnect functionality for server mode
- ✅ Comprehensive example app with tabbed interface
- ✅ Complete API documentation and usage examples
