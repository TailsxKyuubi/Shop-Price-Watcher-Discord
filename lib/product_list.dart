import 'package:discord_price_watcher/product.dart';

abstract class ProductList {
  List<Product> productList = List<Product>();
  String Url;
  String retrieveData();
  String updateList();
  bool check();
}