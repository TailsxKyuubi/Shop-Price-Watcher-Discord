import 'package:discord_price_watcher/product.dart';
import 'package:html/parser.dart' show parse;

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
  double retrievePrice(String productData) {
    var html = parse(productData);
    return double.tryParse(
        html.querySelector('meta[itemprop=price]').attributes['content']
    );
  }

  @override
  String retrieveSKU(String productData) {
    var html = parse(productData);
    return html.querySelector('meta[itemprop=sku]').attributes['content'];
  }

  @override
  String retrieveTitle(String productData) {
    var html = parse(productData);
    return html.querySelector('h1[itemprop=name]').innerHtml;
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