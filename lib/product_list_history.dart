import 'dart:convert';

import 'package:discord_price_watcher/helper.dart';

class ProductListHistory {
  DateTime _recordTime;
  String _productIndex;
  String _action;
  ProductListHistory(String productIndex,String action,DateTime recordTime){
    this._productIndex = productIndex;
    this._action = action;
    this._recordTime = recordTime;
  }

  DateTime getRecordTime(){
    return this._recordTime;
  }
  String getProductIndex(){
    return this._productIndex;
  }

  String getAction(){
    return this._action;
  }

  Map toMap(){
    return {
      'productIndex':this.getProductIndex(),
      'action': this.getAction(),
      'recordTime': toTwoDigit(this.getRecordTime().year) + '-' +
          toTwoDigit(this.getRecordTime().month) + '-' +
          toTwoDigit(this.getRecordTime().day) + ' ' +
          toTwoDigit(this.getRecordTime().hour) + ':' +
          toTwoDigit(this.getRecordTime().minute)+ ':' +
          toTwoDigit(this.getRecordTime().second),
    };
  }

  String toJson(){
    return jsonEncode(this.toMap());
  }
}