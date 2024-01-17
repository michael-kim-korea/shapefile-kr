import 'package:flutter/material.dart';
import 'package:shapefile_kr/shapefile_kr.dart';

void main() {
  CShapefile reader = CShapefile(
      isUtf8: true,
      onError: (value) {
        debugPrint("$value");
      });

  String name = 'test.shp';
  reader.open(name);
  reader.readSHX();
  reader.readSHP();
  reader.readDBF();
  reader.close();

  debugPrint("header: ${reader.headerSHP}");
  debugPrint("    ${reader.offsets.length}");
  debugPrint("    ${reader.offsets[0]}");
  debugPrint("    ${reader.records.length}");
  debugPrint("    ${reader.records[0]}");
  debugPrint("attribute: ${reader.attributeFields}");
  debugPrint("    ${reader.attributeFields.length}");
  debugPrint("    ${reader.attributeFields[0]}");
  debugPrint("    ${reader.attributeRecords.length}");
  debugPrint("    ${reader.attributeRecords[0]}");

  name = 'test_write.shp';
  reader.open(name);
  reader.writeSHX();
  reader.writeSHP();
  reader.writeDBF();
  reader.close();

  var writer = CShapefile(onError: (value) {
    debugPrint("$value");
  });

  var records = [CPoint()..X = 23.133..Y=123.213];
  var attrFields = [CDbaseField.fieldN("NO"), CDbaseField.fieldNF("X"), CDbaseField.fieldNF("Y")];
  var attrRecords = [[1, 23.123, 123.213]];

  if (writer.writerEntirety("test_entirety.shp", CShapeType.POINT, records,
      minX: 23.1234,
      minY: 125.234,
      maxX: 23.2234,
      maxY: 125.434,
      attributeFields: attrFields,
      attributeRecords: attrRecords)) {
    debugPrint("${writer.records}");
  }
}

