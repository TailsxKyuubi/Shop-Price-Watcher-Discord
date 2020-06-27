import 'package:discord_price_watcher/product.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class JbHifiProduct extends Product {

  String currency = 'AUD';

  @override
  Future<bool> check(String url) async {
    this.Url = url;
    String productData = await this.getProductData();
    try{
      String title = await this.retrieveTitle(productData);
      if(null != title && title.trim() != '' ){

      }
    }catch(e){
      return false;
    }
    return true;
  }

  @override
  Future<double> retrievePrice(String productData) async {
    var html = parse(productData);
    return double.tryParse(
        html.querySelector('meta[itemprop=price]').attributes['content']
    );
  }

  @override
  Future<String> retrieveSKU(String productData) async {
    var html = parse(productData);
    return html.querySelector('meta[itemprop=sku]').attributes['content'];
  }

  @override
  Future<String> retrieveTitle(String productData) async {
    var html = parse(productData);
    return html.querySelector('h1[itemprop=name]').attributes['content'];
  }

  @override
  Future<String> getProductData() async {
    print(this.Url);
    http.Response res = await http.get(this.Url);
    return res.body;
  }

  @override
  bool checkForPromo(String productData) {
    var html = parse(productData);
    if(html.querySelector('.product-overview .promotag-container') == null){
      return false;
    }else{
      return true;
    }
  }

}