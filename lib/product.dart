import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0) // Assign a unique typeId for this model
class Product extends HiveObject {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String? productName;

  @HiveField(2)
  String? productType;

  @HiveField(3)
  String? purchaseDate;

  @HiveField(4)
  String? price;

  @HiveField(5)
  String? warrantyStartDate;

  @HiveField(6)
  String? warrantyEndDate;

  @HiveField(7)
  String? productDescription;

  @HiveField(8)
  String? insuranceDate;

  @HiveField(9)
  String? insuranceExpiryDate;

  Product({required this.productId, this.productName, this.productType, this.purchaseDate, this.price, this.warrantyStartDate, this.warrantyEndDate, this.productDescription, this.insuranceDate, this.insuranceExpiryDate});

  // To convert a Map<String, String> to a Product instance
  factory Product.fromMap(Map<String, String> data) {
    return Product(
      productId: data['productId']!,
      productName: data['productName'],
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
      'productId': productId,
      'productName': productName ?? '',
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
