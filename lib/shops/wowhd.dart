import 'package:discord_price_watcher/product.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;

class WowHdProduct extends Product {
  @override
  Future<bool> check(String url) async {
    http.Response res = await http.get(url);
    if(res.statusCode == 404){
      return false;
    }
    Document html = parse(res.body);
    Element checkElement = html.querySelector('.aec-product-title > .aec-toptitle > .aec-maintitle > h1 ');
    if(checkElement != null){
      return true;
    }else{
      return true;
    }
  }

  @override
  bool checkForPromo(String url) {
    return false;
  }

  @override
  double retrievePrice(String productData) {
    Document html = parse(productData);
    return double.parse(
        html.querySelector('.aec-price > .aec-webamiprice-href > .aec-custprice > span')
        .innerHtml.replaceAll('\$', ''));
  }

  @override
  String retrieveSKU(String productData) {
    return this.Url.split('/').last;
  }

  @override
  String retrieveTitle(String productData) {
    Document html = parse(productData);
    return html.querySelector('#aec-product-title > .aec-toptitle > .aec-maintitle > h1 ').innerHtml;
  }
  
}