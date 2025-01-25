// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;

  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      productName: fields[0] as String,
      productType: fields[1] as String?,
      purchaseDate: fields[2] as String?,
      price: fields[3] as String?,
      warrantyStartDate: fields[4] as String?,
      warrantyEndDate: fields[5] as String?,
      productDescription: fields[6] as String?,
      insuranceDate: fields[7] as String?,
      insuranceExpiryDate: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.productName)
      ..writeByte(1)
      ..write(obj.productType)
      ..writeByte(2)
      ..write(obj.purchaseDate)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.warrantyStartDate)
      ..writeByte(5)
      ..write(obj.warrantyEndDate)
      ..writeByte(6)
      ..write(obj.productDescription)
      ..writeByte(7)
      ..write(obj.insuranceDate)
      ..writeByte(8)
      ..write(obj.insuranceExpiryDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
