class TrolleyItem {
  final String itemName;
  final String storeName;
  final double price;

  TrolleyItem({required this.itemName, required this.storeName, required this.price});

  Map<String, dynamic> toJson() => {
        'itemName': itemName,
        'storeName': storeName,
        'price': price,
      };

  static TrolleyItem fromJson(Map<String, dynamic> json) => TrolleyItem(
        itemName: json['itemName'],
        storeName: json['storeName'],
        price: (json['price'] as num).toDouble(),
      );
}
