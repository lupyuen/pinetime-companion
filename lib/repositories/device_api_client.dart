//  Client API for accessing Bluetooth LE device
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:cbor/cbor.dart' as cbor;               //  CBOR Encoder and Decoder. From https://pub.dev/packages/cbor
import 'package:typed_data/typed_data.dart' as typed;  //  Helpers for Byte Buffers. From https://pub.dev/packages/typed_data
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

    //  Create a completer to wait for response from PineTime
    final completer = Completer<typed.Uint8Buffer>();
    final response = typed.Uint8Buffer();

    //  Handle responses from PineTime via Bluetooth LE Notifications    
    await smpCharac.setNotifyValue(true);
    smpCharac.value.listen((value) {
      //  Response bytes are passed to this callback function, chunk by chunk
      print('Notify: ${ _dump(value) }\n');
      response.addAll(value);

      //  Get the expected message length
      if (response.length < 4) { return; }           //  Length field not available
      final len = (response[2] << 8) + response[3];  //  Length field in bytes 2 and 3
      final responseLength = len + 8;  //  Response includes 8 bytes for header

      //  If the received response length is already the expected response length, mark response as complete
      if (response.length >= responseLength && !completer.isCompleted) {
        print('Response Length: ${ response.length } vs $responseLength\n');
        completer.complete(response);
      }
    });

    //  Compose the query firmware request (Simple Mgmt Protocol)
    final request = composeRequest();

    //  Transmit the query firmware request by writing to the SMP charactertistic
    await smpCharac.write(request, withoutResponse: true);

    //  Response will be delivered via Bluetooth LE Notifications, handled above
    final response2 = await completer.future;  //  Wait for the completer to complete

    //  Disconnect the device
    bluetoothDevice.disconnect();

    //  Extract CBOR message body and decode it
    final body = typed.Uint8Buffer();
    body.addAll(response2.sublist(8));  //  Remove the 8-byte header
    final decodedBody = decodeCBOR(body);
    print('Decoded Response: $decodedBody\n');
    final images = decodedBody[0]['images'] as List<dynamic>;

    //  Return the device state
    final device = Device(
      condition: DeviceCondition.clear,
      formattedCondition: 'Update Firmware',
      minTemp: 0,
      temp: 1,
      maxTemp: 1,
      locationId: 0,
      lastUpdated: DateTime.now(),
      location: '${ bluetoothDevice.name } ${ bluetoothDevice.id.toString() }',
      bluetoothDevice: bluetoothDevice,
      activeFirmwareVersion: (images.length >= 1) ? images[0]['version'] : '',
      standbyFirmwareVersion: (images.length >= 2) ? images[1]['version'] : '',
    );
    return device;
  }
}

/// Decode the CBOR message body
List<dynamic> decodeCBOR(typed.Uint8Buffer payload) {
  // Get our cbor instance. Always do this, it correctly initialises the decoder.
  final inst = cbor.Cbor();

  // Decode from the buffer
  inst.decodeFromBuffer(payload);
  print('Decoded CBOR:\n${ inst.decodedPrettyPrint() }');
  print('${ inst.decodedToJSON() }\n');
  return inst.getDecodedData();
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
I/FlutterBluePlugin(20366): setup
Connecting to VM Service at ws://127.0.0.1:56153/XI6AjAwoNUM=/ws
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->getLong(Ljava/lang/Object;J)J (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->arrayBaseOffset(Ljava/lang/Class;)I (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->copyMemory(JJJ)V (greylist, linking, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->objectFieldOffset(Ljava/lang/reflect/Field;)J (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->getByte(J)B (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->getByte(Ljava/lang/Object;J)B (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->getLong(J)J (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->putByte(JB)V (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->putByte(Ljava/lang/Object;JB)V (greylist,core-platform-api, linking, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->getLong(Ljava/lang/Object;J)J (greylist,core-platform-api, reflection, allowed)
W/er_blue_exampl(20366): Accessing hidden method Lsun/misc/Unsafe;->getLong(Ljava/lang/Object;J)J (greylist,core-platform-api, reflection, allowed)
W/er_blue_exampl(20366): Accessing hidden field Ljava/nio/Buffer;->address:J (greylist, reflection, allowed)
D/FlutterBluePlugin(20366): mDevices size: 0
D/FlutterBluePlugin(20366): mDevices size: 0
D/BluetoothAdapter(20366): isLeEnabled(): ON
D/BluetoothLeScanner(20366): onScannerRegistered() - status=0 scannerId=8 mScannerId=0
D/FlutterBluePlugin(20366): mDevices size: 0
I/flutter (20366): onEvent DeviceRequested
I/flutter (20366): Fetching device...
I/flutter (20366): onTransition Transition { currentState: DeviceInitial, event: DeviceRequested, nextState: DeviceLoadInProgress }
D/BluetoothGatt(20366): connect() - device: E8:C1:1A:12:BA:89, auto: true
D/BluetoothGatt(20366): registerApp()
D/BluetoothGatt(20366): registerApp() - UUID=e0c4eada-3709-4f5c-80c4-2d39b4cc0309
D/BluetoothGatt(20366): onClientRegistered() - status=0 clientIf=9
D/FlutterBluePlugin(20366): mDevices size: 1
D/BluetoothGatt(20366): onClientConnectionState() - status=0 clientIf=9 device=E8:C1:1A:12:BA:89
D/FlutterBluePlugin(20366): [onConnectionStateChange] status: 0 newState: 2
I/flutter (20366): Device: BluetoothDevice{id: E8:C1:1A:12:BA:89, name: pinetime, type: BluetoothDeviceType.le, isDiscoveringServices: false, _services: []
D/BluetoothGatt(20366): discoverServices() - device: E8:C1:1A:12:BA:89
D/BluetoothAdapter(20366): isLeEnabled(): ON
D/BluetoothGatt(20366): onConnectionUpdated() - Device=E8:C1:1A:12:BA:89 interval=6 latency=0 timeout=500 status=0
D/BluetoothGatt(20366): onSearchComplete() = Device=E8:C1:1A:12:BA:89 Status=0
D/FlutterBluePlugin(20366): [onServicesDiscovered] count: 6 status: 0
D/BluetoothGatt(20366): setCharacteristicNotification() - uuid: da2e7828-fbce-4e01-ae9e-261174997c48 enable: true
D/FlutterBluePlugin(20366): [onDescriptorWrite] uuid: 00002902-0000-1000-8000-00805f9b34fb status: 0
I/flutter (20366): Encoded {NmpBase:{hdr:{Op:0 Flags:0 Len:0 Group:1 Seq:63 Id:0}}} {} to:
I/flutter (20366): a0
I/flutter (20366): Encoded:
I/flutter (20366): 00 00 00 01 00 01 3f 00 a0
I/flutter (20366): Notify:
D/BluetoothGatt(20366): onConnectionUpdated() - Device=E8:C1:1A:12:BA:89 interval=36 latency=0 timeout=500 status=0
D/FlutterBluePlugin(20366): [onCharacteristicWrite] uuid: da2e7828-fbce-4e01-ae9e-261174997c48 status: 0
D/FlutterBluePlugin(20366): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/chatty  (20366): uid=10302(com.pauldemarco.flutter_blue_example) Binder:20366_2 identical 2 lines
D/FlutterBluePlugin(20366): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/flutter (20366): Notify: 01 00 00 f4 00 01 3f 00 bf 66 69 6d 61 67 65 73 9f bf 64 73
I/flutter (20366): Notify: 6c 6f 74 00 67 76 65 72 73 69 6f 6e 65 31 2e 30 2e 30 64 68
I/flutter (20366): Notify: 61 73 68 58 20 ea bc 3a ce 74 a8 28 4c 6f 78 c2 bc ad 3a e1
I/flutter (20366): Notify: 8d 39 26 75 c7 66 c5 1f 95 23 0f 13 39 3f 08 1c 5d 68 62 6f
D/FlutterBluePlugin(20366): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/flutter (20366): Notify: 6f 74 61 62 6c 65 f5 67 70 65 6e 64 69 6e 67 f4 69 63 6f 6e
D/FlutterBluePlugin(20366): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/chatty  (20366): uid=10302(com.pauldemarco.flutter_blue_example) Binder:20366_2 identical 2 lines
D/FlutterBluePlugin(20366): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/flutter (20366): Notify: 66 69 72 6d 65 64 f5 66 61 63 74 69 76 65 f5 69 70 65 72 6d
I/flutter (20366): Notify: 61 6e 65 6e 74 f4 ff bf 64 73 6c 6f 74 01 67 76 65 72 73 69
I/flutter (20366): Notify: 6f 6e 65 31 2e 31 2e 30 64 68 61 73 68 58 20 0d 78 49 f7 fe
I/flutter (20366): Notify: 43 92 7a 87 d7 b4 d5 54 f8 43 08 82 33 d8 02 d5 09 0c 20 da
D/FlutterBluePlugin(20366): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/chatty  (20366): uid=10302(com.pauldemarco.flutter_blue_example) Binder:20366_2 identical 1 line
D/FlutterBluePlugin(20366): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/flutter (20366): Notify: a1 e6 a7 77 72 99 6e 68 62 6f 6f 74 61 62 6c 65 f5 67 70 65
I/flutter (20366): Notify: 6e 64 69 6e 67 f4 69 63 6f 6e 66 69 72 6d 65 64 f4 66 61 63
I/flutter (20366): Notify: 74 69 76 65 f4 69 70 65 72 6d 61 6e 65 6e 74 f4 ff ff 6b 73
D/FlutterBluePlugin(20366): [onCharacteristicChanged] uuid: da2e7828-fbce-4e01-ae9e-261174997c48
I/flutter (20366): Notify: 70 6c 69 74 53 74 61 74 75 73 00 ff
I/flutter (20366): Response Length: 252 vs 252
D/BluetoothGatt(20366): cancelOpen() - device: E8:C1:1A:12:BA:89
D/BluetoothGatt(20366): onClientConnectionState() - status=0 clientIf=9 device=E8:C1:1A:12:BA:89
D/FlutterBluePlugin(20366): [onConnectionStateChange] status: 0 newState: 0
D/BluetoothGatt(20366): close()
D/BluetoothGatt(20366): unregisterApp() - mClientIf=9
I/flutter (20366): Decoded CBOR:
I/flutter (20366): Entry 0   : Value is => {images: [{slot: 0, version: 1.0.0, hash: [234, 188, 58, 206, 116, 168, 40, 76, 111, 120, 194, 188, 173, 58, 225, 141, 57, 38, 117, 199, 102, 197, 31, 149, 35, 15, 19, 57, 63, 8, 28, 93], bootable: true, pending: false, confirmed: true, active: true, permanent: false}, {slot: 1, version: 1.1.0, hash: [13, 120, 73, 247, 254, 67, 146, 122, 135, 215, 180, 213, 84, 248, 67, 8, 130, 51, 216, 2, 213, 9, 12, 32, 218, 161, 230, 167, 119, 114, 153, 110], bootable: true, pending: false, confirmed: false, active: false, permanent: false}], splitStatus: 0}
I/flutter (20366): {"images":[{"slot":0,"version":"1.0.0","hash":[234,188,58,206,116,168,40,76,111,120,194,188,173,58,225,141,57,38,117,199,102,197,31,149,35,15,19,57,63,8,28,93],"bootable":true,"pending":false,"confirmed":true,"active":true,"permanent":false},{"slot":1,"version":"1.1.0","hash":[13,120,73,247,254,67,146,122,135,215,180,213,84,248,67,8,130,51,216,2,213,9,12,32,218,161,230,167,119,114,153,110],"bootable":true,"pending":false,"confirmed":false,"active":false,"permanent":false}],"splitStatus":0}
I/flutter (20366): Decoded Response: [{images: [{slot: 0, version: 1.0.0, hash: [234, 188, 58, 206, 116, 168, 40, 76, 111, 120, 194, 188, 173, 58, 225, 141, 57, 38, 117, 199, 102, 197, 31, 149, 35, 15, 19, 57, 63, 8, 28, 93], bootable: true, pending: false, confirmed: true, active: true, permanent: false}, {slot: 1, version: 1.1.0, hash: [13, 120, 73, 247, 254, 67, 146, 122, 135, 215, 180, 213, 84, 248, 67, 8, 130, 51, 216, 2, 213, 9, 12, 32, 218, 161, 230, 167, 119, 114, 153, 110], bootable: true, pending: false, confirmed: false, active: false, permanent: false}], splitStatus: 0}]
I/flutter (20366): onTransition Transition { currentState: DeviceLoadInProgress, event: DeviceRequested, nextState: DeviceLoadSuccess }
I/flutter (20366): onEvent DeviceChanged
I/flutter (20366): onTransition Transition { currentState: ThemeState, event: DeviceChanged, nextState: ThemeState }
Application finished.
Exited (sigterm)
*/