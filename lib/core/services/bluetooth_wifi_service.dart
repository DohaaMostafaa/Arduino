import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';

class BluetoothWifiService {
  static const _targetDeviceName = "Proftel-IOT";
  final NetworkInfo _networkInfo = NetworkInfo();
  BluetoothConnection? connection;


  Future<String?> fetchCurrentSSID() async {
    try {
      await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      var ssid = await _networkInfo.getWifiName();
      return ssid?.replaceAll('"', '');
    } catch (e) {
      return null;
    }
  }

  Future<void> openWifiSettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.WIFI_SETTINGS',
      package: 'com.android.settings',
    );
    await intent.launch();
  }

  Future<void> connectToDevice(
      Function(String) onSuccess,
      Function(String) onError,
      Function(String) onBluetoothOff,
      ) async {
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }

    try {
      final isBluetoothEnabled = await FlutterBluetoothSerial.instance.isEnabled ?? false;
      if (!isBluetoothEnabled) {
        onBluetoothOff('Bluetooth is off. Please enable it.');
        return;
      }

      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final device = devices.firstWhere(
            (d) => d.name == _targetDeviceName,
        orElse: () => throw Exception('Device not found'),
      );
      connection = await BluetoothConnection.toAddress(device.address).timeout(
        const Duration(seconds: 15),
      );
      onSuccess(device.name!);
    } catch (e) {
      onError(e.toString());
    }
  }

  void sendCredentials(String ssid, String password) {
    if (connection?.isConnected == true) {
      final data = '$ssid,$password\n';
      connection!.output.add(Uint8List.fromList(data.codeUnits));
    }
  }

  void disconnect() {
    connection?.dispose();
    connection = null;
  }

  Future<void> checkPermissionsAndFetchSSID(
      Function(String) onPermissionGranted,
      Function(String) onError,
      ) async {
    final locationStatus = await Permission.location.request();
    if (locationStatus.isGranted) {
      final ssid = await fetchCurrentSSID();
      if (ssid != null) {
        onPermissionGranted(ssid);
      } else {
        openWifiSettings();
        onError('Unable to retrieve SSID. Please check Wi-Fi settings.');
      }
    } else {
      onError('Location permission is required to detect Wi-Fi');
    }
  }
}
