import 'dart:convert';
import 'dart:io';

import 'package:rightstuf_price_watcher/product.dart';
import 'package:rightstuf_price_watcher/product_history.dart';

ProductCollection productCollection;

class ProductCollection {
  List<Product> collection = [];
  ProductCollection(){
    File dbFile = File('db/db.json');
    if(dbFile.existsSync()){
      String jsonRaw = dbFile.readAsStringSync();
      Map data = jsonDecode(jsonRaw).asMap();
      data.forEach((index,item){
        List<int> channels = [];
        List<ProductHistory> productHistory = [];
        item['channels'].forEach((channelId) {
          channels.add(channelId);
        });
        item['priceHistory'].forEach((productHistoryObject){
          productHistory.add(new ProductHistory(double.tryParse(productHistoryObject['price']), DateTime.parse(productHistoryObject['recordTime'])));
        });
        Product tmpProduct = Product.createFromData(item['url'].toString(),channels,productHistory);
        collection.add(tmpProduct);
      });
    }
  }
  void save(){
    print('saving db');
    List<String> productsJson = [];
    collection.forEach((product){
      productsJson.add(product.toJson());
    });
    String finalOutput = '[' + productsJson.join(',')+']';
    File db = File('db/db.json');
    if(!db.existsSync()){
      db.createSync( recursive: true );
    }
    db.writeAsStringSync(finalOutput);
    print('saved db');
  }
}