// lib/data/price_data.dart

/// Mock price data for items across different stores.
/// Structure:
/// {
///   "ItemName": {
///      "StoreName": price,
///      ...
///   },
///   ...
/// }
final Map<String, Map<String, double>> mockPrices = {
  "Milk": {
    "Shoprite": 23.00,
    "Pick n Pay": 25.50,
    "Spar": 26.75,
    "Woolworths": 28.20,
  },
  "Bread": {
    "Shoprite": 12.00,
    "Pick n Pay": 13.50,
    "Spar": 14.00,
    "Woolworths": 16.00,
  },
  "Eggs": {
    "Shoprite": 35.00,
    "Pick n Pay": 36.50,
    "Spar": 38.00,
    "Woolworths": 42.00,
  },
  "Chicken": {
    "Shoprite": 75.00,
    "Pick n Pay": 78.00,
    "Spar": 80.50,
    "Woolworths": 85.00,
  },
};
