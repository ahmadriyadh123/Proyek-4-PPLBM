import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class ObjectIdAdapter extends TypeAdapter<ObjectId> {
  @override
  final int typeId = 1; // Pastikan typeId unik di luar rentang ID yang dipakai oleh LogModel (misalkan 0)

  @override
  ObjectId read(BinaryReader reader) {
    return ObjectId.fromHexString(reader.readString());
  }

  @override
  void write(BinaryWriter writer, ObjectId obj) {
    writer.writeString(obj.toHexString());
  }
}
