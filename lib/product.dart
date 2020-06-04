import 'dart:convert';
import 'package:rightstuf_price_watcher/config.dart';
import 'package:rightstuf_price_watcher/product_history.dart';

abstract class Product {
  String Url;
  List<ProductHistory> _priceHistory = [];
  List<int> _channels = [];
  String currency = '\$';
  String sku;
  String title;

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

  Future<String> retrieveSKU();

  Future<String> retrieveTitle();

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
      'sku': this.sku,
      'title': this.title,
      'channels': this._channels,
      'priceHistory': historyObjects
    };
    return jsonEncode(tmp);
  }

  static Future<Product> create( String url ) async {
    Uri uri = Uri.tryParse(url);
    if( config['supportedHosts'].indexOf(uri.host) == -1 ){
      print('site not supported');
      // TODO Write Exception for that
      return null;
    }
    Product newProduct = config['ShopCollection'].getInstanceFromShop(uri.host);
    if(await newProduct.check(url)) {
      newProduct.Url = 'https://' + uri.host + uri.path;
      newProduct.sku = await newProduct.retrieveSKU();
      newProduct.title = await newProduct.retrieveTitle();
      DateTime now = DateTime.now();
      double price = await newProduct.retrievePrice();
      ProductHistory firstPrice = ProductHistory(price,now);
      newProduct.addPriceToHistory(firstPrice);
      return newProduct;
    }
    print('check failed');
    // TODO Write Exception for that
    return null;
  }

  static Product createFromData( String url, List<int> channels, List<ProductHistory> productHistory,{String title=null, String sku=null} ){
    print('importing product');
    Product product = config['ShopCollection'].getInstanceFromShop(Uri.parse(url).host);
    product.Url = url;
    product._channels = channels;
    product._priceHistory = productHistory;
    if(title == null){
      product.retrieveTitle().then((String value){
        product.title = value;
        print(product.toJson());
      });
    }else{
      product.title = title;
    }
    if(sku == null){
      product.retrieveSKU().then((String value){
        product.sku = value;
        print(product.toJson());
      });
    }else{
      product.sku = sku;
    }
    return product;
  }
}