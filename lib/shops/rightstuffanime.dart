import 'dart:convert';

import 'package:discord_price_watcher/product.dart';
import 'package:http/http.dart' as http;
import 'package:discord_price_watcher/config.dart';

class RightStufAnimeProduct extends Product {
  String get currency => '\$';

  @override
  double retrievePrice(productData) {
    Map dataList = jsonDecode(productData);
    double price = dataList['items'][0]['onlinecustomerprice_detail']['onlinecustomerprice'];
    return price;
  }

  @override
  Future<bool> check(String url) async {
    Uri uri = Uri.parse(url);
    headerHandler.setHeaderField('Referrer', this.Url, 'www.rightstufanime.com');
    if(uri.path == '/'){
      return false;
    }
    http.Response res = await http.get(
      'https://www.rightstufanime.com/api/items?country=US&currency=USD&fieldset=details&include=facets&language=en&pricelevel=5&url='+uri.path.substring(1),
      headers: headerHandler.getHeaders('www.rightstufanime.com')
    );
    if(res.statusCode == 200){
      return true;
    } else {
      return false;
    }
  }

  @override
  String retrieveSKU(String productData) {
    Map dataList = jsonDecode(productData);
    return dataList['items'][0]['itemid'];
  }

  @override
  String retrieveTitle(String productData) {
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
    headerHandler.setHeaderField('Referrer', this.Url, 'www.rightstufanime.com');
    http.Response res = await http.get(
      'https://www.rightstufanime.com/api/items?country=US&currency=USD&fieldset=details&include=facets&language=en&pricelevel=5&url='+path,
      headers: headerHandler.getHeaders('www.rightstufanime.com')
    );
    return res.body;
  }

}