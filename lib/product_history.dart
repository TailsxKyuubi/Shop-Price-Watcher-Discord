import 'dart:convert';
import 'helper.dart';

class ProductHistory {
  double _price;
  DateTime _recordTime;

  ProductHistory( double price, DateTime recordTime ){
    this._price = price;
    this._recordTime = recordTime;
  }

  double getPrice(){
    return _price;
  }

  DateTime getRecordTime(){
    return _recordTime;
  }
  String toJson(){
    String dateTime = this._recordTime.year.toString() + '-'
        + toTwoDigit(this._recordTime.month) + '-'
        + toTwoDigit(this._recordTime.day) + ' '
        + toTwoDigit(this._recordTime.hour) + ':'
        + toTwoDigit(this._recordTime.minute) + ':' + toTwoDigit(this._recordTime.second);
    return jsonEncode({
      'price': this._price.toString(),
      'recordTime': dateTime,
    });
  }
  Map asMap(){
    String dateTime = this._recordTime.year.toString() + '-'
        + toTwoDigit(this._recordTime.month) + '-'
        + toTwoDigit(this._recordTime.day) + ' '
        + toTwoDigit(this._recordTime.hour) + ':'
        + toTwoDigit(this._recordTime.minute) + ':' + toTwoDigit(this._recordTime.second);
    return {
      'price': this._price.toString(),
      'recordTime': dateTime,
    };
  }
}