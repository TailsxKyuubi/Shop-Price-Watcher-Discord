import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nyxx/nyxx.dart';
import 'package:discord_price_watcher/config.dart';
import 'package:discord_price_watcher/product_history.dart';

import 'package:discord_price_watcher/log.dart';

abstract class Product {
  String Url;
  List<ProductHistory> _priceHistory = [];
  List<int> _channels = [];
  String currency = '\$';
  String sku;
  String title;
  bool active = true;
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
      Log.info('setup timer');
      // running the loop until the bots stops
      this._timer = Timer.periodic(Duration(hours: 6), (timer) {
        Log.info('initialize automatic check attempt');
        this.checkForUpdatePrice();
      });
    }
  }

  Future<double> retrievePrice(String productData);

  Future<bool> check( String url );

  Future<String> retrieveSKU(String productData);

  Future<String> retrieveTitle(String productData);

  Future<String> getProductData();

  bool checkForPromo(String productData);

  // returns true if the price changed
  Future<bool> updatePrice() async{
    Log.info('update price');
    String productData = await this.getProductData();
    double newPrice = await this.retrievePrice(productData);
    ProductHistory historyObject = ProductHistory(newPrice, DateTime.now());
    bool difference = _priceHistory.last.getPrice() != newPrice;
    this.addPriceToHistory(historyObject);
    this._priceHistory.last.activePromo = this.checkForPromo(productData);
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
      'active': active,
      'channels': this._channels,
      'priceHistory': historyObjects
    };
    return jsonEncode(tmp);
  }

  Future<void> checkForUpdatePrice() async{
    try{
      Log.info('checking for new price from ' + this.title);
    }catch(e){
      Log.error('failed to output server message for checking new price with title name');
      Log.error('trying now to output product title');
      Log.error(this.title);
      Log.error('trying to output sku');
      Log.error(this.sku);
    }
    List<ProductHistory> history = this.getPriceHistory();
    bool oldPromoStatus;
    if(history.length > 1){
      oldPromoStatus = history.last.activePromo;
    }else{
      oldPromoStatus = false;
    }

    bool updatedPrice = await this.updatePrice();
    history = this.getPriceHistory();

    bool promoStatus = history.last.activePromo;
    if( updatedPrice || promoStatus != oldPromoStatus ){
      double oldPrice = history[(history.length - 2)].getPrice();
      double newPrice = history.last.getPrice();
      double priceDifference = newPrice - oldPrice;
      //priceDifference = priceDifference.truncateToDouble();
      
      this.getChannels().forEach((channelId) async{
        TextChannel channel = await bot.getChannel(Snowflake(channelId)) as TextChannel;
        if(oldPrice != newPrice) {
          channel.send(
            content: "Das Produkt " + this.title + " hat einen neuen Preis. \n" +
                "Der Preis ist um " + (priceDifference > 0.0 ? priceDifference.toStringAsPrecision(2).replaceAll('.', ',') + this.currency + ' gestiegen': (priceDifference * -1).toStringAsPrecision(2).replaceAll('.', ',') + this.currency + ' gesunken') +
                '\n Der neue Preis beträgt: ' + newPrice.toString() +
                this.currency + '\n' + this.Url,
          );
          Log.info('found new price on ' + this.Url);
        }
        if(oldPromoStatus != promoStatus){
          channel.send(
              content:'Das Produkt "' + this.title + '" ' +(promoStatus==true?' nimmt':'nicht mehr') + ' an einer Promoaktion teil');
        }
      });
    }
    this.save();
  }

  void delete(){
    this._timer.cancel();
    this.active = false;
    this.save();
  }

  void save(){
    Log.info('saving product ' + this.sku);
    List<String> domainArray = Uri.parse(this.Url).host.split('.');
    String shopName;
    String tld = domainArray.last;
    switch(tld){
      case 'au':
      case 'jp':
      case 'uk':
        if( domainArray[domainArray.length-2] == 'co' || domainArray[domainArray.length-2] == 'com' ){
          shopName = domainArray[domainArray.length-3];
        }else{
          shopName = domainArray[domainArray.length-2];
        }
        break;
      default:
        shopName = domainArray[domainArray.length-2];
        break;
    }

    File db = File('db/'+shopName+'~'+this.sku+'.json');
    if(!db.existsSync()){
      db.createSync( recursive: true );
    }
    db.writeAsStringSync(this.toJson());
    Log.info('saved product');
  }

  static Future<Product> create( String url ) async {
    Uri uri = Uri.tryParse(url);
    if( config['supportedHosts'].indexOf(uri.host) == -1 ){
      Log.info('site not supported');
      // TODO Write Exception for that
      return null;
    }
    Product newProduct = config['ShopCollection'].getInstanceFromShop(uri.host);
    if(await newProduct.check(url)) {
      newProduct.Url = 'https://' + uri.host + uri.path;
      String productData = await newProduct.getProductData();
      newProduct.sku = await newProduct.retrieveSKU(productData);
      newProduct.title = await newProduct.retrieveTitle(productData);
      DateTime now = DateTime.now();
      double price = await newProduct.retrievePrice(productData);
      ProductHistory firstPrice = ProductHistory(price,now);
      firstPrice.activePromo = newProduct.checkForPromo(productData);
      newProduct.addPriceToHistory(firstPrice);
      return newProduct;
    }
    Log.info('check failed');
    // TODO Write Exception for that
    return null;
  }

  static Product createFromData( String url, List<int> channels, List<ProductHistory> productHistory,{String title=null, String sku=null} ){
    Log.info('importing product');
    Product product = config['ShopCollection'].getInstanceFromShop(Uri.parse(url).host);
    product.Url = url;
    product._channels = channels;
    product._priceHistory = productHistory;
    product.title = title;
    product.sku = sku;
    return product;
  }
}