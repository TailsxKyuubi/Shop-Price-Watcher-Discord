import 'dart:io';

import 'package:rightstuf_price_watcher/shop_collection.dart';
Map config = {
  'supportedHosts': [
    'www.rightstufanime.com'
  ]
};

loadConfig( Map configJson ){
  if(configJson['discord-token'] == null || configJson['discord-token'] == ''){
    print('no discord token given');
    exit(0);
  }else{
    ShopCollection sc = ShopCollection();
    config['ShopCollection'] = sc;
    config['discord-token'] = configJson['discord-token'];
  }
}