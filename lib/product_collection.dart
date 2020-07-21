import 'dart:convert';
import 'dart:io';

import 'package:discord_price_watcher/product.dart';
import 'package:discord_price_watcher/product_history.dart';
import 'package:path/path.dart';

import 'package:discord_price_watcher/log.dart';

ProductCollection pc;
class ProductCollection {
  List<Product> collection = [];
  ProductCollection(){
    Log.info('loading new database');
    Directory DbDirectory = Directory('db');
    List<FileSystemEntity> fileList = DbDirectory.listSync( recursive: false, followLinks: false);
    if(DbDirectory.listSync( recursive: false, followLinks: false).length > 0){
      File dbFile;
      List<int> channels;
      List<ProductHistory> productHistory;
      fileList.forEach(( FileSystemEntity file ) {
        if(basename(file.path).split('~').length == 2) {
          Log.info('loading ' + file.path.split('/').last);
          channels = [];
          productHistory = [];
          dbFile = File(file.path);
          Map dbContent = jsonDecode(dbFile.readAsStringSync());
          if(dbContent['active'] != null && !dbContent['active']){
            Log.info('product inactive');
            return;
          }
          dbContent['channels'].forEach((channelId) {
            channels.add(channelId);
          });
          dbContent['priceHistory'].forEach((productHistoryObject) {
            productHistory.add(new ProductHistory(double.tryParse(productHistoryObject['price']), DateTime.parse(productHistoryObject['recordTime'])));
          });
          Product tmpProduct = Product.createFromData(
            dbContent['url'].toString(), channels, productHistory,
            sku: dbContent['sku'],
            title: dbContent['title'],
          );
          tmpProduct.initiateTimer();
          collection.add(tmpProduct);
        }
      });
    }
  }

  Product findProductByUrl( String url ){
    Uri uri = Uri.parse(url);
    url = 'https://' + uri.host + uri.path;
    Product result = null;
    for(int i = 0;i<collection.length;i++){
      if(collection[i].Url == url){
        result = this.collection[i];
        break;
      }
    }
    return result;
  }
}