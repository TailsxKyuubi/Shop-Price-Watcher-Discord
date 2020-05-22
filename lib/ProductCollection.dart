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
      Map data = jsonDecode(jsonRaw);
      data.forEach((index,item){
        List<BigInt> channels;
        List<ProductHistory> productHistory;
        item.channels.forEach((index,channelId) {
          channels.add(BigInt.from(channelId));
        });
        item.productHistory.forEach((index,productHistoryObject){
          productHistory.add(new ProductHistory(productHistoryObject.price, productHistoryObject.recordTime));
        });
        Product tmpProduct = Product.createFromData(item.url.toString(),channels,productHistory);
        collection.add(tmpProduct);
      });
    }
  }
  void save(){
    List<String> productsJson;
    collection.forEach((product){
      productsJson.add(product.toJson());
    });
    String finalOutput = '[' + productsJson.join(',')+']';
    File db = File('db/db.json');
    if(!db.existsSync()){
      db.createSync( recursive: true );
    }
    db.writeAsStringSync(finalOutput);
  }
}