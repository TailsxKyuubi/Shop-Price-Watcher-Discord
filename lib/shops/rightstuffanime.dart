import 'dart:convert';

import 'package:discord_price_watcher/product.dart';
import 'package:http/http.dart' as http;

class RightStufAnimeProduct extends Product {
  String get currency => '\$';

  @override
  Future<double> retrievePrice(productData) async {
    Map dataList = jsonDecode(productData);
    double price = dataList['items'][0]['onlinecustomerprice_detail']['onlinecustomerprice'];
    return price;
  }

  @override
  Future<bool> check(String url) async {
    Uri uri = Uri.parse(url);
    if(uri.path == '/'){
      return false;
    }
    http.Response res = await http.get('https://www.rightstufanime.com/api/items?country=US&currency=USD&fieldset=details&include=facets&language=en&pricelevel=5&url='+uri.path.substring(1));
    if(res.statusCode == 200){
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<String> retrieveSKU(String productData) async {
    Map dataList = jsonDecode(productData);
    return dataList['items'][0]['itemid'];
  }

  @override
  Future<String> retrieveTitle(String productData) async {
    Map dataList = jsonDecode(productData);
    return dataList['items'][0]['displayname'];
  }

  @override
  bool checkForPromo(String productData) {
    // no implementation needed right now
    return false;
  }

  @override
  Future<String> getProductData() async {
    String path = Uri.parse(Url).path.substring(1);
    http.Response res = await http.get('https://www.rightstufanime.com/api/items?country=US&currency=USD&fieldset=details&include=facets&language=en&pricelevel=5&url='+path);
    return res.body;
  }

}