import 'dart:io';

import 'package:nyxx/nyxx.dart';
import 'package:discord_price_watcher/shop_collection.dart';

import 'package:discord_price_watcher/log.dart';

Map config = {
  'supportedHosts': [
    'www.rightstufanime.com',
    'www.animeversand.com',
    'www.jbhifi.com.au',
    'www.wowhd.us'
  ]
};
Nyxx bot;

loadConfig( Map configJson ){
  if(configJson['discord-token'] == null || configJson['discord-token'] == ''){
    Log.error('no discord token given');
    exit(0);
  }else{
    ShopCollection sc = ShopCollection();
    config['ShopCollection'] = sc;
    config['discord-token'] = configJson['discord-token'];

    if(configJson['interval'] is int && configJson['interval'] > 0 && configJson['interval'] < 25 ){
      config['interval'] = configJson['interval'];
    }else{
      config['interval'] = 6;
    }
  }
}