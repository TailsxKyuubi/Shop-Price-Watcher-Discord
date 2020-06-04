import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:nyxx/Vm.dart';
import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart' as http;
import 'dart:mirrors';
import 'package:rightstuf_price_watcher/product_history.dart';

import 'package:rightstuf_price_watcher/config.dart';
import 'lib/ProductCollection.dart';
import 'package:rightstuf_price_watcher/product.dart';
import 'package:rightstuf_price_watcher/shops/rightstuffanime.dart';
ProductCollection pc;
Nyxx bot;

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
    print('Shops loaded');

    // Initiate Bot
    bot = NyxxVm(config['discord-token'],ignoreExceptions: false);
    bot.onMessageReceived.listen(MessageReceivedHandler);


    pc = ProductCollection();
    initiateTimer();
  }else{
    print('no config file found');
    exit(0);
  }
}

initiateTimer() async{
  DateTime now = DateTime.now();
  pc.collection.forEach((product){
    DateTime firstRecordTime = product.getPriceHistory().first.getRecordTime();

    DateTime startTime;
    if( ( firstRecordTime.hour < now.hour || firstRecordTime.hour == now.hour && firstRecordTime.minute <= now.minute ) && now.day == DateTime.now().day ){
      now = now.add(Duration(days: 1));
    }
    print(now.day);
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
      checkForUpdatePrice(product);
      checkForUpdatePriceTimer(product);
    });
  });
}

Future<void> checkForUpdatePrice(Product product) async{
  print('checking for new price');
  if( await product.updatePrice() ){
    product.getChannels().forEach((channelId) async{
      TextChannel channel = await bot.getChannel(Snowflake(channelId)) as TextChannel;
      print(channel);
      List<ProductHistory> history = product.getPriceHistory();
      double oldPrice = history[(history.length - 2)].getPrice();
      double newPrice = history.last.getPrice();
      double priceDifference = newPrice - oldPrice;
      priceDifference = priceDifference.truncateToDouble();
      channel.send(
        content: "Das Produkt mit der URL: " + product.getUrl() + " hat einen neuen Preis. \n"+
            "Der Preis ist um " + (priceDifference > 0?priceDifference.toString().replaceAll('.', ',') + product.currency + ' gestiegen':(priceDifference*-1).toString().replaceAll('.', ',') + product.currency + ' gesunken'),
      );
      print('found new price on ' + product.Url);
    });
  }
  pc.save( product );
}

void checkForUpdatePriceTimer(Product product) async {
  print('setup timer');
  // running the loop until the bots stops
  Timer.periodic(Duration(hours: 6), (timer) {
    print('initialize automatic check attempt');
    checkForUpdatePrice(product);
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
  if(url.host != 'www.rightstufanime.com'){
    channel.send(content: 'the url isn\'t from rightstuf');
    return;
  }
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
        pc.save( product );
      }
    }

  });
  if(!productExists) {
    Product product = await Product.create(link);
    product.addChannel(int.tryParse(channel.id.id));
    pc.collection.add(product);
    checkForUpdatePriceTimer(product);
    channel.send(content: 'Produkt wurde hinzugefügt');
    pc.save( product );
  }
}