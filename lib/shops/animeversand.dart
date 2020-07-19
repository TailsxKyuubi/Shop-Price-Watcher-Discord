import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import '../product.dart';
import 'package:http/http.dart' as http;

class AnimeVersandProduct extends Product {

  String currency = '€';

  @override
  Future<bool> check(String url) async {
    http.Response res = await http.get(url);
    if(res.statusCode == 404){
      return false;
    }
    Document html = parse(res.body);
    if(html.querySelector('h1.product--title[itemprop=name]') == null){
      return false;
    }
    return true;
  }

  @override
  double retrievePrice(String productData) {
    Document html = parse(productData);
    return double.tryParse(html.querySelector('meta[itemprop=price]').attributes['content']);
  }

  @override
  String retrieveSKU(String productData) {
    Document html = parse(productData);
    return html.querySelector('.base-info--entry.entry--sku > .entry--content').text;
  }

  @override
  String retrieveTitle(String productData) {
    Document html = parse(productData);
    return html.querySelector('h1.product--title[itemprop=name]').innerHtml;
  }

  @override
  bool checkForPromo(String productData) {
    return false;
  }

}