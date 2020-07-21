import 'package:discord_price_watcher/config.dart';
import 'package:discord_price_watcher/log.dart';
import 'package:discord_price_watcher/product.dart';
import 'package:nyxx.commander/commander.dart';
import 'package:discord_price_watcher/product_collection.dart';

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

  }

  static void removeList( CommandContext context, String message ){

  }
}