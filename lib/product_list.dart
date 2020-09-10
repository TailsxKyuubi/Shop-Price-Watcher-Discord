import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:discord_price_watcher/helper.dart';
import 'package:discord_price_watcher/product.dart';
import 'package:discord_price_watcher/product_collection.dart';
import 'package:discord_price_watcher/product_history.dart';
import 'package:discord_price_watcher/product_list_history.dart';
import 'package:nyxx/nyxx.dart';
import 'package:discord_price_watcher/config.dart';

import 'log.dart';

abstract class ProductList {
  String Name;
  List<Product> collection = [];
  List<int> channels = [];
  List<ProductListHistory> history = [];
  Timer _timer;

  ProductList(){
    Directory dbListDirectory = Directory('db/list');
    if( ! dbListDirectory.existsSync() ){
      dbListDirectory.createSync(recursive: true);
    }
    File dbFile = File('db/list/'+this.Name+'.json');
    if(!dbFile.existsSync()){
      dbFile.createSync();
    }
    String dbString = dbFile.readAsStringSync();
    Map db;
    try{
      db = jsonDecode(dbString);
    }catch(exception){
      db = {
        'channels': List<int>(),
        'history': List<ProductListHistory>(),
        'collection': List<Product>()
      };
    }
    db['channels'].forEach((id) => this.channels.add(id));
    List<ProductListHistory> history = [];
    db['history'].forEach((productListHistory) => history.add(
        ProductListHistory(
            productListHistory['productIndex'],
            productListHistory['action'],
            DateTime.parse(productListHistory['recordTime'])
        )
    )
    );
    this.history = history;
    db['collection'].forEach((productFileName) {
      File dbFile = File('db/'+productFileName+'.json');
      Map dbProduct = jsonDecode(dbFile.readAsStringSync());
      Product productSearch = pc.findProductByUrl(dbProduct['url']);
      Product product;
      List<ProductHistory> productHistory = [];
      dbProduct['priceHistory'].asMap().forEach((key,value) =>
          productHistory.add(new ProductHistory(value['price'], value['recordTime'])));
      if(productSearch == null){
        product = Product.createFromData(
          dbProduct['url'],
          dbProduct['channels'],
          productHistory,
          sku: dbProduct['sku'],
          title: dbProduct['title'],
        );
        product.active = false;
      }else{
        product = productSearch;
        product.active = false;
        product.stopTimer();
      }

      this.collection.add(product);
    });
  }

  Future<List> retrieveData();
  void updateList( [Timer timer] ) async {
    Log.info('retrieving List Data');
    List content = await this.retrieveData();
    Log.info('found ' + content.length.toString() + ' elements');
    List<Product> comparisionList = this.collection;
    int messageCounter = 0;
    Log.info('starting iteration');
    String message = '';
    String tmpMessage = '';
    content.forEach((element) {
      String url = this.getUrlSingle(element);
      String sku = this.getSkuSingle(element);
      Log.info('trying to find Product');
      Product product = pc.findProductByUrl(url);
      if(product == null){
        String shopName = getShopName(url);
        File dbFile = File(shopName+'~'+sku+'.json');
        Map productData = null;
        if(dbFile.existsSync()){
          productData = jsonDecode(dbFile.readAsStringSync());
        }
        List<ProductHistory> productHistory = List<ProductHistory>();
        productData != null?productData['priceHistory'].asMap().forEach((key,value) =>
            productHistory.add(new ProductHistory(value['price'], value['recordTime']))):[];
        product = Product.createFromData(
            this.getUrlSingle(element),
            [],
            productHistory,
            sku: sku,
            title: this.getTitleSingle(element)
        );
        product.active = false;
      }
      product.addPriceToHistory(
        ProductHistory(
          this.getPriceSingle(element),
          DateTime.now()
        )
      );
      if(collection.indexOf(product) == -1){
        collection.add(product);
        this.history.add(
            ProductListHistory(
                getShopName(product.getUrl())+'~'+product.sku,
                'add',
                DateTime.now()
            )
        );
        product.save();
        tmpMessage = '\nDas Produkt "' + product.title + '" nimmt am Sale teil';
        // 2000 Characters is the limit for messages in discord
        if( (message+tmpMessage).trim().length > 2000 ){
          messageCounter++;
          String messageFinal = message;
          message = tmpMessage.trim();
          Timer(Duration(seconds: messageCounter * 5), (){
            this.channels.forEach((int id) async {
              GuildTextChannel channel = await bot.getChannel(Snowflake(id)) as GuildTextChannel;
              channel.send(content: messageFinal);
            });
          });
        }else{
          message = (message+tmpMessage).trim();
        }
      }else{
        product.stopTimer();
        product.active = false;
      }
      comparisionList.remove(product);
    });
    comparisionList.forEach((product) {
        history.add(
            ProductListHistory(
                getShopName(product.getUrl())+'~'+product.sku,
                'remove',
                DateTime.now()
            )
        );
        product.save();
        if(!product.getChannels().isEmpty){
          product.active = true;
          product.initiateTimer();
        }
      }
    );
    this.channels.forEach((int id) async {
      GuildTextChannel channel = await bot.getChannel(Snowflake(id)) as GuildTextChannel;
      comparisionList.forEach((product) {
        Timer(Duration(seconds: messageCounter * 5), (){
          channel.send(content: 'Das Produkt "' + product.title + '" nimmt nicht mehr am Sale teil');
          messageCounter++;
        });
      });
    });
    this.save();
  }
  String toJson(){
    List<Map> historyList = [];
    this.history.forEach((element) => historyList.add(element.toMap()));
    List<String> collectionList = [];
    this.collection.forEach((element) => collectionList.add(getShopName(element.getUrl())+'~'+element.sku));
    return jsonEncode({
      'name': this.Name,
      'channels': this.channels,
      'history': historyList,
      'collection': collectionList
    });
  }

  void _setupTimer(){
    this._timer = Timer.periodic(
        Duration( hours: config['interval']),
        this.updateList
    );
  }

  bool addChannel(int channelId){
    if(this.channels.indexOf(channelId) != -1){
      Log.error('channel is already subscribed');
      return false;
    }
    if(this.channels.isEmpty){
      this.updateList();
      this._setupTimer();
    }
    this.channels.add(channelId);
    this.save();
    return true;
  }

  bool delete( int channelId ){
    if(this.channels.indexOf(channelId) == -1){
      return false;
    }
    this.channels.remove(channelId);
    if(this.channels.isEmpty){
      this._timer.cancel();
      this._timer = null;
    }
    return true;
  }

  save(){
    Directory dbListDirectory = Directory('db/list');
    if( ! dbListDirectory.existsSync() ){
      dbListDirectory.createSync(recursive: true);
    }
    File dbFile = File('db/list/'+this.Name+'.json');
    if(dbFile.existsSync()){
      dbFile.createSync();
    }
    dbFile.writeAsStringSync(this.toJson());
  }
  double getPriceSingle(element);
  String getSkuSingle(element);
  String getUrlSingle(element);
  String getTitleSingle(element);
}