import 'dart:convert';

import 'package:discord_price_watcher/config.dart';
import 'package:discord_price_watcher/log.dart';
import 'package:discord_price_watcher/product.dart';
import 'package:nyxx_commander/commander.dart';
import 'package:discord_price_watcher/product_collection.dart';

import 'package:http/http.dart' as http;

import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';
class Commands {

  static void pong( CommandContext context, String message ){
    context.channel.send(content: 'pong');
  }

  static void add( CommandContext context, String message ){
    List<String> messageList = message.trim().split(' ');

    String command = messageList[1];
    // remove spaces in the string
    messageList.remove('');
    messageList.removeAt(0);
    messageList.removeAt(0);
    message = messageList.join(' ');

    switch(command.toLowerCase()){
      case 'product':
        Commands.addProduct(context, message);
        break;
      case 'list':
        Log.info('trying to add list');
        Commands.addList(context, message);
        break;
      default:
        context.channel.send(content: 'Not supported parameter');
    }
  }

  static void remove( CommandContext context, String message ){
    List<String> messageList = message.trim().split(' ');

    String command = messageList[1];
    // remove spaces in the string
    messageList.remove('');
    messageList.removeAt(0);
    messageList.removeAt(0);
    message = messageList.join(' ');

    switch(command.toLowerCase()){
      case 'product':
        Commands.removeProduct(context, message);
        break;
      case 'list':
        Commands.removeList(context, message);
        break;
      default:
        context.channel.send(content: 'Not supported parameter');
    }
  }

  static void addProduct( CommandContext context, String message ) async {
    Uri url = Uri.parse(message);
    String link = url.scheme +'://'+url.host+url.path;
    List<String> supportedHosts = config['supportedHosts'];
    if(supportedHosts.indexOf(url.host) == -1){
      context.channel.send(content: 'Dieser Shop wird zurzeit nicht unterstützt');
      return;
    }
    bool productExists = false;
    pc.collection.forEach((Product product) {
      if(product.Url == link){
        productExists = true;
        if(product.getChannels().indexOf(context.channel.id.id) != -1){
          context.channel.send(content: 'Dieses Produkt wurde bereits eingetragen');
        }else{
          product.addChannel(context.channel.id.id);
          context.channel.send(content: 'Dieses Produkt wurde diesem Channel hinzugefügt');
          product.save();
        }
      }

    });
    if(!productExists) {
      Product product = await Product.create(link);
      product.addChannel(context.channel.id.id);
      pc.collection.add(product);
      product.initiateTimer();
      context.channel.send(content: 'Produkt wurde hinzugefügt');
      product.save();
    }
  }

  static void removeProduct( CommandContext context, String message ){
    Product product = pc.findProductByUrl(message);
    if(product != null && product.getChannels().indexOf(context.channel.id.id) != -1){
      product.delete(context.channel.id.id);
      context.channel.send(content: 'Produkt erfolgreich gelöscht');
    }else{
      context.channel.send(content: 'Produkt konnte nicht gefunden werden');
    }

  }

  static void addList( CommandContext context, String message ){
    if(pc.listCollection[message] != null){
      if(pc.listCollection[message].addChannel(context.channel.id.id)){
        context.channel.send(content: 'Channel erfolgreich zur Produktliste Überwachung hinzugefügt');
      }else{
        context.channel.send(content: 'Channel konnte nicht zur Produktliste Überwachung hinzugefügt werden');
      }
    }else{
      context.channel.send(content: 'Die angegebene Produktliste existiert nicht');
    }
  }

  static void removeList( CommandContext context, String message ){
    if(pc.listCollection[message] != null){
      if(pc.listCollection[message].delete(context.channel.id.id)){
        context.channel.send(content: 'Channel wurde erfolgreich von der Produktliste Überwachung entfernt');
      }else{
        context.channel.send(content: 'Channel konnte nicht von der Produktliste Überwachung entfernt werden');
      }
    }else{
      context.channel.send(content: 'Die angegebene Produktliste existiert nicht');
    }
  }

  static void checkCountry(CommandContext context, String message) async{
    var dio = new Dio();
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      // config the http client
      client.findProxy = (uri) {
        return "PROXY de680.nordvpn.com:80";
      };
      // you can also create a new HttpClient to dio
      // return new HttpClient();
    };
    headerHandler.setHeaderField('Proxy-Authorization','Basic UnU2RjZSN1JNb3BHajZ0V2gxM2J6Q2FlOmtnVUNDOUJCWTcxOTZNcXRpb2dWaHBZcQ==', 'test.com');
    headerHandler.setHeaderField('Authorization','Basic UnU2RjZSN1JNb3BHajZ0V2gxM2J6Q2FlOmtnVUNDOUJCWTcxOTZNcXRpb2dWaHBZcQ==', 'test.com');
    //http.Response res = await http.get('geoip.sezzle.com/v1/geoip/ipdetails',headers: headerHandler.getHeaders('test.com'));
    try {
      var value  = await dio.get('https://geoip.sezzle.com/v1/geoip/ipdetails',options: Options( headers: headerHandler.getHeaders('test.com')));
      Log.info(value.data);
      context.channel.send(content: '```json\n'+value.data+'```');
    } on DioError catch(e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if(e.response != null) {
        print(e.response.data);
        print(e.response.headers);
        print(e.response.request);
      } else{
        // Something happened in setting up or sending the request that triggered an Error
        print(e.request);
        print(e.message);
      }
    }
    Log.info('test');
    //Log.info(res.request.toString());
    //context.channel.send(content: res.request.headers.toString());
  }
}