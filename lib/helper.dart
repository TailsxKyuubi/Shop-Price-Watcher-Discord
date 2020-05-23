String toTwoDigit(int value){
  String returnVal = value.toString();
  if(value < 10){
    returnVal = '0' + returnVal;
  }
  return returnVal;
}