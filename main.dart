import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:nyxx/Vm.dart';
import 'package:nyxx/nyxx.dart';
import 'dart:mirrors';

import 'package:rightstuf_price_watcher/config.dart';
import 'lib/ProductCollection.dart';
import 'package:rightstuf_price_watcher/product.dart';
import 'package:rightstuf_price_watcher/shops/rightstuffanime.dart';
import 'package:rightstuf_price_watcher/shops/animeversand.dart';
ProductCollection pc;

void main(){
  print('starting up');
  File configFile = new File('config.json');
  if(configFile.existsSync()){
    String configJsonString = configFile.readAsStringSync();
    Map configJson = jsonDecode(configJsonString);
    loadConfig(configJson);
    print('loaded config');

    // Add Pages to Shop Mapping
    ClassMirror rightstufanime = reflectClass(RightStufAnimeProduct);
    config['ShopCollection'].addShop('www.rightstufanime.com', rightstufanime);
    ClassMirror animeversand = reflectClass(AnimeVersandProduct);
    config['ShopCollection'].addShop('www.animeversand.com', animeversand);
    print('Shops loaded');

    // Initiate Bot
    bot = NyxxVm(config['discord-token'],ignoreExceptions: false);
    bot.onMessageReceived.listen(MessageReceivedHandler);


    pc = ProductCollection();
    planningTimer();
  }else{
    print('no config file found');
    exit(0);
  }
}

planningTimer() async{
  DateTime now = DateTime.now();
  pc.collection.forEach((product){
    DateTime firstRecordTime = product.getPriceHistory().first.getRecordTime();

    DateTime startTime;
    if( ( firstRecordTime.hour < now.hour || firstRecordTime.hour == now.hour && firstRecordTime.minute <= now.minute ) && now.day == DateTime.now().day ){
      now = now.add(Duration(days: 1));
    }
    startTime = DateTime(
        now.year,
        now.month,
        now.day,
        firstRecordTime.hour,
        firstRecordTime.minute
    );
    print('Initialised Product');
    print('Next Planned Update ' + startTime.day.toString() + '.' + startTime.month.toString() + '.'+startTime.year.toString() + ' ' + startTime.hour.toString() + ':' + startTime.minute.toString());
    Duration timeDifference;
    if(firstRecordTime.hour < now.hour || firstRecordTime.hour == now.hour && firstRecordTime.minute <= now.minute){
      timeDifference = now.difference(startTime);
    }else{
      timeDifference = startTime.difference(now);
    }
    Timer(timeDifference, (){
      product.checkForUpdatePrice();
      product.initiateTimer();
    });
  });
}
MessageReceivedHandler( event ){
  if(event.message.content.split(' ')[0] == '!addWatcher'){
    addWatcherPage(event.message.content,event.message.channel, event.message.guild);
  }
}

addWatcherPage( String message, MessageChannel channel, Guild guild ) async {
  if(message.split(' ')[1] == null && message.split(' ')[1] == ''){
    print('no url provided');
    return;
  }
  Uri url = Uri.parse(message.split(' ')[1]);
  String link = url.scheme +'://'+url.host+url.path;
  bool productExists = false;
  pc.collection.forEach((Product product) {
    if(product.Url == link){
      productExists = true;
      if(product.getChannels().indexOf(int.tryParse(channel.id.id)) != -1){
        channel.send(content: 'Dieses Produkt wurde bereits eingetragen');
      }else{
        product.addChannel(int.tryParse(channel.id.id));
        channel.send(content: 'Dieses Produkt wurde diesem Channel hinzugefügt');
        product.save();
      }
    }

  });
  if(!productExists) {
    Product product = await Product.create(link);
    product.addChannel(int.tryParse(channel.id.id));
    pc.collection.add(product);
    product.initiateTimer();
    channel.send(content: 'Produkt wurde hinzugefügt');
    product.save();
  }
}