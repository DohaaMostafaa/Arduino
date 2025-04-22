
import 'package:flutter/material.dart';
import 'gbs.dart';

void main() {
  runApp( MaterialApp(home: GpsReaderPage()));
}
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:usb_serial/usb_serial.dart';
// import 'dart:typed_data';
//
// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => GpsService()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'GPS Reader',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: const GpsScreen(),
//     );
//   }
// }
//
// class GpsScreen extends StatelessWidget {
//   const GpsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final gpsService = Provider.of<GpsService>(context);
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('NEO-6M GPS Reader')),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () => gpsService.connectToDevice(),
//               child: const Text('Connect to GPS'),
//             ),
//             const SizedBox(height: 20),
//             Text('Status: ${gpsService.connectionStatus}'),
//             const SizedBox(height: 30),
//             Text('Latitude: ${gpsService.latitude ?? "N/A"}'),
//             Text('Longitude: ${gpsService.longitude ?? "N/A"}'),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class GpsService extends ChangeNotifier {
//   UsbPort? _port;
//   String connectionStatus = "Disconnected";
//   String connectionError = "0";
//   double? latitude;
//   double? longitude;
//
//   Future<void> connectToDevice() async {
//     try {
//       List<UsbDevice> devices = await UsbSerial.listDevices();
//       if (devices.isEmpty) {
//         connectionStatus = "No devices found";
//         connectionError = "1";
//         notifyListeners();
//         return;
//       }
//
//       UsbDevice? device;
//       for (UsbDevice d in devices) {
//         if (d.deviceName.contains("NEO-6M")) {
//           device = d;
//           break;
//         }
//       }
//
//       if (device == null) {
//         connectionStatus = "GPS device not found";
//         connectionError = "2";
//         notifyListeners();
//         return;
//       }
//
//       _port = await device.create();
//       await _port?.open();
//       await _port?.setDTR(true);
//       await _port?.setRTS(true);
//       await _port?.setPortParameters(112500, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
//
//       connectionStatus = "Connected";
//       connectionError = "4";
//
//       notifyListeners();
//
//       _port?.inputStream?.listen(_handleData);
//     } catch (e) {
//       connectionStatus = "Connection error: $e";
//       connectionError = "3";
//
//       notifyListeners();
//     }
//   }
//
//   void _handleData(Uint8List data) {
//     final rawData = String.fromCharCodes(data);
//     final sentences = rawData.split('\r\n');
//
//     for (String sentence in sentences) {
//       if (sentence.startsWith('\$GPRMC')) {
//         _parseGPRMC(sentence);
//       }
//     }
//   }
//
//   void _parseGPRMC(String sentence) {
//     final parts = sentence.split(',');
//     if (parts.length < 7 || parts[2] != 'A') return;
//
//     try {
//       latitude = _convertToDecimal(parts[3], parts[4]);
//       longitude = _convertToDecimal(parts[5], parts[6]);
//       notifyListeners();
//     } catch (e) {
//       print("Error parsing GPS data: $e");
//     }
//   }
//
//   double _convertToDecimal(String value, String direction) {
//     final deg = double.parse(value.substring(0, value.indexOf('.') - 2));
//     final min = double.parse(value.substring(value.indexOf('.') - 2));
//     final decimal = deg + (min / 60);
//     return direction == 'S' || direction == 'W' ? -decimal : decimal;
//   }
//
//   @override
//   void dispose() {
//     _port?.close();
//     super.dispose();
//   }
// }