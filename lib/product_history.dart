import 'dart:convert';

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
        + this._recordTime.month.toString() + '-'
        + this._recordTime.day.toString() + ' '
        + this._recordTime.hour.toString() + ':'
        + this._recordTime.minute.toString() + ':' + this._recordTime.second.toString();
    return jsonEncode({
      'price': this._price.toString(),
      'recordTime': dateTime,
    });
  }
  Map asMap(){
    String dateTime = this._recordTime.year.toString() + '-'
        + this._recordTime.month.toString() + '-'
        + this._recordTime.day.toString() + ' '
        + this._recordTime.hour.toString() + ':'
        + this._recordTime.minute.toString() + ':' + this._recordTime.second.toString();
    return {
      'price': this._price.toString(),
      'recordTime': dateTime,
    };
  }
}