import 'dart:convert';
import 'package:rightstuf_price_watcher/config.dart';
import 'package:rightstuf_price_watcher/product_history.dart';

abstract class Product {
  String Url;
  List<ProductHistory> _priceHistory = [];
  List<int> _channels = [];
  String currency = '\$';

  List<ProductHistory> getPriceHistory(){
    return _priceHistory;
  }

  List<int> getChannels(){
    return _channels;
  }
  String getUrl(){
    return this.Url;
  }

  void addPriceToHistory(ProductHistory productHistoryObject){
    _priceHistory.add(productHistoryObject);
  }

  void addChannel(int channelId){
    _channels.add(channelId);
  }

  Future<double> retrievePrice();

  Future<bool> check(String url);

  // returns true if the price changed
  Future<bool> updatePrice() async{
    print('update price');
    double newPrice = await this.retrievePrice();
    ProductHistory historyObject = ProductHistory(newPrice, DateTime.now());
    bool difference = _priceHistory.last.getPrice() != newPrice;
    this.addPriceToHistory(historyObject);
    return difference;
  }

  String toJson(){
    List<Map> historyObjects = [];
    this._priceHistory.forEach(( ProductHistory element){
      historyObjects.add(element.asMap());
    });
    Map tmp = {
      'url': this.Url,
      'channels': this._channels,
      'priceHistory': historyObjects
    };
    return jsonEncode(tmp);
  }

  static Future<Product> create( String url ) async {
    Uri uri = Uri.tryParse(url);
    if( config['supportedHosts'].indexOf(uri.host) == -1 ){
      return null;
    }
    Product newProduct = config['ShopCollection'].getInstanceFromShop(uri.host);
    if(await newProduct.check(url)) {
      newProduct.Url = 'https://' + uri.host + uri.path;
      DateTime now = DateTime.now();
      double price = await newProduct.retrievePrice();
      ProductHistory firstPrice = ProductHistory(price,now);
      newProduct.addPriceToHistory(firstPrice);
      return newProduct;
    }
    return null;
  }

  static Product createFromData( String url, List<int> channels, List<ProductHistory> productHistory ){
    Product product = config['ShopCollection'].getInstanceFromShop(Uri.parse(url).host);
    product.Url = url;
    product._channels = channels;
    product._priceHistory = productHistory;
    return product;
  }
}