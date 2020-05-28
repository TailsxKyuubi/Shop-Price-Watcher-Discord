import 'dart:mirrors';

import 'package:rightstuf_price_watcher/product.dart';
class ShopCollection {
  Map<String,ClassMirror> _shopMapping = {};
  addShop(String domain,ClassMirror className){
    this._shopMapping[domain] = className;
  }

  Product getInstanceFromShop(String domain){
    return this._shopMapping[domain].newInstance(Symbol(''), []).reflectee;
  }
}