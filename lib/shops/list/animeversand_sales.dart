import 'dart:convert';

import 'package:discord_price_watcher/product_list.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
class AnimeversandSalesProductList extends ProductList {

  @override
  String Name = 'AnimeVersandSales';

  @override
  Future<List<Element>> retrieveData() async {
    http.Response res = await http.get('https://www.animeversand.com/widgets/listing/listingCount/sCategory/45?p=3&c=45&o=1&n=1000&loadProducts=1');
    Map jsonMap = jsonDecode(res.body);
    return parse(jsonMap['listing']).getElementsByClassName('box--minimal');
  }

  @override
  double getPriceSingle(element) {
    Element productElement = element;
    String priceString = productElement.querySelector('.product--price-info > .product--price-outer > .product--price > .price--default')
        .innerHtml.replaceAll('€','').replaceAll(' ', '').replaceAll('*', '').replaceAll(',', '.');
    return double.tryParse(priceString);
  }

  @override
  String getSkuSingle(element) {
    Element productElement = element;
    return productElement.attributes['data-ordernumber'];
  }

  @override
  String getUrlSingle(element) {
    Element productElement = element;
    return productElement.querySelector('.product--title').attributes['href'];
  }

  @override
  String getTitleSingle(element) {
    Element productElement = element;
    return productElement.querySelector('.product--title').attributes['title'];
  }
}