import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'mdl_dbasefile.dart';

class COffset {
  COffset(this.offset, this.length);
  final int offset;
  final int length;

  @override
  String toString() {
    return "{$offset, $length}";
  }
}

class CShapeType {
  final int id;
  final String type;

  const CShapeType._(this.id, this.type);

  static const NULL = CShapeType._(0, 'Null');
  static const POINT = CShapeType._(1, 'Point');
  static const POINTZ = CShapeType._(11, 'PointZ');
  static const POINTM = CShapeType._(21, 'PointM');
  static const POLYLINE = CShapeType._(3, 'PolyLine');
  static const POLYLINEZ = CShapeType._(13, 'PolyLineZ');
  static const POLYLINEM = CShapeType._(23, 'PolyLineM');
  static const POLYGON = CShapeType._(5, 'Polygon');
  static const POLYGONZ = CShapeType._(15, 'PolygonZ');
  static const POLYGONM = CShapeType._(25, 'PolygonM');
  static const MULTIPOINT = CShapeType._(8, 'MultiPoint');
  static const MULTIPOINTZ = CShapeType._(18, 'MultiPointZ');
  static const MULTIPOINTM = CShapeType._(28, 'MultiPointM');
  static const MULTIPATCH = CShapeType._(31, 'MultiPointM');
  static const UNDEFINED = CShapeType._(-1, 'Undefined');

  @override
  String toString() {
    return type;
  }

  bool isPointType() {
    return id % 10 == 1;
  }

  bool isLineType() {
    return id % 10 == 3;
  }

  bool isPolygonType() {
    return id % 10 == 5;
  }

  bool isMultiPointType() {
    return id % 10 == 8;
  }

  static CShapeType toType(int id) {
    switch (id) {
      case 0:
        return NULL;
      case 1:
        return POINT;
      case 11:
        return POINTZ;
      case 21:
        return POINTM;
      case 3:
        return POLYLINE;
      case 13:
        return POLYLINEZ;
      case 23:
        return POLYLINEM;
      case 5:
        return POLYGON;
      case 15:
        return POLYGONZ;
      case 25:
        return POLYGONM;
      case 8:
        return MULTIPOINT;
      case 18:
        return MULTIPOINTZ;
      case 28:
        return MULTIPOINTM;
    // case 31:
    //   return MULTIPATCH:
      default:
        return UNDEFINED;
    }
  }
}

// class CBound {
//   double minX = 0.0;
//   double minY = 0.0;
//   double maxX = 0.0;
//   double maxY = 0.0;
//
//   @override
//   String toString() {
//     return "{$minX, $minY, $maxX, $maxY}";
//   }
// }

abstract class CRecord {
  CShapeType type = CShapeType.UNDEFINED;
}

class CPoint extends CRecord {
  double X = 0.0;
  double Y = 0.0;

  CPoint() {
    type = CShapeType.POINT;
  }

  List toList() {
    return [X, Y];
  }

  @override
  String toString() {
    return "{$X, $Y}";
  }
}

class CPointM extends CPoint {
  double M = 0.0;

  CPointM() {
    type = CShapeType.POINTM;
  }

  List toList() {
    return [...super.toList(), M];
  }

  @override
  String toString() {
    return "{$X, $Y, $M}";
  }
}

class CPointZ extends CPointM {
  double Z = 0.0;

  CPointZ() {
    type = CShapeType.POINTZ;
  }

  List toList() {
    return [...super.toList(), Z];
  }

  @override
  String toString() {
    return "{$X, $Y, $Z, $M}";
  }
}

class CMultiPoint extends CRecord {
  double minX = 0.0;
  double minY = 0.0;
  double maxX = 0.0;
  double maxY = 0.0;

  int numPoints = 0;
  List<CPoint> points = [];

  CMultiPoint() {
    type = CShapeType.MULTIPOINT;
  }

  List toList() {
    return [minX, minY, maxX, maxY,
      [for(int i=0; i <numPoints; ++i) [points[i].X, points[i].Y],],
    ];
  }

  @override
  String toString() {
    return "{($minX, $minY, $maxX, $maxY), $numPoints, $points}";
  }
}

class CMultiPointM extends CMultiPoint {
  double minM = 0.0;
  double maxM = 0.0;
  List<double> arrayM = [];

  CMultiPointM() {
    type = CShapeType.MULTIPOINTM;
  }

  List toList() {
    return [...super.toList(), minM, maxM, arrayM];
  }

  @override
  String toString() {
    return "{($minX, $minY, $maxX, $maxY), $numPoints, $points, $minM, $maxM, $arrayM}";
  }
}

class CMultiPointZ extends CMultiPointM {
  double minZ = 0.0;
  double maxZ = 0.0;
  List<double> arrayZ = [];

  CMultiPointZ() {
    type = CShapeType.MULTIPOINTZ;
  }

  List toList() {
    return [...super.toList(), minZ, maxZ, arrayZ];
  }

  @override
  String toString() {
    return "{($minX, $minY, $maxX, $maxY), $numPoints, $points, $minM, $maxZ, $arrayZ, $maxM, $arrayM}";
  }
}

class CPolyline extends CRecord {
  double minX = 0.0;
  double minY = 0.0;
  double maxX = 0.0;
  double maxY = 0.0;

  int numParts = 0;
  int numPoints = 0;

  List<int> parts = [];
  List<CPoint> points = [];

  CPolyline() {
    type = CShapeType.POLYLINE;
  }

  List toList() {
    return [minX, minY, maxX, maxY,
      parts,
      [for(int i=0; i <numPoints; ++i) [points[i].X, points[i].Y],]
    ];
  }

  @override
  String toString() {
    return "{($minX, $minY, $maxX, $maxY)\n$numParts, $parts\n$numPoints, $points}";
  }
}

class CPolylineM extends CPolyline {
  double minM = 0.0;
  double maxM = 0.0;

  List<double> arrayM = [];

  CPolylineM() {
    type = CShapeType.POLYLINEM;
  }

  List toList() {
    return [...super.toList(), minM, maxM, arrayM];
  }

  @override
  String toString() {
    return "{($minX, $minY, $maxX, $maxY)\n$numParts, $parts\n$numPoints, $points\n$minM, $maxM, $arrayM}";
  }
}

class CPolylineZ extends CPolylineM {
  double minZ = 0.0;
  double maxZ = 0.0;

  List<double> arrayZ = [];

  CPolylineZ() {
    type = CShapeType.POLYLINEZ;
  }

  List toList() {
    return [...super.toList(), minZ, maxZ, arrayZ];
  }

  @override
  String toString() {
    return "{($minX, $minY, $maxX, $maxY)\n$numParts, $parts\n$numPoints, $points\n$minZ, $maxZ, $arrayZ\n$minM, $maxM, $arrayM}";
  }
}

class CPolygon extends CPolyline {

  CPolygon() {
    type = CShapeType.POLYGON;
  }
}

class CPolygonM extends CPolylineM {

  CPolygonM() {
    type = CShapeType.POLYGONM;
  }
}

class CPolygonZ extends CPolylineZ {

  CPolygonZ() {
    type = CShapeType.POLYGONZ;
  }
}

class CMultiPath extends CPolylineZ {
  List<int> partTypes = [];

  CMultiPath() {
    type = CShapeType.MULTIPATCH;
  }

  List toList() {
    return [...super.toList(), partTypes];
  }

  @override
  String toString() {
    return "{($minX, $minY, $maxX, $maxY)\n$numParts, $parts, $partTypes\n$numPoints, $points\n$minZ, $maxZ, $arrayZ\n$minM, $maxM, $arrayM}";
  }

}

class CShapeHeader {
  static const FILECODE = 9994;
  static const VERSION = 1000;

  // Big
  int fileCode = 0;   // 9994
  int length = 0;

  // Little
  int version = 0;    // 1000
  CShapeType type = CShapeType.UNDEFINED;
  double minX = 0.0;
  double minY = 0.0;
  double maxX = 0.0;
  double maxY = 0.0;
  double minZ = 0.0;
  double maxZ = 0.0;
  double minM = 0.0;
  double maxM = 0.0;

  int fileLength = 0;

  String checkCode() {
    if (fileCode != FILECODE) {
      return "Wrong magic number, expected $FILECODE, got $fileCode";
    }
    return "";
  }

  String checkVersion() {
    if (version != VERSION) {
      return "Wrong version, expected $VERSION, got $version";
    }
    return "";
  }

  void setBound(double xMin, double yMin, double xMax, double yMax,
      [double zMin = 0.0, double zMax = 0.0, double mMin = 0.0, double mMax = 0.0]) {
    minX = xMin; minY = yMin; maxX = xMax;  maxY = yMax;
    minZ = zMin; maxZ = zMax; minM = mMin; maxM = mMax;
  }

  @override
  String toString() {
    return "{$type, $length, X($minX, $minY), Y($maxX, $maxY), Z($minZ, $minZ), M($maxM, $maxM)}";
  }
}

class CShapefile {
  CShapefile({this.isUtf8 = false, this.isCp949 = false, this.onError});
  // static const LEN_MAX_BUFFER = 65535;
  // static const LEN_MAX_BUFFER = 1000000;

  static const LEN_WORD = 2;
  static const LEN_INIEGER = 4;
  static const LEN_DOUBLE = 8;
  static const LEN_POINTS = 16;
  static const LEN_HEADER = 100;
  static const LEN_RECORD_HEADER = 8;

  int lenMaxBuffer = 65535;

  bool isUtf8;
  bool isCp949;

  String? _fNameSHX;
  File? _fileSHX;
  RandomAccessFile? _rafSHX;

  String? _fNameSHP;
  File? _fileSHP;
  RandomAccessFile? _rafSHP;

  String? _fNameDBF;

  final ValueChanged? onError;

  final headerSHX = CShapeHeader();
  final headerSHP = CShapeHeader();

  CDbaseFile? _dbase;

  //int fieldCount = 0;
  List<COffset> offsets = [];
  List<CRecord> records = [];

  get attributeFields => _dbase == null ? [] : _dbase!.fields;
  get attributeRecords => _dbase == null ? [] : _dbase!.records;

  void open(String shpFile) {
    close();
    String name = shpFile.substring(0, shpFile.lastIndexOf("."));
    _fNameSHX = "$name.shx";
    _fNameSHP = "$name.shp";
    _fNameDBF = "$name.dbf";
  }

  bool readSHX() {
    if (null == _fNameSHX) {
      onError?.call("SHX 파일 이름이 없습니다. open을 실행 하십시요.");
      return false;
    }

    Uint8List? bufferSHX;
    try {
      _fileSHX = File(_fNameSHX!);
      bufferSHX = _fileSHX?.readAsBytesSync();
    } catch(e) {
      onError?.call("SHX 파일 열기/일기 오류: $e");
      return false;
    }

    int pos = 0;
    if (null != bufferSHX) {
      String errText = "";
      ByteData dataSHX = ByteData.sublistView(bufferSHX);

      headerSHX.fileCode = dataSHX.getInt32(0, Endian.big);
      errText = headerSHX.checkCode();
      if (errText.isNotEmpty) {
        onError?.call(errText);
        return false;
      }
      // skip position 20
      headerSHX.length = dataSHX.getInt32(24, Endian.big);
      headerSHX.version = dataSHX.getInt32(28, Endian.little);
      errText = headerSHX.checkVersion();
      if (errText.isNotEmpty) {
        onError?.call(errText);
        return false;
      }
      headerSHX.type = CShapeType.toType(dataSHX.getInt32(32, Endian.little));
      headerSHX.minX = dataSHX.getFloat64(36, Endian.little);
      headerSHX.minY = dataSHX.getFloat64(44, Endian.little);
      headerSHX.maxX = dataSHX.getFloat64(52, Endian.little);
      headerSHX.maxY = dataSHX.getFloat64(60, Endian.little);

      headerSHX.minZ = dataSHX.getFloat64(68, Endian.little);
      headerSHX.maxZ = dataSHX.getFloat64(76, Endian.little);
      headerSHX.minM = dataSHX.getFloat64(84, Endian.little);
      headerSHX.maxM = dataSHX.getFloat64(92, Endian.little);

      headerSHX.fileLength = headerSHX.length * LEN_WORD;
      int fieldCount = (headerSHX.fileLength - LEN_HEADER) ~/ LEN_RECORD_HEADER;

      // debugPrint("header ${headerSHX.fileLength}, $fieldCount");

      pos += LEN_HEADER;
      for (int n = 0; n < fieldCount; ++n) {
        int offset = dataSHX.getInt32(pos, Endian.big) * LEN_WORD;
        int content = dataSHX.getInt32(pos + 4, Endian.big) * LEN_WORD;
        offsets.add(COffset(offset, content));
        // if (n < 2) {
        //   debugPrint("$offset, $content");
        // }
        pos += LEN_RECORD_HEADER;
        // debugPrint("line $n");
      }
    }
    // debugPrint("SHX file position: $pos / ${headerSHX.fileLength}");
    return true;
  }

  bool readSHP() {
    if (null == _fNameSHP) {
      onError?.call("SHP 파일 이름이 없습니다. open을 실행 하십시요.");
      return false;
    }

    int workPosition =0;
    int filePosition = 0;

    Uint8List? bufferSHP;
    try {
      _fileSHP = File(_fNameSHP!);
      _rafSHP = _fileSHP!.openSync();
      bufferSHP = _rafSHP!.readSync(LEN_HEADER);
      filePosition += LEN_HEADER;
      // debugPrint("file position: $filePosition");
    } catch(e) {
      onError?.call("SHP 파일 열기/읽기 오류: $e");
      return false;
    }

    ByteData dataSHP = ByteData.sublistView(bufferSHP);

    headerSHP.fileCode = dataSHP.getInt32(0, Endian.big);
    // skip position 20
    headerSHP.length = dataSHP.getInt32(24, Endian.big);
    headerSHP.version = dataSHP.getInt32(28, Endian.little);
    headerSHP.type = CShapeType.toType(dataSHP.getInt32(32, Endian.little));
    headerSHP.minX = dataSHP.getFloat64(36, Endian.little);
    headerSHP.minY = dataSHP.getFloat64(44, Endian.little);
    headerSHP.maxX = dataSHP.getFloat64(52, Endian.little);
    headerSHP.maxY = dataSHP.getFloat64(60, Endian.little);

    headerSHP.minZ = dataSHP.getFloat64(68, Endian.little);
    headerSHP.maxZ = dataSHP.getFloat64(76, Endian.little);
    headerSHP.minM = dataSHP.getFloat64(84, Endian.little);
    headerSHP.maxM = dataSHP.getFloat64(92, Endian.little);

    headerSHP.fileLength = headerSHP.length * LEN_WORD;

    // debugPrint("header ${headerSHP.fileCode}, ${headerSHP.version}, ${offsets.length} ");

    if (headerSHX.fileCode != headerSHP.fileCode) {
      onError?.call("SHP 파일 file code 오류 ${headerSHP.fileCode}");
      return false;
    }
    if (headerSHX.version != headerSHP.version) {
      onError?.call("SHP 파일 version 오류 ${headerSHP.version}");
      return false;
    }
    workPosition += LEN_HEADER;

    int totalCount = 0;
    while(totalCount < offsets.length) {
      int length = 0, count = 0;
      for(var n=totalCount; n < offsets.length; ++n) {
        // debugPrint("record : $n, ${offsets[n].length}");
        int fieldLength = (LEN_RECORD_HEADER + offsets[n].length);
        if ((length + fieldLength) > lenMaxBuffer) {
          if (0 == count) {
            lenMaxBuffer = fieldLength;
          } else {
            break;
          }
        }
        count++;
        length += fieldLength;
      }
      //debugPrint("record length : $count, $length");
      
      bufferSHP = null;
      try {
        bufferSHP = _rafSHP!.readSync(length);
        filePosition += length;
        // debugPrint("file position: $filePosition");
      } catch (e) {
        onError?.call("SHP 파일 읽기 오류: $e");
        return false;
      }
      dataSHP = ByteData.sublistView(bufferSHP);
      int pos = 0;
      for (var n = 0; n < count; ++n) {
        // int offset = dataSHP.getInt32(pos, Endian.big);
        // int content = dataSHP.getInt32(pos + 4, Endian.big) * LEN_WORD;
        // if (n < 2) {
        //   debugPrint("record header: ${totalCount+n}, $offset, $content");
        // }
        pos += LEN_RECORD_HEADER;
        workPosition += LEN_RECORD_HEADER;

        switch (headerSHP.type) {
          case CShapeType.POINT:
            CPoint points = CPoint();
            // int shapeType = dataSHP.getInt32(pos, Endian.little);
            // if (n < 2) {
            //   debugPrint("record shape type: $shapeType");
            // }
            points.X = dataSHP.getFloat64(pos + 4, Endian.little);
            points.Y = dataSHP.getFloat64(pos + 12, Endian.little);
            records.add(points);
            break;
          case CShapeType.POLYLINE:
            CPolyline polyline = CPolyline();
            // int shapeType = dataSHP.getInt32(pos, Endian.little);
            polyline.minX = dataSHP.getFloat64(pos+4, Endian.little);
            polyline.minY = dataSHP.getFloat64(pos+12, Endian.little);
            polyline.maxX = dataSHP.getFloat64(pos+20, Endian.little);
            polyline.maxY = dataSHP.getFloat64(pos+28, Endian.little);
            polyline.numParts = dataSHP.getInt32(pos+36, Endian.little);
            polyline.numPoints = dataSHP.getInt32(pos+40, Endian.little);
            int posPartStart = pos + 44;
            for(int iPart = 0; iPart < polyline.numParts; ++iPart ) {
              int posPart = posPartStart + iPart * LEN_INIEGER;
              polyline.parts.add(dataSHP.getInt32(posPart, Endian.little));
            }
            int posPointStart = pos + 44 + polyline.numParts * LEN_INIEGER;
            for(int iPoint = 0; iPoint < polyline.numPoints; ++iPoint ) {
              int posPoint = posPointStart + iPoint * LEN_POINTS;
              CPoint point = CPoint();
              point.X = dataSHP.getFloat64(posPoint, Endian.little);
              point.Y = dataSHP.getFloat64(posPoint+8, Endian.little);
              polyline.points.add(point);
            }
            records.add(polyline);
            break;
          case CShapeType.POLYGON:
            CPolygon polygon = CPolygon();
            // int shapeType = dataSHP.getInt32(pos, Endian.little);
            polygon.minX = dataSHP.getFloat64(pos+4, Endian.little);
            polygon.minY = dataSHP.getFloat64(pos+12, Endian.little);
            polygon.maxX = dataSHP.getFloat64(pos+20, Endian.little);
            polygon.maxY = dataSHP.getFloat64(pos+28, Endian.little);
            polygon.numParts = dataSHP.getInt32(pos+36, Endian.little);
            polygon.numPoints = dataSHP.getInt32(pos+40, Endian.little);
            int posPartStart = pos + 44;
            for(int iPart = 0; iPart < polygon.numParts; ++iPart ) {
              int posPart = posPartStart + iPart * LEN_INIEGER;
              polygon.parts.add(dataSHP.getInt32(posPart, Endian.little));
            }
            int posPointStart = pos + 44 + polygon.numParts * LEN_INIEGER;
            for(int iPoint = 0; iPoint < polygon.numPoints; ++iPoint ) {
              int posPoint = posPointStart + iPoint * LEN_POINTS;
              CPoint point = CPoint();
              point.X = dataSHP.getFloat64(posPoint, Endian.little);
              point.Y = dataSHP.getFloat64(posPoint+8, Endian.little);
              polygon.points.add(point);
            }
            records.add(polygon);
            break;
          default:
            onError?.call("unexpected shape type  ${headerSHP.type}");
            return false;
        }
        pos += offsets[totalCount+n].length;
        workPosition += offsets[totalCount+n].length;
        // if (n < 2) {
        //   debugPrint("record data: ${totalCount+n}, ${records.last}");
        // }
      }
      totalCount += count;
      // debugPrint("next: $totalCount, $count");
    }
    // debugPrint("SHP file position: $workPosition / ${headerSHP.fileLength}");
    return true;
  }

  bool readDBF() {
    if (null == _fNameDBF) return false;
    if (!File(_fNameDBF!).existsSync()) return false;

    _dbase = CDbaseFile(isUtf8:isUtf8, isCp949: isCp949, onError: onError);
    _dbase!.open(_fNameDBF!);
    bool result = _dbase!.readDBF();
    _dbase!.close();
    return result;
  }

  bool writeSHX() {
    if (null == _fNameSHX) {
      onError?.call("SHX 파일 이름이 없습니다. open을 실행 하십시요.");
      return false;
    }

    int filePosition = 0;

    Uint8List? bufferSHX;
    bufferSHX = Uint8List(LEN_HEADER);
    ByteData dataSHX = ByteData.sublistView(bufferSHX);

    headerSHX.fileCode = CShapeHeader.FILECODE;
    dataSHX.setInt32(0, headerSHX.fileCode, Endian.big);
    // skip position 20
    headerSHX.fileLength = LEN_HEADER + offsets.length * LEN_RECORD_HEADER;
    headerSHX.length = headerSHX.fileLength ~/ LEN_WORD;;
    dataSHX.setInt32(24, headerSHX.length, Endian.big);
    headerSHX.version = CShapeHeader.VERSION;
    dataSHX.setInt32(28, headerSHX.version, Endian.little);

    dataSHX.setInt32(32, headerSHX.type.id, Endian.little);

    dataSHX.setFloat64(36, headerSHX.minX, Endian.little);
    dataSHX.setFloat64(44, headerSHX.minY, Endian.little);
    dataSHX.setFloat64(52, headerSHX.maxX, Endian.little);
    dataSHX.setFloat64(60, headerSHX.maxY, Endian.little);

    dataSHX.setFloat64(68, headerSHX.minZ, Endian.little);
    dataSHX.setFloat64(76, headerSHX.maxZ, Endian.little);
    dataSHX.setFloat64(84, headerSHX.minM, Endian.little);
    dataSHX.setFloat64(92, headerSHX.maxM, Endian.little);

    // debugPrint("header $headerSHX");

    try {
      _fileSHX = File(_fNameSHX!);
      _rafSHX = _fileSHX!.openSync(mode: FileMode.write);
      _rafSHX!.writeFromSync(bufferSHX);
      filePosition += LEN_HEADER;
    } catch(e) {
      onError?.call("SHX 파일 열기/저장 오류: $e");
      return false;
    }

    bufferSHX = Uint8List(lenMaxBuffer);
    dataSHX = ByteData.sublistView(bufferSHX);

    int pos = 0;
    int totalCount = 0;
    while(totalCount < offsets.length) {
      int length = 0, count = 0;
      length = (offsets.length - totalCount) * LEN_RECORD_HEADER;
      if (length > lenMaxBuffer) {
        count = lenMaxBuffer ~/ LEN_RECORD_HEADER;
        length = LEN_RECORD_HEADER * count;
      } else {
        count = length ~/ LEN_RECORD_HEADER;
      }

      pos = 0;
      for (var n = 0; n < count; ++n) {
        var offset = offsets[totalCount + n];
        dataSHX.setInt32(pos, offset.offset ~/ LEN_WORD, Endian.big);
        dataSHX.setInt32(pos + 4, offset.length ~/ LEN_WORD, Endian.big);
        pos += LEN_RECORD_HEADER;
        // if (n < 3) {
        //   debugPrint("$offset");
        // }
      }
      totalCount += count;

      try {
        _rafSHX!.writeFromSync(bufferSHX, 0, pos);
        filePosition += pos;
        // debugPrint("file position: $filePosition");
      } catch (e) {
        onError?.call("DBF 파일 저장 오류: $e");
        return false;
      }
    }
    // debugPrint("SHX file position: $filePosition / ${headerSHX.fileLength}");
    return true;
  }

  bool writeSHP() {
    if (null == _fNameSHP) {
      onError?.call("SHP 파일 이름이 없습니다. open을 실행 하십시요.");
      return false;
    }
    if (0 == headerSHP.length) {
      if (!analysis()) return false;
    }

    int workPosition = 0;
    int filePosition = 0;

    Uint8List? bufferSHP;
    bufferSHP = Uint8List(LEN_HEADER);
    ByteData dataSHP = ByteData.sublistView(bufferSHP);

    headerSHP.fileCode = CShapeHeader.FILECODE;
    dataSHP.setInt32(0, headerSHP.fileCode, Endian.big);
    // skip position 20
    headerSHP.fileLength = headerSHP.length * LEN_WORD;
    dataSHP.setInt32(24, headerSHP.length, Endian.big);
    headerSHP.version = CShapeHeader.VERSION;
    dataSHP.setInt32(28, headerSHP.version, Endian.little);

    dataSHP.setInt32(32, headerSHP.type.id, Endian.little);

    dataSHP.setFloat64(36, headerSHP.minX, Endian.little);
    dataSHP.setFloat64(44, headerSHP.minY, Endian.little);
    dataSHP.setFloat64(52, headerSHP.maxX, Endian.little);
    dataSHP.setFloat64(60, headerSHP.maxY, Endian.little);

    dataSHP.setFloat64(68, headerSHP.minZ, Endian.little);
    dataSHP.setFloat64(76, headerSHP.maxZ, Endian.little);
    dataSHP.setFloat64(84, headerSHP.minM, Endian.little);
    dataSHP.setFloat64(92, headerSHP.maxM, Endian.little);

    workPosition += LEN_HEADER;

    try {
      _fileSHP = File(_fNameSHP!);
      _rafSHP = _fileSHP!.openSync(mode: FileMode.write);
      _rafSHP!.writeFromSync(bufferSHP);
      filePosition += LEN_HEADER;
      // debugPrint("file position: $filePosition");
    } catch(e) {
      onError?.call("SHP 파일 열기/읽기 오류: $e");
      return false;
    }

    // debugPrint("file length ${headerSHP.length}, ${headerSHP.fileLength}");

    bufferSHP = Uint8List(lenMaxBuffer);
    dataSHP = ByteData.sublistView(bufferSHP);

    int totalCount = 0;
    while(totalCount < offsets.length) {
      int length = 0, count = 0;
      for(var n=totalCount; n < offsets.length; ++n) {
        int fieldLength = (LEN_RECORD_HEADER + offsets[n].length);
        if ((length + fieldLength) > lenMaxBuffer) {
          if (0 == count) {
            lenMaxBuffer = fieldLength;
          } else {
            break;
          }
        }
        count++;
        length += fieldLength;
      }
      // debugPrint("record length : $count, $length");

      int pos = 0;
      for (var n = 0; n < count; ++n) {
        COffset cOffset = offsets[totalCount+n];
        dataSHP.setInt32(pos, totalCount+n+1/* start 1 base */, Endian.big);
        dataSHP.setInt32(pos + 4, cOffset.length ~/ LEN_WORD, Endian.big);
        pos += LEN_RECORD_HEADER;
        workPosition += LEN_RECORD_HEADER;
        // if (n < 2) {
        //   debugPrint("record offset ${totalCount+n}, $cOffset");
        // }
        var record = records[totalCount+n];
        switch (headerSHP.type) {
          case CShapeType.POINT:
            CPoint points = record as CPoint;
            dataSHP.setInt32(pos, headerSHP.type.id, Endian.little);
            dataSHP.setFloat64(pos + 4, points.X, Endian.little);
            dataSHP.setFloat64(pos + 12, points.Y, Endian.little);
            break;
          case CShapeType.POLYLINE:
            CPolyline polyline = record as CPolyline;
            dataSHP.setInt32(pos, headerSHP.type.id, Endian.little);
            dataSHP.setFloat64(pos+4, polyline.minX, Endian.little);
            dataSHP.setFloat64(pos+12, polyline.minY, Endian.little);
            dataSHP.setFloat64(pos+20, polyline.maxX, Endian.little);
            dataSHP.setFloat64(pos+28, polyline.maxY, Endian.little);
            dataSHP.setInt32(pos+36, polyline.numParts, Endian.little);
            dataSHP.setInt32(pos+40, polyline.numPoints, Endian.little);
            int posPartStart = pos + 44;
            for(int iPart=0; iPart<polyline.numParts; ++iPart) {
              int posPart = posPartStart + iPart * LEN_INIEGER;
              dataSHP.setInt32(posPart, polyline.parts[iPart], Endian.little);
            }
            int posPointStart = pos + 44 + polyline.numParts * LEN_INIEGER;
            for(int iPoint=0; iPoint<polyline.numPoints; ++iPoint) {
              int posPoint = posPointStart + iPoint * LEN_POINTS;
              CPoint point = polyline.points[iPoint];
              dataSHP.setFloat64(posPoint, point.X, Endian.little);
              dataSHP.setFloat64(posPoint+8, point.Y, Endian.little);
            }
            break;
          case CShapeType.POLYGON:
            CPolygon polygon = record as CPolygon;
            dataSHP.setInt32(pos, headerSHP.type.id, Endian.little);
            dataSHP.setFloat64(pos+4, polygon.minX, Endian.little);
            dataSHP.setFloat64(pos+12, polygon.minY, Endian.little);
            dataSHP.setFloat64(pos+20, polygon.maxX, Endian.little);
            dataSHP.setFloat64(pos+28, polygon.maxY, Endian.little);
            dataSHP.setInt32(pos+36, polygon.numParts, Endian.little);
            dataSHP.setInt32(pos+40, polygon.numPoints, Endian.little);
            int posPartStart = pos + 44;
            for(int iPart = 0; iPart < polygon.numParts; ++iPart ) {
              int posPart = posPartStart + iPart * LEN_INIEGER;
              dataSHP.setInt32(posPart, polygon.parts[iPart], Endian.little);
            }
            int posPointStart = pos + 44 + polygon.numParts * LEN_INIEGER;
            for(int iPoint = 0; iPoint < polygon.numPoints; ++iPoint ) {
              int posPoint = posPointStart + iPoint * LEN_POINTS;
              CPoint point = polygon.points[iPoint];
              dataSHP.setFloat64(posPoint, point.X, Endian.little);
              dataSHP.setFloat64(posPoint+8, point.Y, Endian.little);
            }
            break;
          default:
            onError?.call("unexpected shape type  ${headerSHP.type}");
            return false;
        }
        pos += cOffset.length;
        workPosition += cOffset.length;
        // if (n < 2) {
        //   debugPrint("record data: ${totalCount+n}, $record");
        // }
      }
      totalCount += count;

      try {
        _rafSHP!.writeFromSync(bufferSHP, 0, pos);
        filePosition += pos;
        // debugPrint("file position: $filePosition");
      } catch (e) {
        onError?.call("SHP 파일 저장 오류: $e");
        return false;
      }
    }
    // debugPrint("SHP file position: $workPosition / ${headerSHP.fileLength}");
    return true;
  }

  bool writeDBF() {
    if (null == _fNameDBF) return false;
    if (null == _dbase) return false;

    _dbase!.open(_fNameDBF!);
    bool result = _dbase!.writeDBF();
    _dbase!.close();
    return result;
  }

  void close() {
    _fileSHX = null;
    _rafSHX?.close();
    _rafSHX = null;

    _fileSHP = null;
    _rafSHP?.close();
    _rafSHP = null;

    _dbase?.close();
  }
  
  void dispose() {
    offsets = [];
    records = [];
    close();
    _dbase?.dispose();
  }

  bool reader(String shpFile) {
    open(shpFile);
    bool result = readSHX();
    if (result) result = readSHP();
    if (result) result = readDBF();
    close();
    return result;
  }

  // 읽은 데이터를 값을 변경 한 후에 저장할때 사용.
  bool writer(String shpFile) {
    open(shpFile);
    bool result = writeSHX();
    if (result) result = writeSHP();
    if (result) result = writeDBF();
    close();
    return result;
  }

  void setHeaderType(CShapeType type) {
    headerSHX.type = type;
    headerSHP.type = type;
  }

  void setHeaderBound(double minX, double minY, double maxX, double maxY,
      [double minZ = 0.0, double maxZ = 0.0, double minM = 0.0, double maxM = 0.0]) {
    headerSHX.setBound(minX, minY, maxX, maxY, minZ, maxZ, minM, maxM);
    headerSHP.setBound(minX, minY, maxX, maxY, minZ, maxZ, minM, maxM);
  }

  void setRecords(List<CRecord> records) {
    this.records = records;
  }

  void setAttributeField(List<CDbaseField> list) {
    _dbase = _dbase??CDbaseFile(isUtf8:isUtf8, isCp949: isCp949, onError: onError);
    _dbase?.fields = list;
  }

  void setAttributeRecord(List<List<dynamic>> list) {
    _dbase = _dbase??CDbaseFile(isUtf8:isUtf8, isCp949: isCp949, onError: onError);
    _dbase?.records = list;
  }

  // 최초 데이터와 속성을 생성 후에 저장 할 때 또는 읽은 데이터를 추가 삭제 할 경우 사용.
  bool writerEntirety(String filename, CShapeType type, List<CRecord> records,
      {
        double minX = 0.0, double minY = 0.0,
        double maxX = 0.0, double maxY = 0.0,
        double minZ = 0.0, double maxZ = 0.0,
        double minM = 0.0, double maxM = 0.0,
        List<CDbaseField>? attributeFields,
        List<List<dynamic>>? attributeRecords
      }) {

    headerSHX.type = type;
    headerSHP.type = type;

    headerSHX.setBound(minX, minY, maxX, maxY, minZ, maxZ, minM, maxM);
    headerSHP.setBound(minX, minY, maxX, maxY, minZ, maxZ, minM, maxM);

    this.records = records;
    if (null != attributeFields && null != attributeRecords) {
      _dbase = _dbase ?? CDbaseFile(isUtf8:isUtf8, isCp949: isCp949, onError: onError);
      _dbase!.fields = attributeFields;
      _dbase!.records = attributeRecords;
    } else {
      _dbase?.close();
      _dbase = null;
    }

    if (analysis()) {
      return writer(filename);
    }

    return false;
  }

  bool analysis() {
    if (headerSHP.type == CShapeType.UNDEFINED) {
      onError?.call("shape file 타입이 설정 되어 있지 않습니다. setHeaderType");
      return false;
    }
    if (headerSHP.minX == headerSHP.maxX || headerSHP.minY == headerSHP.maxY) {
      onError?.call("bound가 설정 되어 있지 않습니다. setHeaderBound");
      return false;
    }

    offsets = [];
    int pos = LEN_HEADER;
    for(int n=0; n < records.length; ++n) {
      int offset = pos;
      int length = 0;
      switch (headerSHP.type) {
        case CShapeType.POINT:
          if (records[n] is CPoint) {
            length = 4 + 8 + 8;
            pos += (LEN_RECORD_HEADER + length);
          } else {
            onError?.call("Point 데이터가 아닙니다. No.$n");
            return false;
          }
          break;
        case CShapeType.POLYLINE:
          if (records[n] is CPolyline) {
            CPolyline polyline = records[n] as CPolyline;
            length = 4 + 32 + 4 + 4 + polyline.numParts * 4 + polyline.numPoints * 16;
            pos += (LEN_RECORD_HEADER + length);
          } else {
            onError?.call("Polyline 데이터가 아닙니다. No.$n");
            return false;
          }
          break;
        case CShapeType.POLYGON:
          if (records[n] is CPolygon) {
            CPolygon polygon = records[n] as CPolygon;
            length = 4 + 32 + 4 + 4 + polygon.numParts * 4 + polygon.numPoints * 16;
            pos += (LEN_RECORD_HEADER + length);
          } else {
            onError?.call("Polygon 데이터가 아닙니다. No.$n");
            return false;
          }
          break;
        default:
          onError?.call("지원하지 않는 type(${headerSHP.type}) 입니다.");
          return false;
      }
      offsets.add(COffset(offset, length));
    }
    headerSHP.fileLength = pos;
    headerSHP.length = pos ~/ LEN_WORD;

    if (null != _dbase) {
      if (!_dbase!.analysis()) return false;
    }

    return true;
  }
}