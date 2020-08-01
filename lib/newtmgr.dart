/* 
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
import 'dart:math';
import 'package:cbor/cbor.dart'
    as cbor; //  CBOR Encoder and Decoder. From https://pub.dev/packages/cbor
import 'package:typed_data/typed_data.dart'
    as typed; //  Helpers for Byte Buffers. From https://pub.dev/packages/typed_data

////////////////////////////////////////
//  nmxact/nmp/nmp.go
//  Converted from Go: https://github.com/lupyuen/mynewt-newtmgr/blob/master/nmxact/nmp/nmp.go

const NMP_HDR_SIZE = 8;

/// SMP Header
class NmpHdr {
  int op; //  uint8: 3 bits of opcode
  int flags; //  uint8
  int len; //  uint16
  int group; //  uint16
  int seq; //  uint8
  int id; //  uint8

  /// Construct an SMP Header
  NmpHdr(
      this.op, //  uint8: 3 bits of opcode
      this.flags, //  uint8
      this.len, //  uint16
      this.group, //  uint16
      this.seq, //  uint8
      this.id //  uint8
      );

  /// Return this SMP Header as a list of bytes
  typed.Uint8Buffer bytes() {
    //  Returns []byte
    var buf = typed.Uint8Buffer(); //  make([]byte, 0, NMP_HDR_SIZE);

    buf.add(this.op);
    buf.add(this.flags);

    typed.Uint8Buffer u16b = binaryBigEndianPutUint16(this.len);
    buf.addAll(u16b);

    u16b = binaryBigEndianPutUint16(this.group);
    buf.addAll(u16b);

    buf.add(this.seq);
    buf.add(this.id);
    assert(buf.length == NMP_HDR_SIZE);

    return buf;
  }
}

/// SMP Message
class NmpMsg {
  NmpHdr hdr;
  NmpReq body; //  Previously interface{}

  /// Construct an SMP Message
  NmpMsg(this.hdr, this.body);
}

/// SMP Request Message
abstract class NmpReq {
  NmpHdr hdr();
  void setHdr(NmpHdr hdr);

  NmpMsg msg();
  void encode(cbor.MapBuilder builder);
}

/// SMP Response Message
abstract class NmpRsp {
  NmpHdr hdr();
  void setHdr(NmpHdr msg);

  NmpMsg msg();
}

/// SMP Base Message
mixin NmpBase {
  NmpHdr _hdr; //  Will not be encoded: `codec:"-"`

  NmpHdr hdr() {
    return _hdr;
  }

  void setHdr(NmpHdr h) {
    _hdr = h;
  }
}

NmpMsg msgFromReq(NmpReq r) {
  return NmpMsg(r.hdr(), r);
}

NmpMsg newNmpMsg() {
  return NmpMsg(NmpHdr(0, 0, 0, 0, 0, 0), null);
}

NmpHdr decodeNmpHdr(typed.Uint8Buffer data /* []byte */) {
  if (data.length < NMP_HDR_SIZE) {
    throw Exception("Newtmgr request buffer too small ${data.length} bytes");
  }

  final hdr = NmpHdr(
    data[0], //  Op:    uint8
    data[1], //  Flags: uint8
    binaryBigEndianUint16(data[2], data[3]), //  Len: binary.BigEndian.Uint16
    binaryBigEndianUint16(data[4], data[5]), //  Group: binary.BigEndian.Uint16
    data[6], //  Seq:   uint8
    data[7], //  Id:    uint8
  );

  return hdr;
}

/// Encode SMP Request Body with CBOR and return the byte array
typed.Uint8Buffer bodyBytes(
    //  Returns []byte
    NmpReq body //  Previously interface{}
    ) {
  // Get our cbor instance, always do this, it correctly initialises the decoder.
  final inst = cbor.Cbor();

  // Get our encoder and map builder
  final encoder = inst.encoder;
  final mapBuilder = cbor.MapBuilder.builder();

  //  Encode the body as a CBOR map
  body.encode(mapBuilder);
  final mapData = mapBuilder.getData();
  encoder.addBuilderOutput(mapData);

  //  Get the encoded body
  final data = inst.output.getData();

  //  Decode the encoded body and pretty print it
  inst.decodeFromInput(); //  print(inst.decodedPrettyPrint(false));
  final hdr = body.hdr();
  print("Encoded {NmpBase:{hdr:{"
      "Op:${hdr.op} "
      "Flags:${hdr.flags} "
      "Len:${hdr.len} "
      "Group:${hdr.group} "
      "Seq:${hdr.seq} "
      "Id:${hdr.id}}}} "
      "${inst.decodedToJSON()} "
      "to:\n${hexDump(data)}");
  return data;
}

/// Encode the SMP Message with CBOR and return the byte array
typed.Uint8Buffer encodeNmpPlain(NmpMsg nmr) {
  //  Returns []byte
  final bb = bodyBytes(nmr.body);

  nmr.hdr.len = bb.length; //  uint16

  final hb = nmr.hdr.bytes();
  var data = typed.Uint8Buffer();
  data.addAll(hb);
  data.addAll(bb);

  print("Encoded:\n${hexDump(data)}");
  return data;
}

/// Init the SMP Request and set the sequence number
void fillNmpReqWithSeq(
    NmpReq req,
    int op, //  uint8
    int group, //  uint16
    int id, //  uint8
    int seq //  uint8
    ) {
  final hdr = NmpHdr(
      op, //  Op
      0, //  Flags
      0, //  Len
      group, //  Group
      seq, //  Seq
      id //  Id
      );

  req.setHdr(hdr);
}

/// Init the SMP Request and set the next sequence number
void fillNmpReq(
    NmpReq req,
    int op, //  uint8
    int group, //  uint16
    int id //  uint8
    ) {
  fillNmpReqWithSeq(req, op, group, id, nextNmpSeq() //  From nmxutil
      );
}

/// Return byte array [a,b] as unsigned 16-bit int
int binaryBigEndianUint16(int a, int b) {
  return (a << 8) + b;
}

/// Return unsigned int u as big endian byte array
typed.Uint8Buffer binaryBigEndianPutUint16(int u) {
  var data = typed.Uint8Buffer();
  data.add(u >> 8);
  data.add(u & 0xff);
  return data;
}

/// Return the buffer buf dumped as hex numbers
String hexDump(typed.Uint8Buffer buf) {
  return buf.map((b) {
    return b.toRadixString(16).padLeft(2, "0");
  }).join(" ");
}

////////////////////////////////////////
//  nmxact/xact/image.go
//  Converted from Go: https://github.com/lupyuen/mynewt-newtmgr/blob/master/nmxact/xact/image.go

//////////////////////////////////////////////////////////////////////////////
// $state read                                                              //
//////////////////////////////////////////////////////////////////////////////

class ImageStateReadCmd with CmdBase implements Cmd {
  CmdBase base;

  //  TODO: ImageStateReadCmd(this.base);

  Result run(Sesn s //  Previously sesn.Sesn
      ) {
    final r = newImageStateReadReq(); //  Previously nmp.NewImageStateReadReq()

    //final rsp = 
    txReq(s, r.msg(), this.base);
    //  TODO: final srsp = rsp.ImageStateRsp;  //  Previously nmp.ImageStateRsp

    var res = newImageStateReadResult();
    //  TODO: res.Rsp = srsp;
    return res;
  }
}

class ImageStateReadResult implements Result {
  ImageStateRsp rsp; //  Previously nmp.ImageStateRsp

  int status() {
    return this.rsp.rc;
  }
}

ImageStateReadCmd newImageStateReadCmd() {
  return ImageStateReadCmd(
      //  TODO: NewCmdBase()
      );
}

ImageStateReadResult newImageStateReadResult() {
  return ImageStateReadResult();
}

////////////////////////////////////////
//  nmxact/nmp/image.go
//  Converted from Go: https://github.com/lupyuen/mynewt-newtmgr/blob/master/nmxact/nmp/image.go

//////////////////////////////////////////////////////////////////////////////
// $state                                                                   //
//////////////////////////////////////////////////////////////////////////////

/* TODO
  type SplitStatus int

  const (
    NOT_APPLICABLE SplitStatus = iota
    NOT_MATCHING
    MATCHING
  )

  //  returns the enum as a string
  func (sm SplitStatus) String() string {
    names := map[SplitStatus]string{
      NOT_APPLICABLE: "N/A",
      NOT_MATCHING:   "non-matching",
      MATCHING:       "matching",
    }

    str := names[sm]
    if str == "" {
      return "Unknown!"
    }
    return str
  }

  type ImageStateEntry struct {
    NmpBase
    Image     int    `codec:"image"`
    Slot      int    `codec:"slot"`
    Version   string `codec:"version"`
    Hash      []byte `codec:"hash"`
    Bootable  bool   `codec:"bootable"`
    Pending   bool   `codec:"pending"`
    Confirmed bool   `codec:"confirmed"`
    Active    bool   `codec:"active"`
    Permanent bool   `codec:"permanent"`
  }
*/

class ImageStateReadReq
    with
        NmpBase //  Get and set SMP Message Header
    implements
        NmpReq //  SMP Request Message
{
  NmpBase base; //  Will not be encoded: `codec:"-"`

  NmpMsg msg() {
    return msgFromReq(this);
  }

  /// Encode the SMP Request fields to CBOR
  void encode(cbor.MapBuilder builder) {
    // Add some map entries to the list.
    // Entries are added as a key followed by a value, this ordering is enforced.
    // Map keys can be integers or strings only, this is also enforced.
    // mapBuilder.writeString('a');   // key
    // mapBuilder.writeURI('a/ur1');  // value
    // mapBuilder.writeString('b');      // key
    // mapBuilder.writeEpoch(1234567899);// value
    // mapBuilder.writeString('c');           // key
    // mapBuilder.writeDateTime('19/04/2020');// value

    // Get our built map output and add it to the encoding stream.
    // The key/value pairs must be balanced, i.e. you must end the map building with
    // a value else the getData method will throw an exception.
    // Use the addBuilderOutput method to add built output to the encoder.
    // You can use the addBuilderOutput method on the map builder to add
    // the output of other list or map builders to its encoding stream.

    //  encoder.writeArray(<int>[1, 2, 3]);
    //  encoder.writeFloat(67.89);
    //  encoder.writeInt(10);
  }
}

/* TODO
  type ImageStateWriteReq struct {
    NmpBase `codec:"-"`
    Hash    []byte `codec:"hash"`
    Confirm bool   `codec:"confirm"`
  }

  type ImageStateRsp struct {
    NmpBase
    Rc          int               `codec:"rc"`
    Images      []ImageStateEntry `codec:"images"`
    SplitStatus SplitStatus       `codec:"splitStatus"`
  }
*/

ImageStateReadReq newImageStateReadReq() {
  var r = ImageStateReadReq();
  fillNmpReq(r, NMP_OP_READ, NMP_GROUP_IMAGE, NMP_ID_IMAGE_STATE);
  return r;
}

/* TODO
  func NewImageStateWriteReq() *ImageStateWriteReq {
    r := &ImageStateWriteReq{}
    fillNmpReq(r, NMP_OP_WRITE, NMP_GROUP_IMAGE, NMP_ID_IMAGE_STATE)
    return r
  }

  func (r *ImageStateWriteReq) Msg() *NmpMsg { return MsgFromReq(r) }

  func NewImageStateRsp() *ImageStateRsp {
    return &ImageStateRsp{}
  }

  func (r *ImageStateRsp) Msg() *NmpMsg { return MsgFromReq(r) }
*/

////////////////////////////////////////
//  nmxact/nmxutil/nmxutil.go
//  Converted from Go: https://github.com/lupyuen/mynewt-newtmgr/blob/master/nmxact/nmxutil/nmxutil.go

int _nextNmpSeq = 0; //  Previously uint8
bool nmpSeqBeenRead = false;

/// Return the next SMP Message Sequence Number, 0 to 255. The first number is random.
int nextNmpSeq() {
  //  Returns uint8
  //  TODO: seqMutex.Lock()
  //  TODO: defer seqMutex.Unlock()

  if (!nmpSeqBeenRead) {
    //  First number is random
    var rng = new Random();
    _nextNmpSeq = rng.nextInt(256); //  Returns 0 to 255
    nmpSeqBeenRead = true;
  }

  final val = _nextNmpSeq;
  _nextNmpSeq = (_nextNmpSeq + 1) % 256;
  assert(val >= 0 && val <= 255);
  return val;
}

////////////////////////////////////////
//  nmxact/xact/cmd.go
//  Converted from Go: https://github.com/lupyuen/mynewt-newtmgr/blob/master/nmxact/xact/cmd.go

/// Result of an SMP operation
abstract class Result {
  int status();
}

/// SMP Command
abstract class Cmd {
  /// Transmits request and listens for response; blocking.
  Result run(Sesn s); //  Previously sesn.Sesn
  void abort();

  //  TxOptions TxOptions();             //  Previously sesn.TxOptions
  void setTxOptions(TxOptions opt); //  Previously sesn.TxOptions
}

/// Base Class for SMP Command
mixin CmdBase {
  TxOptions txOptions; //  Previously sesn.TxOptions
  int curNmpSeq; //  Previously uint8
  Sesn curSesn; //  Previously sesn.Sesn
  Exception abortErr; // Previously error

  /// Constructor
  //  CmdBase(this.txOptions);

  /*
  TxOptions TxOptions() {  //  Previously sesn.TxOptions
    return this.txOptions;
  }
  */

  void setTxOptions(TxOptions opt //  Previously sesn.TxOptions
      ) {
    this.txOptions = opt;
  }

  void abort() {
    if (this.curSesn != null) {
      //  TODO: this.curSesn.AbortRx(this.curNmpSeq);
    }
    this.abortErr = Exception("Command aborted");
  }
}

/*
CmdBase NewCmdBase() {
	return CmdBase(
		NewTxOptions()  //  Previously sesn.NewTxOptions
  );
}
*/

////////////////////////////////////////
//  nmxact/xact/xact.go
//  Converted from Go: https://github.com/lupyuen/mynewt-newtmgr/blob/master/nmxact/xact/xact.go

/// Transmit an SMP Request and get the SMP Response
NmpRsp txReq(
    //  Returns nmp.NmpRsp
    Sesn s, //  Previously sesn.Sesn
    NmpMsg m, //  Previously nmp.NmpMsg
    CmdBase c) {
  //  TODO: assert(c != null);
  if (c != null) {
    //  TODO: Should not be null
    if (c.abortErr != null) {
      throw c.abortErr;
    }
    c.curNmpSeq = m.hdr.seq;
    c.curSesn = s;
  }

  //  TODO: final rsp = sesn.TxRxMgmt(s, m, c.TxOptions());
  final rsp = ImageStateRsp();
  //final data = 
  encodeNmpPlain(m);

  if (c != null) {
    //  TODO: Should not be null
    c.curNmpSeq = 0;
    c.curSesn = null;
  }
  return rsp;
}

////////////////////////////////////////
//  nmxact/nmp/defs.go
//  Converted from Go: https://github.com/lupyuen/mynewt-newtmgr/blob/master/nmxact/nmp/defs.go

const NMP_OP_READ = 0,
    NMP_OP_READ_RSP = 1,
    NMP_OP_WRITE = 2,
    NMP_OP_WRITE_RSP = 3;

const NMP_ERR_OK = 0,
    NMP_ERR_EUNKNOWN = 1,
    NMP_ERR_ENOMEM = 2,
    NMP_ERR_EINVAL = 3,
    NMP_ERR_ETIMEOUT = 4,
    NMP_ERR_ENOENT = 5;

// First 64 groups are reserved for system level newtmgr commands.
// Per-user commands are then defined after group 64.

const NMP_GROUP_DEFAULT = 0,
    NMP_GROUP_IMAGE = 1,
    NMP_GROUP_STAT = 2,
    NMP_GROUP_CONFIG = 3,
    NMP_GROUP_LOG = 4,
    NMP_GROUP_CRASH = 5,
    NMP_GROUP_SPLIT = 6,
    NMP_GROUP_RUN = 7,
    NMP_GROUP_FS = 8,
    NMP_GROUP_SHELL = 9,
    NMP_GROUP_PERUSER = 64;

// Default group (0).
const NMP_ID_DEF_ECHO = 0,
    NMP_ID_DEF_CONS_ECHO_CTRL = 1,
    NMP_ID_DEF_TASKSTAT = 2,
    NMP_ID_DEF_MPSTAT = 3,
    NMP_ID_DEF_DATETIME_STR = 4,
    NMP_ID_DEF_RESET = 5;

// Image group (1).
const NMP_ID_IMAGE_STATE = 0,
    NMP_ID_IMAGE_UPLOAD = 1,
    NMP_ID_IMAGE_CORELIST = 3,
    NMP_ID_IMAGE_CORELOAD = 4,
    NMP_ID_IMAGE_ERASE = 5;

// Stat group (2).
const NMP_ID_STAT_READ = 0, NMP_ID_STAT_LIST = 1;

// Config group (3).
const NMP_ID_CONFIG_VAL = 0;

// Log group (4).
const NMP_ID_LOG_SHOW = 0,
    NMP_ID_LOG_CLEAR = 1,
    NMP_ID_LOG_APPEND = 2,
    NMP_ID_LOG_MODULE_LIST = 3,
    NMP_ID_LOG_LEVEL_LIST = 4,
    NMP_ID_LOG_LIST = 5;

// Crash group (5).
const NMP_ID_CRASH_TRIGGER = 0;

// Run group (7).
const NMP_ID_RUN_TEST = 0, NMP_ID_RUN_LIST = 1;

// File system group (8).
const NMP_ID_FS_FILE = 0;

// Shell group (8).
const NMP_ID_SHELL_EXEC = 0;

////////////////////////////////////////
//  TODO: Check response from PineTime

class ImageStateRsp implements NmpRsp {
  //  TODO
  int rc;
  //  TODO
  NmpHdr hdr() {
    return NmpHdr(0, 0, 0, 0, 0, 0);
  }

  //  TODO
  NmpMsg msg() {
    return NmpMsg(null, null);
  }

  //  TODO
  void setHdr(NmpHdr msg) {}
}

/// Bluetooth LE Session
class Sesn {}

Sesn getSesn() {
  return Sesn();
}

/// Bluetooth LE Transmission Options
class TxOptions {}

TxOptions newTxOptions() {
  return TxOptions();
}

////////////////////////////////////////
//  Send Simple Mgmt Protocol Command to PineTime over Bluetooth LE

void oldMain() {
  composeRequest();
}

/// Compose a request to query firmware images on PineTime
typed.Uint8Buffer composeRequest() {
  //  Create the SMP Request
  final req = newImageStateReadReq();

  //  Encode the SMP Message with CBOR
  final msg = req.msg();
  final data = encodeNmpPlain(msg);
  return data;
}

/// Query firmware images on PineTime
void testCommand() {
  //  Fetch the Bluetooth LE Session
  final s = getSesn();

  //  Create the SMP Command
  final c = newImageStateReadCmd(); //  Previously xact.NewImageStateReadCmd()

  //  TODO: Set the Bluetooth LE transmission options
  //  c.SetTxOptions(nmutil.TxOptions());

  //  Transmit the SMP Command
  //final res = 
  c.run(s);

  //  TODO: Handle SMP Response
  //  final ires = res.ImageStateReadResult;  //  Previously xact.ImageStateReadResult
  //  imageStatePrintRsp(ires.Rsp);
}

/// Test the CBOR library
void testCbor() {
  /// An example of using the Map Builder class.
  /// Map builder is used to build maps with complex values such as tag values, indefinite sequences
  /// and the output of other list or map builders.

  // Get our cbor instance, always do this,it correctly
  // initialises the decoder.
  final inst = cbor.Cbor();

  // Get our encoder
  final encoder = inst.encoder;

  // Encode some values
  encoder.writeArray(<int>[1, 2, 3]);
  encoder.writeFloat(67.89);
  encoder.writeInt(10);

  // Get our map builder
  final mapBuilder = cbor.MapBuilder.builder();

  // Add some map entries to the list.
  // Entries are added as a key followed by a value, this ordering is enforced.
  // Map keys can be integers or strings only, this is also enforced.
  mapBuilder.writeString('a'); // key
  mapBuilder.writeURI('a/ur1');
  mapBuilder.writeString('b'); // key
  mapBuilder.writeEpoch(1234567899);
  mapBuilder.writeString('c'); // key
  mapBuilder.writeDateTime('19/04/2020');

  // Get our built map output and add it to the encoding stream.
  // The key/value pairs must be balanced, i.e. you must end the map building with
  // a value else the getData method will throw an exception.
  // Use the addBuilderOutput method to add built output to the encoder.
  // You can use the addBuilderOutput method on the map builder to add
  // the output of other list or map builders to its encoding stream.
  final mapData = mapBuilder.getData();
  encoder.addBuilderOutput(mapData);

  // Add another value
  encoder.writeRegEx('^[12]g');

  // Decode ourselves and pretty print it.
  inst.decodeFromInput();
  print(inst.decodedPrettyPrint(false));

  // Finally to JSON
  print(inst.decodedToJSON());

  // JSON output is :-
  // [1,2,3],67.89,10,{"a":"a/ur1","b":1234567899,"c":"19/04/2020"},"^[12]g"

  //  Get the encoded body
  final data = inst.output.getData();
  print("Encoded ${inst.decodedToJSON()} to:\n${hexDump(data)}");
}
