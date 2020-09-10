import 'dart:convert';

import 'package:discord_price_watcher/config.dart';
import 'package:discord_price_watcher/product_list.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

import '../../log.dart';
class AnimeversandSalesProductList extends ProductList {

  @override
  String Name = 'AnimeVersandSales';

  @override
  Future<List<Element>> retrieveData() async {

    http.Client client = http.Client();
    http.Response resCSRF = await client.get('https://www.animeversand.com/csrftoken',headers: headerHandler.getHeaders('www.animeversand.com'));
    String csrf = resCSRF.headers['x-csrf-token'];

    headerHandler.setCookie('language', 'de_DE', 'www.animeversand.com');
    headerHandler.setCookie('amazon-pay-cors-blocked-status', 'true', 'www.animeversand.com');
    headerHandler.setCookie('x-ua-device', 'desktop', 'www.animeversand.com');
    headerHandler.setCookie('amazon-pay-connectedAuth', 'connectedAuth_general', 'www.animeversand.com');
    headerHandler.setCookie('__csrf_token-1', csrf, 'www.animeversand.com');

    String sessionCookie = resCSRF.headers['set-cookie'];
    headerHandler.decodeCookiesString(sessionCookie, 'www.animeversand.com');
    headerHandler.setHeaderField('X-Requested-With', 'XMLHttpRequest', 'www.animeversand.com');

    int pageNumber = 1;
    List<Element> elements = [];
    int totalCount;

    do {
      if(pageNumber > 1){
        headerHandler.setHeaderField('Referer', 'https://www.animeversand.com/sale/?p='+pageNumber.toString(), 'www.animeversand.com');
      }
      http.Response res = await http.get(
        'https://www.animeversand.com/widgets/listing/listingCount/sCategory/45?p='+pageNumber.toString()+'&c=45&o=1&n=50&loadProducts=1',
        headers: headerHandler.getHeaders('www.animeversand.com')
      );
      Map jsonMap = jsonDecode(res.body);
      elements.addAll(parse(jsonMap['listing']).getElementsByClassName('box--minimal'));
      totalCount = jsonMap['totalCount'];
      pageNumber++;
    } while(totalCount > elements.length);
    return elements;
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