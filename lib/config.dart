import 'dart:io';

import 'package:nyxx/Vm.dart';
import 'package:discord_price_watcher/shop_collection.dart';

import 'package:discord_price_watcher/log.dart';

Map config = {
  'supportedHosts': [
    'www.rightstufanime.com',
    'www.animeversand.com',
    'www.jbhifi.com.au'
  ]
};
NyxxVm bot;

loadConfig( Map configJson ){
  if(configJson['discord-token'] == null || configJson['discord-token'] == ''){
    Log.error('no discord token given');
    exit(0);
  }else{
    ShopCollection sc = ShopCollection();
    config['ShopCollection'] = sc;
    config['discord-token'] = configJson['discord-token'];
  }
}