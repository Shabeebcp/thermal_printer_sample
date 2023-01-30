import 'dart:math';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pfriteeer/PrintSamples/esc_blutooth_model.dart';
import 'package:pfriteeer/PrintSamples/normal_method.dart';

class PrinterScreen extends StatefulWidget {
  PrinterScreen({Key? key}) : super(key: key);

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  @override
  void initState() {
    requestLocationPermission();

    super.initState();
  }

  BlueThermalPrinter blue = BlueThermalPrinter.instance;
  List<BluetoothDevice>? _devices = [];
  BluetoothDevice? device;
  bool? _connected = false;

  Future<void> initPrinter() async {
    bool? isConnected = await blue.isConnected;
    try {
      _devices = await blue.getBondedDevices();
    } catch (e) {
      print(e.toString());
    }

    blue.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            print("bluetooth device state: CONNECTED");
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            print("bluetooth device state: DISCONNECTED!!!!!!!");
          });
          break;
      }
    });

    if (!mounted) return;
    if (isConnected!) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Blue Thermal Printer'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(width: 10),
                  const Text(
                    'Device:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: DropdownButton(
                      items: _getDeviceItems(),
                      onChanged: (BluetoothDevice? value) =>
                          setState(() => device = value),
                      value: device,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(primary: Colors.brown),
                    onPressed: () {
                      initPrinter();
                    },
                    child: const Text(
                      'Refresh',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        primary: _connected! ? Colors.red : Colors.green),
                    onPressed: _connected! ? _disconnect : _connect,
                    child: Text(
                      _connected! ? 'Disconnect' : 'Connect',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.brown),
                  onPressed: () {
                    NormalPrint().sample();
                  },
                  child: const Text('Normal PRINT TEST',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 10.0, right: 10.0, top: 50),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.brown),
                  onPressed: () async {
                    var paper = PaperSize.mm80;
                    var profile = await CapabilityProfile.load();
                    var bytes =
                        ESCPOSBluetoothModel().demoReceipt(paper, profile);
                    await blue.writeBytes(Uint8List.fromList(bytes));
                  },
                  child: const Text('Esc_pos_bluetooth_PRINT TEST',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices!.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devices!.forEach((x) {
        items.add(DropdownMenuItem(
          child: Text(x.name ?? ""),
          value: x,
        ));
      });
    }
    return items;
  }

  void _connect() {
    if (device != null) {
      blue.isConnected.then((isConnected) {
        if (isConnected == false) {
          blue.connect(device!).catchError((error) {
            setState(() => _connected = false);
          });
          setState(() => _connected = true);
        }
      });
    } else {
      show('No device selected.');
    }
  }

  void _disconnect() {
    blue.disconnect();
    setState(() => _connected = false);
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: duration,
      ),
    );
  }

  Future<void> requestLocationPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.manageExternalStorage,
      Permission.accessMediaLocation,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
  }
}
