import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:nyxx/Vm.dart';
import 'package:nyxx/nyxx.dart';
import 'package:http/http.dart' as http;
import 'package:rightstuf_price_watcher/product_history.dart';

import 'lib/config.dart';
import 'lib/ProductCollection.dart';
import 'package:rightstuf_price_watcher/product.dart';
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
    startTime = DateTime(
        now.year,
        now.month,
        now.day,
        firstRecordTime.hour,
        firstRecordTime.minute
    );
    print('Initialised Product');
    print('Next Planned Update ' + startTime.day.toString() + '.' + startTime.month.toString() + '.'+startTime.year.toString() + ' ' + startTime.hour.toString() + ':' + startTime.minute.toString());
    //Timer(now.difference(startTime), (){
      //checkForUpdatePrice(product);
      checkForUpdatePriceTimer(product);
    //});
  });
}

Future<void> checkForUpdatePrice(Product product) async{
  print('checking for new price');
  if( await product.updatePrice() ){
    product.getChannels().forEach((channelId) async{
      TextChannel channel = bot.channels[Snowflake(channelId)] as TextChannel;
      List<ProductHistory> history = product.getPriceHistory();
      double priceDifference = history[(history.length - 2)].getPrice() - history.last.getPrice();
      channel.send(
        content: "Das Produkt mit der URL: " + product.getUrl() + " hat einen neuen Preis. \n"+
            "Der Preis ist um " + (priceDifference > 0?priceDifference.toString() + ' gestiegen':(priceDifference*-1).toString() + ' gesunken'),
      );
      print('found new price on ' + product.Url);
      pc.save();
    });
  }
}

void checkForUpdatePriceTimer(Product product) async {
  print('setup timer');
  // running the loop until the bots stops
  while(true){
    print('initialize automatic check attempt');
    await Future.delayed(Duration(minutes: 1));
    checkForUpdatePrice(product);
  };
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
  if(await checkRightstufPage(url)){
    File jsonFile = new File('db/db.json');
    if(!jsonFile.existsSync()){
      jsonFile.createSync(recursive: true);
    }
  }
  Product product = await Product.create(url.scheme +'://'+url.host+url.path);
  product.addChannel(int.tryParse(channel.id.id));
  pc.collection.add(product);
  channel.send(content: 'Produkt wurde hinzugefügt');
  pc.save();
}

Future<bool> checkRightstufPage(Uri url) async {
  http.Response res = await http.get('https://'+url.host+url.path);
  Document document = parse(res.body);
  Element form = document.getElementById('product-details-full-form');
  List<Element> price_elements = form.getElementsByClassName('product-views-price-lead');
  double price = double.tryParse(price_elements[0].attributes['data-rate']);
  if(price > 0){
    return true;
  }else{
    return false;
  }
}