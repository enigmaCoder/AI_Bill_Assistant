import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0) // Assign a unique typeId for this model
class Product extends HiveObject {
  @HiveField(0)
  String productName;

  @HiveField(1)
  String? productType;

  @HiveField(2)
  String? purchaseDate;

  @HiveField(3)
  String? price;

  @HiveField(4)
  String? warrantyStartDate;

  @HiveField(5)
  String? warrantyEndDate;

  @HiveField(6)
  String? productDescription;

  @HiveField(7)
  String? insuranceDate;

  @HiveField(8)
  String? insuranceExpiryDate;

  Product({required this.productName, this.productType, this.purchaseDate, this.price, this.warrantyStartDate, this.warrantyEndDate, this.productDescription, this.insuranceDate, this.insuranceExpiryDate});

  // To convert a Map<String, String> to a Product instance
  factory Product.fromMap(Map<String, String> data) {
    return Product(
      productName: data['productName']!,
      productType: data['productType'],
      purchaseDate: data['purchaseDate'],
      price: data['price'],
      insuranceDate: data['insuranceDate'],
      insuranceExpiryDate: data['insuranceExpiryDate'],
      warrantyEndDate: data['warrantyEndDate'],
      warrantyStartDate: data['warrantyStartDate'],
      productDescription: data['productDescription'],
    );
  }

  // To convert a Product instance to a Map<String, String>
  Map<String, String> toMap() {
    return {
      'productName': productName,
      'productType': productType ?? '',
      'purchaseDate': purchaseDate ?? '',
      'price': price ?? '',
      'insuranceDate': insuranceDate ?? '',
      'insuranceExpiryDate': insuranceExpiryDate ?? '',
      'warrantyStartDate': warrantyStartDate ?? '',
      'warrantyEndDate': warrantyEndDate ?? '',
      'productDescription': productDescription ?? '',
    };
  }
}
