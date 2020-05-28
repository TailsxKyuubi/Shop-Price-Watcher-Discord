import 'dart:convert';

import 'package:rightstuf_price_watcher/product.dart';
import 'package:http/http.dart' as http;

class RightStufAnimeProduct extends Product {
  String get currency => '\$';

  @override
  Future<double> retrievePrice() async {
    String path = Uri.parse(Url).path.substring(1);
    http.Response res = await http.get('https://www.rightstufanime.com/api/items?country=US&currency=USD&fieldset=details&include=facets&language=en&pricelevel=5&url='+path);
    Map dataList = jsonDecode(res.body);
    double price = dataList['items'][0]['onlinecustomerprice_detail']['onlinecustomerprice'];
    return price;
  }

  @override
  Future<bool> check(String url) async {
    Uri uri = Uri.parse(url);
    if(uri.path == '/'){
      return false;
    }
    http.Response res = await http.get('https://www.rightstufanime.com/api/items?country=US&currency=USD&fieldset=details&include=facets&language=en&pricelevel=5&url='+uri.path);
    if(res.statusCode == 200){
      return true;
    } else {
      return false;
    }
  }

}