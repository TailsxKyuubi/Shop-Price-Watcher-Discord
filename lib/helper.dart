String toTwoDigit(int value){
  String returnVal = value.toString();
  if(value < 10){
    returnVal = '0' + returnVal;
  }
  return returnVal;
}

String getShopName(String url){
  List<String> domainArray = Uri.parse(url).host.split('.');
  String shopName;
  String tld = domainArray.last;
  switch(tld){
    case 'au':
    case 'jp':
    case 'uk':
      if( domainArray[domainArray.length-2] == 'co' || domainArray[domainArray.length-2] == 'com' ){
        shopName = domainArray[domainArray.length-3];
      }else{
        shopName = domainArray[domainArray.length-2];
      }
      break;
    default:
      shopName = domainArray[domainArray.length-2];
      break;
  }
  return shopName;
}