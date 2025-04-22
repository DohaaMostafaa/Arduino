import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:usb_serial/usb_serial.dart';

class GpsReaderPage extends StatefulWidget {
  const GpsReaderPage({super.key});

  @override
  _GpsReaderPageState createState() => _GpsReaderPageState();
}

class _GpsReaderPageState extends State<GpsReaderPage> {
  UsbPort? _port;
  String gpsData = "";
  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    _connectToGps();
  }

  Future<void> _connectToGps() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) {
      setState(() {
        gpsData = "No USB devices found.";
      });
      return;
    }

    UsbDevice device = devices.first;
    UsbPort? port = await device.create();
    if (port == null) {
      setState(() {
        gpsData = "Failed to open port.";
      });
      return;
    }

    bool openResult = await port.open();
    if (!openResult) {
      setState(() {
        gpsData = "Failed to open connection.";
      });
      return;
    }

    await port.setDTR(true);
    await port.setRTS(true);
    await port.setPortParameters(115200, UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    port.inputStream?.listen((Uint8List event) {
      String data = String.fromCharCodes(event);
      setState(() {
        gpsData += data;
      });

      if (data.contains("\$GPGGA")) {
        final lines = data.split("\r\n");
        for (var line in lines) {
          if (line.startsWith("\$GPGGA")) {
          }
        }
      }
    });

    _port = port;
  }

  void _parseGPGGA(String line) {
    // Example parsing logic
    List<String> parts = line.split(',');
    if (parts.length > 5) {
      final lat = _convertToDecimal(parts[2], parts[3]);
      final lon = _convertToDecimal(parts[4], parts[5]);
      setState(() {
        gpsData = "Latitude: $lat\nLongitude: $lon";
        print(gpsData);
      });
    }
  }

  double _convertToDecimal(String raw, String direction) {
    if (raw.isEmpty) return 0.0;
    double d = double.parse(raw.substring(0, 2));
    double m = double.parse(raw.substring(2)) / 60;
    double result = d + m;
    return (direction == "S" || direction == "W") ? -result : result;
  }


  @override
  void dispose() {
    _port?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("USB GPS")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _connectToGps(),
                child: const Text('Connect to GPS'),
              ),
              const SizedBox(height: 20),
              Text('Status: ${gpsData}'),
            ],
          ),
        ),
      ),
    );
  }
}
