import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../../../core/services/bluetooth_wifi_service.dart';


class WifiSenderPage extends StatefulWidget {
  const WifiSenderPage({super.key});
  @override
  State<WifiSenderPage> createState() => _WifiSenderPageState();
}

class _WifiSenderPageState extends State<WifiSenderPage> with WidgetsBindingObserver {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final BluetoothWifiService _bluetoothWifiService = BluetoothWifiService();

  bool _obscurePassword = true;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndFetchSSID();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bluetoothWifiService.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndFetchSSID();
    }
  }

  Future<void> _checkPermissionsAndFetchSSID() async {
    setState(() => _isCheckingPermissions = true);
    try {
      await _bluetoothWifiService.checkPermissionsAndFetchSSID(
            (ssid) {setState(() => _ssidController.text = ssid);
        },
            (error) {
          _showSnackBar(error);
        },
      );
    } catch (e) {
      debugPrint('Permission check error: $e');
      _showSnackBar('Error checking permissions.');
    } finally {
      setState(() => _isCheckingPermissions = false);
    }
  }

  Future<bool> isWifiConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi;
  }

  void _connectToDevice() async {
    if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Please enter both SSID and Password');
      return;
    }

    // bool connectedToWifi = await isWifiConnected();
    // if (!connectedToWifi) {
    //   _showSnackBarWithAction('Not connected to Wi-Fi', 'Settings', () async {
    //     await _bluetoothWifiService.openWifiSettings();
    //   });
    //   return;
    // }


    setState(() => _isConnecting = true);

    _bluetoothWifiService.connectToDevice(
          (deviceName) {
        setState(() {
          _isConnected = true;
          _isConnecting = false;
        });
        _showSnackBar('Connected to $deviceName');
      },
          (error) {
        setState(() => _isConnecting = false);
        _handleConnectionError(error);
      },
          (message) {
        _showSnackBarWithAction(message, 'ENABLE', () async {
          await FlutterBluetoothSerial.instance.requestEnable();
        });
      },
    );
  }


  void _sendCredentials() {
    if (_bluetoothWifiService.connection?.isConnected == true) {
      _bluetoothWifiService.sendCredentials(
        _ssidController.text, _passwordController.text,
      );
      _showSnackBar('Sent WiFi credentials.');
    } else {
      _showSnackBar('Not connected to ESP32.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSnackBarWithAction(String message, String actionText, VoidCallback onAction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: actionText,
          onPressed: onAction,
        ),
      ),
    );
  }

  void _handleConnectionError(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('Timeout')) {
      _showSnackBar('Connection timed out. Please try again.');
    } else if (errorString.contains('Socket closed') || errorString.contains('read failed')) {
      _showSnackBar('Connection error. The socket might have been closed.');
    } else if (errorString.contains('BluetoothPermissionDenied')) {
      _showSnackBar('Bluetooth permissions are required. Please grant them.');
    } else {
      _showSnackBar('An unexpected error occurred.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text( 'Send WiFi to ESP32', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
              const SizedBox(height: 20),
              TextField( controller: _ssidController, decoration: const InputDecoration(labelText: 'WiFi SSID'),),
              const SizedBox(height: 16),
              TextField( controller: _passwordController, decoration: InputDecoration(labelText: 'WiFi Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20,),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    child: ElevatedButton( onPressed: _isConnecting ? null : _connectToDevice,
                      child: Text(_isConnected ? 'Connected' : 'Connect'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: ElevatedButton( onPressed: _isConnected ? _sendCredentials : null,
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

