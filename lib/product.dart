import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nyxx/nyxx.dart';
import 'package:discord_price_watcher/config.dart';
import 'package:discord_price_watcher/product_history.dart';

abstract class Product {
  String Url;
  List<ProductHistory> _priceHistory = [];
  List<int> _channels = [];
  String currency = '\$';
  String sku;
  String title;
  Timer _timer;

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

  void initiateTimer(){
    if(this._timer == null){
      print('setup timer');
      // running the loop until the bots stops
      this._timer = Timer.periodic(Duration(hours: 6), (timer) {
        print('initialize automatic check attempt');
        this.checkForUpdatePrice();
      });
    }
  }

  Future<double> retrievePrice();

  Future<bool> check( String url );

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
    this._priceHistory.forEach(( ProductHistory element ){
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

  Future<void> checkForUpdatePrice() async{
    print('checking for new price from ' + this.title);
    if( await this.updatePrice() ){
      this.getChannels().forEach((channelId) async{
        TextChannel channel = await bot.getChannel(Snowflake(channelId)) as TextChannel;
        List<ProductHistory> history = this.getPriceHistory();
        double oldPrice = history[(history.length - 2)].getPrice();
        double newPrice = history.last.getPrice();
        double priceDifference = newPrice - oldPrice;
        priceDifference = priceDifference.truncateToDouble();
        channel.send(
          content: "Das Produkt " + this.title + " hat einen neuen Preis. \n"+
              "Der Preis ist um " + (priceDifference > 0?priceDifference.toString().replaceAll('.', ',') + this.currency + ' gestiegen':(priceDifference*-1).toString().replaceAll('.', ',') + this.currency + ' gesunken') +
              '\n Der neue Preis beträgt:' + newPrice.toString() + this.currency +'\n'+this.Url,
        );
        print('found new price on ' + this.Url);
      });
    }
    this.save();
  }

  void delete(){
    this._timer.cancel();

  }

  void save(){
    print('saving product ' + this.sku);
    List<String> domainArray = this.Url.split('.');
    String shopName = domainArray[domainArray.length-2];
    File db = File('db/'+shopName+'~'+this.sku+'.json');
    if(!db.existsSync()){
      db.createSync( recursive: true );
    }
    db.writeAsStringSync(this.toJson());
    print('saved product');
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
      });
    }else{
      product.title = title;
    }
    if(sku == null){
      product.retrieveSKU().then((String value){
        product.sku = value;
      });
    }else{
      product.sku = sku;
    }
    return product;
  }
}