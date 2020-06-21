//  Client API for accessing Bluetooth LE device
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';
import '../models/models.dart';
import '../newtmgr.dart';

class DeviceApiClient {
  /// Connect to the PineTime device and query the firmare inside
  Future<Device> fetchDevice(BluetoothDevice bluetoothDevice) async {
    print('Fetching device...\n');

    //  Connect to PineTime
    await bluetoothDevice.connect();
    print('Device: ${ bluetoothDevice.toString() }\n');
    var smpCharac;

    //  Discover the services on PineTime
    List<BluetoothService> services = await bluetoothDevice.discoverServices();
    for (BluetoothService service in services) {
      //  Look for Simple Mgmt Protocol Service
      //  print('Service: ${ service.toString() }\n');  //  print('UUID: ${ service.uuid.toByteArray() }\n');
      if (!listEquals(
        service.uuid.toByteArray(), 
        [0x8d,0x53,0xdc,0x1d,0x1d,0xb7,0x4c,0xd3,0x86,0x8b,0x8a,0x52,0x74,0x60,0xaa,0x84]
      )) { continue; }

      //  Look for Simple Mgmt Protocol Characteristic
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic charac in characteristics) {
        //  print('Charac: ${ charac.toString() }\n');  //  print('UUID: ${ charac.uuid.toByteArray() }\n');
        if (!listEquals(
          charac.uuid.toByteArray(),
          [0xda,0x2e,0x78,0x28,0xfb,0xce,0x4e,0x01,0xae,0x9e,0x26,0x11,0x74,0x99,0x7c,0x48]
        )) { continue; }

        //  Found the characteristic
        smpCharac = charac;
        break;
      }
      //  Found the characteristic
      if (smpCharac != null) { break; }
    }

    //  If Simple Mgmt Protocol Service or Characteristic not found...
    if (smpCharac == null) {
      bluetoothDevice.disconnect();
      throw new Exception('Device doesn\'t support Simple Management Protocol. You may need to flash a suitable firmware.');
    }

    //  Read all descriptors
    //  var descriptors = smpCharac.descriptors;
    //  for (BluetoothDescriptor desc in descriptors) { print('Desc: ${ desc.toString() }\n'); }

    //  Handle responses from PineTime via Bluetooth LE Notifications
    await smpCharac.setNotifyValue(true);
    smpCharac.value.listen((value) {
      print('Notify: ${ _dump(value) }\n');
    });

    //  Compose the query firmware request (Simple Mgmt Protocol)
    final request = composeRequest();

    //  Transmit the query firmware request by writing to the SMP charactertistic
    await smpCharac.write(request, withoutResponse: true);

    //  Response will be delivered via Bluetooth LE Notifications, handled above

    //  Return the interim device state
    final device = Device(
      condition: DeviceCondition.clear,
      formattedCondition: 'Update Firmware',
      minTemp: 0,
      temp: 1,
      maxTemp: 1,
      locationId: 0,
      lastUpdated: DateTime.now(),
      location: '${ bluetoothDevice.name } ${ bluetoothDevice.id.toString() }',
      bluetoothDevice: bluetoothDevice
    );
    return device;
  }
}

/// Return the buffer buf dumped as hex numbers
String _dump(dynamic buf) {
  return buf.map(
    (b) {
      return b.toRadixString(16).padLeft(2, "0");
    }
  ).join(" ");
}

/* Log:
Launching lib/main.dart on Pixel 4 XL in debug mode...
✓ Built build/app/outputs/apk/debug/app-debug.apk.
I/FlutterBluePlugin(20746): setup
Connecting to VM Service at ws://127.0.0.1:56834/J0WhhxjM9qI=/ws
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->getLong(Ljava/lang/Object;J)J (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->arrayBaseOffset(Ljava/lang/Class;)I (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->copyMemory(JJJ)V (greylist, linking, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->objectFieldOffset(Ljava/lang/reflect/Field;)J (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->getByte(J)B (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->getByte(Ljava/lang/Object;J)B (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->getLong(J)J (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->putByte(JB)V (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->putByte(Ljava/lang/Object;JB)V (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->getLong(Ljava/lang/Object;J)J (greylist,core-platform-api, reflection, allowed)
W/er_blue_exampl(20746): Accessing hidden method Lsun/misc/Unsafe;->getLong(Ljava/lang/Object;J)J (greylist,core-platform-api, reflection, allowed)
W/er_blue_exampl(20746): Accessing hidden field Ljava/nio/Buffer;->address:J (greylist, reflection, allowed)
D/FlutterBluePlugin(20746): mDevices size: 0
D/BluetoothAdapter(20746): isLeEnabled(): ON
D/BluetoothLeScanner(20746): onScannerRegistered() - status=0 scannerId=7 mScannerId=0
I/flutter (20746): onEvent DeviceRequested
I/flutter (20746): Fetching device...
I/flutter (20746): onTransition Transition { currentState: DeviceInitial, event: DeviceRequested, nextState: DeviceLoadInProgress }
D/BluetoothGatt(20746): connect() - device: E8:C1:1A:12:BA:89, auto: true
D/BluetoothGatt(20746): registerApp()
D/BluetoothGatt(20746): registerApp() - UUID=4de1fee2-4a06-4595-a5cf-40533eb5db77
D/BluetoothGatt(20746): onClientRegistered() - status=0 clientIf=8
D/BluetoothGatt(20746): onClientConnectionState() - status=0 clientIf=8 device=E8:C1:1A:12:BA:89
D/FlutterBluePlugin(20746): [onConnectionStateChange] status: 0 newState: 2
I/flutter (20746): Device: BluetoothDevice{id: E8:C1:1A:12:BA:89, name: pinetime, type: BluetoothDeviceType.le, isDiscoveringServices: false, _services: []
D/BluetoothGatt(20746): discoverServices() - device: E8:C1:1A:12:BA:89
D/BluetoothGatt(20746): onConnectionUpdated() - Device=E8:C1:1A:12:BA:89 interval=6 latency=0 timeout=500 status=0
D/BluetoothGatt(20746): onSearchComplete() = Device=E8:C1:1A:12:BA:89 Status=0
D/FlutterBluePlugin(20746): [onServicesDiscovered] count: 6 status: 0
D/BluetoothGatt(20746): setCharacteristicNotification() - uuid: da2e7828-fbce-4e01-ae9e-261174997c48 enable: true
D/FlutterBluePlugin(20746): [onDescriptorWrite] uuid: 00002902-0000-1000-8000-00805f9b34fb status: 0
I/flutter (20746): Encoded {NmpBase:{hdr:{Op:0 Flags:0 Len:0 Group:1 Seq:46 Id:0}}} {} to:
I/flutter (20746): a0
I/flutter (20746): Encoded:
I/flutter (20746): 00 00 00 01 00 01 2e 00 a0
I/flutter (20746): Notify:
D/FlutterBluePlugin(20746): [onCharacteristicWrite] uuid: da2e7828-fbce-4e01-ae9e-261174997c48 status: 0
I/flutter (20746): onTransition Transition { currentState: DeviceLoadInProgress, event: DeviceRequested, nextState: DeviceLoadSuccess }
I/flutter (20746): onEvent DeviceChanged
I/flutter (20746): onTransition Transition { currentState: ThemeState, event: DeviceChanged, nextState: ThemeState }
D/BluetoothGatt(20746): onConnectionUpdated() - Device=E8:C1:1A:12:BA:89 interval=36 latency=0 timeout=500 status=0
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/flutter (20746): Notify: 01 00 00 f4 00 01 2e 00 bf 66 69 6d 61 67 65 73 9f bf 64 73
I/flutter (20746): Notify: 6c 6f 74 00 67 76 65 72 73 69 6f 6e 65 31 2e 30 2e 30 64 68
I/flutter (20746): Notify: 61 73 68 58 20 ea bc 3a ce 74 a8 28 4c 6f 78 c2 bc ad 3a e1
I/flutter (20746): Notify: 8d 39 26 75 c7 66 c5 1f 95 23 0f 13 39 3f 08 1c 5d 68 62 6f
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/flutter (20746): Notify: 6f 74 61 62 6c 65 f5 67 70 65 6e 64 69 6e 67 f4 69 63 6f 6e
I/flutter (20746): Notify: 66 69 72 6d 65 64 f5 66 61 63 74 69 76 65 f5 69 70 65 72 6d
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/chatty  (20746): uid=10302(com.pauldemarco.flutter_blue_example) Binder:20746_3 identical 1 line
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/flutter (20746): Notify: 61 6e 65 6e 74 f4 ff bf 64 73 6c 6f 74 01 67 76 65 72 73 69
I/flutter (20746): Notify: 6f 6e 65 31 2e 31 2e 30 64 68 61 73 68 58 20 0d 78 49 f7 fe
I/flutter (20746): Notify: 43 92 7a 87 d7 b4 d5 54 f8 43 08 82 33 d8 02 d5 09 0c 20 da
I/flutter (20746): Notify: a1 e6 a7 77 72 99 6e 68 62 6f 6f 74 61 62 6c 65 f5 67 70 65
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
D/FlutterBluePlugin(20746): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/flutter (20746): Notify: 6e 64 69 6e 67 f4 69 63 6f 6e 66 69 72 6d 65 64 f4 66 61 63
I/flutter (20746): Notify: 74 69 76 65 f4 69 70 65 72 6d 61 6e 65 6e 74 f4 ff ff 6b 73
I/flutter (20746): Notify: 70 6c 69 74 53 74 61 74 75 73 00 ff
D/BluetoothAdapter(20746): isLeEnabled(): ON
Application finished.
Exited (sigterm)
*/