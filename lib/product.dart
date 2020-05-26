import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rightstuf_price_watcher/product_history.dart';

class Product {
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

  Future<double> retrievePrice() async {
    String path = Uri.parse(Url).path.substring(1);
    http.Response res = await http.get('https://www.rightstufanime.com/api/items?country=US&currency=USD&fieldset=details&include=facets&language=en&pricelevel=5&url='+path);
    Map dataList = jsonDecode(res.body);
    double price = dataList['items'][0]['onlinecustomerprice_detail']['onlinecustomerprice'];
    print(price);
    return price;
  }

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
    Product newProduct = Product();
    Uri uri = Uri.tryParse(url);
    if(uri.host == 'www.rightstufanime.com' && uri.path != '/'){
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
    Product product = Product();
    product.Url = url;
    product._channels = channels;
    product._priceHistory = productHistory;
    return product;
  }
}