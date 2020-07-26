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

abstract class ProductList {
  List<Product> productList = List<Product>();
  String Name;
  List<Product> collection = [];
  List<int> channels = [];
  List<ProductListHistory> history = [];
  Timer _timer;


  Future<List> retrieveData();
  void updateList( [Timer timer] ) async {
    List content = await this.retrieveData();
    List<Product> comparisionList = this.collection;
    int messageCounter = 0;
    content.forEach((element) {
      String url = this.getUrlSingle(element);
      String sku = this.getSkuSingle(element);
      Product product = pc.findProductByUrl(url);
      if(product == null){
        String shopName = getShopName(url);
        File dbFile = File(shopName+'~'+sku+'.json');
        Map productData = null;
        if(dbFile.existsSync()){
          productData = jsonDecode(dbFile.readAsStringSync());
        }
        List<ProductHistory> productHistory = List<ProductHistory>();
        Product.createFromData(
            this.getUrlSingle(element),
            [],
            productData != null?productData['priceHistory'].asMap().forEach((key,value) =>
                productHistory.add(new ProductHistory(value['price'], value['recordTime']))):[],
            sku: sku,
            title: this.getTitleSingle(element)
        );
        product.active = false;
      }
      if(collection.indexOf(product) == -1){
        collection.add(product);
        history.add(
            ProductListHistory(
              getShopName(product.getUrl())+'~'+product.sku,
              'add',
              DateTime.now()
            )
        );
        Timer(Duration(seconds: messageCounter % 10 == 0?5:0), (){
          this.channels.forEach((int id) {
            GuildTextChannel channel =  bot.getChannel(Snowflake(id)) as GuildTextChannel;
            channel.send(content: 'Das Produkt "' + product.title + '" nimmt am Sale teil');
          });
        });
        messageCounter++;
      }else{
        comparisionList.remove(product);
      }
    });
    comparisionList.forEach((product) => history.add(
        ProductListHistory(
            getShopName(product.getUrl())+'~'+product.sku,
            'add',
            DateTime.now()
        )
    ));
    this.channels.forEach((int id) {
      GuildTextChannel channel =  bot.getChannel(Snowflake(id)) as GuildTextChannel;
      comparisionList.forEach((product) {
        Timer(Duration(seconds: messageCounter % 10 == 0?5:0), (){
          channel.send(content: 'Das Produkt "' + product.title + '" nimmt nicht mehr am Sale teil');
          messageCounter++;
        });
      });
    });
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

  void delete( int channelId ){
    if(this.channels.indexOf(channelId) == -1){
      return;
    }
    this.channels.remove(channelId);
    if(this.channels.isEmpty){
      this._timer.cancel();
      this._timer = null;
    }
  }

  save(){
    Directory dbListDirectory = Directory('db/list');
    if( ! dbListDirectory.existsSync() ){
      dbListDirectory.createSync(recursive: true);
    }
    File dbFile = File('db/list/'+this.Name);
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