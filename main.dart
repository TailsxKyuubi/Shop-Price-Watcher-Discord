import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:mirrors';

import 'package:intl/intl.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx.commander/commander.dart';

import 'package:discord_price_watcher/config.dart';
import 'package:discord_price_watcher/product_collection.dart';
import 'package:discord_price_watcher/log.dart';
import 'package:discord_price_watcher/commands.dart';
import 'package:discord_price_watcher/shops/rightstuffanime.dart';
import 'package:discord_price_watcher/shops/animeversand.dart';
import 'package:discord_price_watcher/shops/jbhifi.dart';
import 'package:discord_price_watcher/shops/wowhd.dart';

void main(){
  Log.info('starting up');
  File configFile = new File('config.json');
  if(configFile.existsSync()){
    String configJsonString = configFile.readAsStringSync();
    Map configJson = jsonDecode(configJsonString);
    loadConfig(configJson);
    Intl.defaultLocale = 'de_DE';
    Log.info('loaded config');

    // Add Pages to Shop Mapping
    ClassMirror rightstufanime = reflectClass(RightStufAnimeProduct);
    config['ShopCollection'].addShop('www.rightstufanime.com', rightstufanime);
    ClassMirror animeversand = reflectClass(AnimeVersandProduct);
    config['ShopCollection'].addShop('www.animeversand.com', animeversand);
    ClassMirror jbhifi = reflectClass(JbHifiProduct);
    config['ShopCollection'].addShop('www.jbhifi.com.au',jbhifi);
    ClassMirror wowhdUS = reflectClass(WowHdProduct);
    config['ShopCollection'].addShop('www.wowhd.us',wowhdUS);
    Log.info('Shops loaded');

    // Initiate Bot
    try{
      bot = Nyxx(config['discord-token'],ignoreExceptions: false);
      //bot.onMessageReceived.listen(MessageReceivedHandler);
      Commander commander = Commander(bot,prefix: '!')
        ..registerCommand('ping',Commands.pong)
        ..registerCommand('add', Commands.add)
        ..registerCommand('remove', Commands.remove);
    }catch(exception){
      print("error");
    }
    pc = ProductCollection();
    planningTimer();
  }else{
    Log.info('no config file found');
    exit(0);
  }
}


planningTimer() async{
  DateTime now;
  pc.collection.forEach((product){
    DateTime firstRecordTime = product.getPriceHistory().first.getRecordTime();
    now = DateTime.now();
    DateTime startTime;
    Duration difference = now.difference(firstRecordTime);
    double intervalCount = (difference.inHours % 24) / config['interval'];

    startTime = DateTime(
        now.year,
        now.month,
        now.day,
        firstRecordTime.hour,
        firstRecordTime.minute
    );
    int hours;
    if(intervalCount < 1){
      intervalCount = 1;
    }

    hours = intervalCount.ceil() * config['interval'];

    startTime = startTime.add(Duration(hours: hours));
    if(now.isAfter(startTime)){
      startTime = startTime.add(Duration(hours: config['interval']));
    }

    Log.info('Initialised Product "' + product.title + '"');
    Log.info('Next Planned Update ' + startTime.day.toString() + '.' + startTime.month.toString() + '.'+startTime.year.toString() + ' ' + startTime.hour.toString() + ':' + startTime.minute.toString());
    Duration timeDifference = startTime.difference(now);
    Timer(timeDifference, (){
      product.checkForUpdatePrice();
      product.initiateTimer();
    });
  });
}

listProductsFromChannel( event ){
  int channelId = int.tryParse(event.message.channel.id.id);
  String products = '';
  var embed = EmbedBuilder();
  int i = 0;
  pc.collection.forEach( ( element ) {
    if( element.getChannels().indexOf( channelId ) != -1 ){
      i++;
      products += i.toString()+') ' + element.title.trim() + '\n'+element.Url+'\n\n';
    }
  });
  embed.addField(name: 'Liste Produkte', content: products);
  event.message.channel.send(embed: embed);
}