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
      productId: fields[0] as String,
      productName: fields[1] as String?,
      productType: fields[2] as String?,
      purchaseDate: fields[3] as String?,
      price: fields[4] as String?,
      warrantyStartDate: fields[5] as String?,
      warrantyEndDate: fields[6] as String?,
      productDescription: fields[7] as String?,
      insuranceDate: fields[8] as String?,
      insuranceExpiryDate: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.productType)
      ..writeByte(3)
      ..write(obj.purchaseDate)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.warrantyStartDate)
      ..writeByte(6)
      ..write(obj.warrantyEndDate)
      ..writeByte(7)
      ..write(obj.productDescription)
      ..writeByte(8)
      ..write(obj.insuranceDate)
      ..writeByte(9)
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
