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
  Future<double> retrievePrice() async {
    http.Response res = await http.get(this.Url);
    Document html = parse(res.body);
    return double.tryParse(html.querySelector('meta[itemprop=price]').attributes['content']);
  }

  @override
  Future<String> retrieveSKU() async {
    http.Response res = await http.get(this.Url);
    Document html = parse(res.body);
    return html.querySelector('.base-info--entry.entry--sku > .entry--content').text;
  }

  @override
  Future<String> retrieveTitle() async {
    http.Response res = await http.get(this.Url);
    Document html = parse(res.body);
    return html.querySelector('h1.product--title[itemprop=name]').innerHtml;
  }

}