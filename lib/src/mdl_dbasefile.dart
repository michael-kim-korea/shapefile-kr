import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cp949_codec/cp949_codec.dart';

class CDbaseField {
  CDbaseField();

  String _name = '';

  String get name => _name;

  set name(String s) => _name = s.length > 11 ? s.substring(0, 11) : s;
  String type = '';
  int fieldLength = 0;
  int fieldCount = 0;
  int id = 0;
  int flag = 0;

  factory CDbaseField.fieldC(String nameC, [int length = 10]) {
    return CDbaseField()
      ..name = nameC
      ..type = 'C'
      ..fieldLength = length;
  }

  factory CDbaseField.fieldD(String nameD) {
    return CDbaseField()
      ..name = nameD
      ..type = 'D'
      ..fieldLength = 8;
  }

  factory CDbaseField.fieldL(String nameL) {
    return CDbaseField()
      ..name = nameL
      ..type = 'L'
      ..fieldLength = 1;
  }

  factory CDbaseField.fieldN(String nameN, [int length = 10]) {
    return CDbaseField()
      ..name = nameN
      ..type = 'N'
      ..fieldLength = length;
  }

  factory CDbaseField.fieldNF(String nameN, [int length = 20, int count = 8]) {
    return CDbaseField()
      ..name = nameN
      ..type = 'N'
      ..fieldLength = length
      ..fieldCount = count;
  }

  @override
  String toString() {
    return "{$name, $type, $fieldLength, $fieldCount, $id, $flag}";
  }
}

class CDbaseFile {
  CDbaseFile({this.isUtf8 = false, this.isCp949 = false, this.onError});

  bool isUtf8;
  bool isCp949;

  static const LEN_MAX_BUFFER = 65535;
  static const LEN_DB_HEADER = 32;
  static const LEN_DESCRIPTOR = 32;
  static const DBASE_III_PLUS_NO_MENO = 0x03;

  String? _fNameDBF;

  // String get fileName => _fNameDBF??"";
  // set fileName(String name) => _fNameDBF = name;

  File? _fileDBF;
  RandomAccessFile? _rafDBF;

  // Number of records in the database file
  int _recordCount = 0;

  // Number of bytes in the header
  int _headerLength = 0;

  // Number of bytes in the record
  int _recordLength = 0;

  // 전체 파일 길이.
  int _fileLength = -1;

  final ValueChanged? onError;

  List<CDbaseField> fields = [];
  List<List<dynamic>> records = [];

  void open(String dbfFile) {
    close();
    _fNameDBF = dbfFile;
  }

  bool readDBF() {
    if (null != _fileDBF) close();
    int filePosition = 0;

    Uint8List? bufferDBF;
    try {
      _fileDBF = File(_fNameDBF!);
      _rafDBF = _fileDBF!.openSync();
      // _fileLength = _rafDBF!.lengthSync();
      bufferDBF = _rafDBF!.readSync(LEN_DB_HEADER);
      filePosition += LEN_DB_HEADER;
      // debugPrint("file length $_fileLength, file position: $filePosition");
    } catch (e) {
      onError?.call("DBF 파일 열기/읽기 오류: $e");
      return false;
    }

    ByteData dataDBF = ByteData.sublistView(bufferDBF);

    // 0x03 FoxBASE+/Dbase III plus, no memo
    // 0x83 FoxBASE+/dBASE III PLUS, w/ memo
    int type = dataDBF.getUint8(0);
    if (type != DBASE_III_PLUS_NO_MENO) {
      onError?.call("지원하지 않는 DBF 파일 버전입니다. $type");
      return false;
    }

    // The year value in the dBASE header must be the year since 1900.
    int YY = dataDBF.getUint8(1);
    int MM = dataDBF.getUint8(2);
    int DD = dataDBF.getUint8(3);

    // Number of records in the database file
    _recordCount = dataDBF.getUint32(4, Endian.little);
    // Number of bytes in the header
    _headerLength = dataDBF.getUint16(8, Endian.little);
    // Number of bytes in the record
    _recordLength = dataDBF.getUint16(10, Endian.little);

    _fileLength = _headerLength + _recordCount * _recordLength + 1;
    // debugPrint("Type:$type Date:$YY/$MM/$DD - $_recordCount, $_headerLength, $_recordLength");

    bufferDBF = null;
    int descriptorLength = _headerLength - LEN_DB_HEADER;
    try {
      bufferDBF = _rafDBF!.readSync(descriptorLength);
      filePosition += descriptorLength;
      // debugPrint("file position $filePosition");
    } catch (e) {
      onError?.call("DBF 파일 해더 오류: $e");
      return false;
    }
    dataDBF = ByteData.sublistView(bufferDBF);

    int pos = 0;
    while (pos < descriptorLength) {
      var field = CDbaseField();
      var name =
      dataDBF.buffer.asUint8List(pos, 11).where((e) => e != 0).toList();

      field.name = isCp949
          ? cp949.decode(name)
          : isUtf8
          ? utf8.decode(name)
          : String.fromCharCodes(name);

      field.type = String.fromCharCode(dataDBF.getUint8(pos + 11));
      field.fieldLength = dataDBF.getUint8(pos + 16);
      field.fieldCount = dataDBF.getUint8(pos + 17);
      field.id = dataDBF.getUint8(pos + 20);
      field.flag = dataDBF.getUint8(pos + 23);
      fields.add(field);
      // debugPrint("${field.name}, ${field.type}, ${field.fieldLength}, ${field.fieldCount}, ${field.id}, ${field.flag}");

      // var test = dataDBF.buffer.asUint8List(pos, LEN_DESCRIPTOR);
      // debugPrint("$test");

      pos += LEN_DESCRIPTOR;
      // debugPrint("position:$pos");
      // 0x0d 라고 소문자로 사용하면 오류가 된다. 왜인지 모르겠다.
      if (0x0D == dataDBF.getUint8(pos)) {
        pos++;
        break;
      }
    }
    // debugPrint("pos $pos, fields $fields");

    int totalCount = 0; //, totalPosition = filePosition;
    while (totalCount < _recordCount) {
      int length = 0, count = 0;
      for (var n = totalCount; n < _recordCount; ++n) {
        if ((length + _recordLength) > LEN_MAX_BUFFER) {
          break;
        }
        count++;
        length += _recordLength;
      }
      // debugPrint("record length : $count, $length");

      bufferDBF = null;
      try {
        bufferDBF = _rafDBF!.readSync(length);
        filePosition += length;
        // debugPrint("file position: $filePosition");
      } catch (e) {
        onError?.call("DBF 파일 읽기 오류: $e");
        return false;
      }
      dataDBF = ByteData.sublistView(bufferDBF);
      int pos = 0;
      for (var n = 0; n < count; ++n) {
        int offset = 0;
        List<dynamic> record = [];
        // int code = dataDBF.getUint8(pos);
        // 파일의 끝 체크., 현재 코드에서는 count로 체크 하기 때문에 들어올 일이 없다.
        // (code == 0x1A) // end of record
        // 레코드가 삭제 되었음을 알린다. 거의 사용하지 않는다.
        // (code == 0x2A) // record delete
        // 레코드가 삭제되지 않아서 사용 가능하다.
        // (code == 0x20) // record not delete (enable use)
        // debugPrint("$n, $code");
        offset++;
        for (var field in fields) {
          var data =
          dataDBF.buffer.asUint8List(pos + offset, field.fieldLength);
          // debugPrint("$field, $data");
          switch (field.type) {
          // All OEM code page characters.
            case "C": // Character
            // debugPrint("$data, ${utf8.decode(data)}");
            // String dataC = utf8.decode(data).trim();
            //   var name = data.where((e) => e != 0).toList();
              String dataC = isCp949
                  ? cp949.decode(data)
                  : isUtf8
                  ? utf8.decode(data)
                  : String.fromCharCodes(data);
              dataC = dataC.replaceAll(RegExp('\\0'), "").trim();
              record.add(dataC);
              break;
          // Numbers and a character to separate month, day, and year
          // (stored internally as 8 digits in YYYYMMDD format)
            case "D":
              String dataD = String.fromCharCodes(data);
              if (dataD.length == 8) {
                String YY = dataD.substring(0, 4);
                String MM = dataD.substring(4, 6);
                String DD = dataD.substring(6, 8);
                // debugPrint("read: $YY:$MM:$DD");
                record.add(DateTime.parse("$YY-$MM-$DD"));
              } else {
                onError?.call("Field Type D error, $dataD");
                return false;
              }
              break;
          // - . 0 1 2 3 4 5 6 7 8 9
            case "F":
            // String dataF = utf8.decode(data).trim();
              String dataF = String.fromCharCodes(data)
                  .replaceAll(RegExp('\\0'), "")
                  .trim();
              record.add(double.parse(dataF));
              break;
          // - . 0 1 2 3 4 5 6 7 8 9
            case "N":
            // String dataN = utf8.decode(data).trim();
              String dataN =
              String.fromCharCodes(data).replaceAll(RegExp(r'[^\d.-]'), "");
              // debugPrint("$field, $data, $dataN");
              if (0 < dataN.indexOf('-')) {
                if (0 < field.fieldCount) {
                  record.add(0.0);
                } else {
                  record.add(0);
                }
              } else {
                if (0 < field.fieldCount) {
                  record.add(dataN.isEmpty ? 0.0 : double.parse(dataN));
                } else {
                  record.add(dataN.isEmpty ? 0 : int.parse(dataN));
                }
              }
              break;
          //  ? Y y N n T t F f (? when not initialized).
            case "L":
              if ("T" == String.fromCharCode(data[0])) {
                record.add(true);
              } else {
                record.add(false);
              }
              break;
          // case "M":
          //   break;
            default:
              onError?.call("unexpected type code ${field.type}");
              return false;
          }
          offset += field.fieldLength;
        }
        records.add(record);

        pos += offset;
        // totalPosition += offset;
        // if (n < 3) {
        //   debugPrint("index:${totalCount + n}, $record");
        //   debugPrint("$offset, $pos, $totalPosition");
        // }
      }
      totalCount += count;
      // debugPrint("total count: $totalCount, total position $totalPosition");
    }
    // last end of file (0x1A)
    filePosition++;

    // debugPrint("file position: $filePosition / $_fileLength");
    return true;
  }

  bool writeDBF() {
    if (null != _fileDBF) close();
    int filePosition = 0;

    Uint8List? bufferDBF;
    bufferDBF = Uint8List(LEN_DB_HEADER);
    ByteData dataDBF = ByteData.sublistView(bufferDBF);

    // 0x03 FoxBASE+/Dbase III plus, no memo
    // 0x83 FoxBASE+/dBASE III PLUS, w/ memo
    int type = DBASE_III_PLUS_NO_MENO;
    dataDBF.setUint8(0, type);

    // The year value in the dBASE header must be the year since 1900.
    DateTime dt = DateTime.now();
    var YY = dt.year - 1900;
    var MM = dt.month;
    var DD = dt.day;
    dataDBF.setUint8(1, YY);
    dataDBF.setUint8(2, MM);
    dataDBF.setUint8(3, DD);

    // Number of records in the database file
    _recordCount = records.length;
    dataDBF.setUint32(4, _recordCount, Endian.little);
    // Number of bytes in the header
    int descriptorLength =
        LEN_DESCRIPTOR * fields.length + 1 /* end of descriptor */;
    _headerLength = LEN_DB_HEADER + descriptorLength;
    dataDBF.setUint16(8, _headerLength, Endian.little);
    // Number of bytes in the record
    _recordLength = 1; /* check byte (use / not use / end of record) */
    for (var field in fields) {
      _recordLength += field.fieldLength;
    }
    dataDBF.setUint16(10, _recordLength, Endian.little);

    _fileLength = _headerLength + _recordCount * _recordLength + 1;
    // debugPrint("Type:$type Date:$YY/$MM/$DD - $_recordCount, $_headerLength, $_recordLength");

    try {
      _fileDBF = File(_fNameDBF!);
      _rafDBF = _fileDBF!.openSync(mode: FileMode.write);
      _rafDBF!.writeFromSync(bufferDBF);
      filePosition += LEN_DB_HEADER;
      // debugPrint("file position: $filePosition");
    } catch (e) {
      onError?.call("DBF 파일 열기/저장 오류: $e");
      return false;
    }

    bufferDBF = Uint8List(descriptorLength);
    dataDBF = ByteData.sublistView(bufferDBF);

    int pos = 0;
    for (var field in fields) {
      var name = dataDBF.buffer.asUint8List(pos, 11);
      var code = isCp949
          ? cp949.encode(field.name)
          : isUtf8
          ? utf8.encode(field.name)
          : field.name.codeUnits;
      name.setAll(0, code);
      name.fillRange(code.length, 11, 0x20);
      dataDBF.setUint8(pos + 11, field.type.codeUnitAt(0));
      dataDBF.setUint8(pos + 16, field.fieldLength);
      dataDBF.setUint8(pos + 17, field.fieldCount);
      dataDBF.setUint8(pos + 20, field.id);
      dataDBF.setUint8(pos + 23, field.flag);

      // var test = dataDBF.buffer.asUint8List(pos, LEN_DESCRIPTOR);
      // debugPrint("$test");

      pos += LEN_DESCRIPTOR;
    }
    // end of descriptor
    dataDBF.setUint8(pos, 0x0D);
    pos++;

    try {
      _rafDBF!.writeFromSync(bufferDBF, 0, pos);
      filePosition += pos;
      // debugPrint("file position: $filePosition");
    } catch (e) {
      onError?.call("DBF 파일 저장 오류: $e");
      return false;
    }

    bufferDBF = Uint8List(LEN_MAX_BUFFER);
    dataDBF = ByteData.sublistView(bufferDBF);

    int totalCount = 0; //, totalPosition = filePosition;
    while (totalCount < _recordCount) {
      int length = 0, count = 0;
      for (var n = totalCount; n < _recordCount; ++n) {
        if ((length + _recordLength) > LEN_MAX_BUFFER) {
          break;
        }
        count++;
        length += _recordLength;
      }

      pos = 0;
      for (var n = 0; n < count; ++n) {
        int offset = 0;
        // record not delete (enable use) sign
        dataDBF.setUint8(pos + offset, 0x20);
        // record delete sign
        // dataDBF.setUint8(pos+offset, 0x2A);
        offset++;
        var list = records[totalCount + n];
        // debugPrint("${list}");
        for (var i = 0; i < fields.length; ++i) {
          var field = fields[i];
          var data =
          dataDBF.buffer.asUint8List(pos + offset, field.fieldLength);
          switch (field.type) {
            case "C":
            // var dataC = utf8.encode(list[i]);
              var dataC = list[i] as String;

              // var code = utf8.encode(dataC);
              // debugPrint("$dataC - $code");

              var code = isCp949
                  ? cp949.encode(dataC)
                  : isUtf8
                  ? utf8.encode(dataC)
                  : dataC.codeUnits;
              data.setAll(0, code);
              data.fillRange(code.length, field.fieldLength, 0x20);
              break;
            case "D":
              var dataD = list[i] as DateTime;
              String YY = dataD.year.toString();
              String MM = dataD.month.toString().padLeft(2, '0');
              String DD = dataD.day.toString().padLeft(2, '0');
              data.setAll(0, "$YY$MM$DD".codeUnits);
              // debugPrint("write: $YY:$MM:$DD");
              break;
            case "F":
              var dataF = (list[i] as double)
                  .toStringAsPrecision(field.fieldCount)
                  .padLeft(field.fieldLength, ' ');
              data.setAll(0, dataF.codeUnits);
              break;
            case "N":
              if (list[i].runtimeType is double) {
                String dataN = (list[i] as double)
                    .toStringAsPrecision(field.fieldCount)
                    .padLeft(field.fieldLength, ' ');
                data.setAll(0, dataN.codeUnits);
              } else {
                String dataN =
                list[i].toString().padLeft(field.fieldLength, ' ');
                data.setAll(0, dataN.codeUnits);
              }
              break;
            case "L":
              if (list[i]) {
                data.setAll(0, "T".codeUnits);
              } else {
                data.setAll(0, "F".codeUnits);
              }
              break;
          // case "M":
          //   break;
            default:
              onError?.call("unexpected type code ${field.type}");
              return false;
          }
          // debugPrint("data $data");
          offset += field.fieldLength;
        }
        // debugPrint("offset - $offset");
        pos += _recordLength;
      }
      totalCount += count;
      try {
        _rafDBF!.writeFromSync(bufferDBF, 0, pos);
        filePosition += pos;
        // debugPrint("file position: $filePosition");
      } catch (e) {
        onError?.call("DBF 파일 저장 오류: $e");
        return false;
      }
    }
    // end of record
    _rafDBF!.writeByteSync(0x1A);
    filePosition++;

    // debugPrint("file position: $filePosition / $_fileLength");
    return true;
  }

  bool reader(String filename) {
    open(filename);
    bool result = readDBF();
    close();
    return result;
  }

  bool writer(String filename) {
    open(filename);
    bool result = writeDBF();
    close();
    return result;
  }

  bool writerEntirety(
      String filename, List<CDbaseField> fields, List<List<dynamic>> records) {
    this.fields = fields;
    this.records = records;
    if (analysis()) {
      return writer(filename);
    }
    return false;
  }

  bool analysis() {
    for (int n = 0; n < records.length; ++n) {
      var list = records[n];
      if (fields.length != list.length) {
        onError?.call("field 길이와 record 데이터의 길이가 다릅니다.");
        return false;
      }

      for (int i = 0; i < fields.length; ++i) {
        var field = fields[i];
        switch (field.type) {
          case "C": // Character
            if (list[i] is! String) {
              onError?.call("C(String) 타입 데이터가 아닙니다. ${list[i].runtimeType}");
              return false;
            }
            String data = list[i];
            var len = isCp949
                ? cp949.encode(data).length
                : isUtf8
                ? utf8.encode(data).length
                : data.length;
            if (len >= field.fieldLength) {
              field.fieldLength = len + 1;
              // 필드 길이를 넘는 문제가 발생하기 때문에 길이 조절이 필요하다.
              // debugPrint("$n , $i - $len , ${field.fieldLength}");
            }
            break;
          case "D":
            if (list[i] is! DateTime) {
              onError?.call("D(DateTime) 타입 데이터가 아닙니다. ${list[i].runtimeType}");
              return false;
            }
            break;
          case "F":
            if (list[i] is! double) {
              onError?.call("F(double) 타입 데이터가 아닙니다. ${list[i].runtimeType}");
              return false;
            }
            break;
          case "N":
            if (list[i] is double) {
              if (0 == field.fieldCount) {
                onError?.call("N(double) 타입은 field count가 0보다 커야 합니다.");
                return false;
              }
            } else if (list[i] is! int) {
              onError?.call("N(int) 타입 데이터가 아닙니다. ${list[i].runtimeType}");
              return false;
            }
            break;
          case "L":
            if (list[i] is! bool) {
              onError?.call("L(bool) 타입 데이터가 아닙니다. ${list[i].runtimeType}");
              return false;
            }
            break;
        // case "M":
        //   break;
          default:
            onError?.call("지원하지 않는 field 타입 입니다. ${field.type}");
            return false;
        }
      }
    }
    return true;
  }

  void close() {
    _fileDBF = null;
    _rafDBF?.close();
    _rafDBF = null;
    _recordCount = 0;
    _headerLength = 0;
    _recordLength = 0;
    _fileLength = -1;
  }
  
  void dispose() {
    fields = [];
    records = [];
    close();
  }
}
