part of 'incident.dart';

class IncidentAdapter extends TypeAdapter<Incident> {
  @override
  final int typeId = 0;

  @override
  Incident read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Incident(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      status: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Incident obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.status);
  }
}
