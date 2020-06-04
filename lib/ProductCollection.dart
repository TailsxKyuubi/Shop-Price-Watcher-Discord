import 'dart:convert';
import 'dart:io';

import 'package:rightstuf_price_watcher/product.dart';
import 'package:rightstuf_price_watcher/product_history.dart';

ProductCollection productCollection;

class ProductCollection {
  List<Product> collection = [];
  ProductCollection(){
    File oldDbFile = File('db/db.json');
    if(oldDbFile.existsSync()) {
      print('loading old database');
      String jsonRaw = oldDbFile.readAsStringSync();
      Map data = jsonDecode(jsonRaw).asMap();
      oldDbFile.deleteSync();
      data.forEach((index, item) async {
        List<int> channels = [];
        List<ProductHistory> productHistory = [];
        item['channels'].forEach((channelId) {
          channels.add(channelId);
        });
        item['priceHistory'].forEach((productHistoryObject) {
          productHistory.add(new ProductHistory(double.tryParse(productHistoryObject['price']), DateTime.parse(productHistoryObject['recordTime'])));
        });
        Product tmpProduct = Product.createFromData(item['url'].toString(), channels, productHistory);
        // Converting save format
        tmpProduct.title = await tmpProduct.retrieveTitle();
        tmpProduct.sku = await tmpProduct.retrieveSKU();
        this.save(tmpProduct);
        collection.add(tmpProduct);
      });
    } else {
      print('loading new database');
      Directory DbDirectory = Directory('db');
      List<FileSystemEntity> fileList = DbDirectory.listSync( recursive: false, followLinks: false);
      if(DbDirectory.listSync( recursive: false, followLinks: false).length > 0){
        File dbFile;
        Map dbContent;
        List<int> channels;
        List<ProductHistory> productHistory;
        fileList.forEach(( FileSystemEntity file ) {
          if(file.path.split('/').last.split('~') == 2) {
            channels = [];
            productHistory = [];
            dbFile = File(file.path);
            dbContent = jsonDecode(dbFile.readAsStringSync());
            dbContent['channels'].forEach((channelId) {
              channels.add(channelId);
            });
            dbContent['priceHistory'].forEach((productHistoryObject) {
              productHistory.add(new ProductHistory(
                  double.tryParse(productHistoryObject['price']),
                  DateTime.parse(productHistoryObject['recordTime'])));
            });
            Product tmpProduct = Product.createFromData(
                dbContent['url'].toString(), channels, productHistory);
            collection.add(tmpProduct);
          }
        });
      }
    }
  }
  void save( Product product ){
    print('saving product');
    List<String> domainArray = product.Url.split('.');
    String shopName = domainArray[domainArray.length-2];
    File db = File('db/'+shopName+'~'+product.sku+'.json');
    if(!db.existsSync()){
      db.createSync( recursive: true );
    }
    db.writeAsStringSync(product.toJson());
    print('saved product');
  }
}