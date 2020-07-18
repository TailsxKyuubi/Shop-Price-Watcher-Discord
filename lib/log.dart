import 'dart:io';

class Log {
  static info( String message ) => Log._output( 'INFO', message );
  static error( String message ) => Log._output( 'ERROR', message );
  static _output( String type, String message ) {
    DateTime now = DateTime.now();
    String fullMessage = '['+type+']['+now.day.toString()+'.'
        +now.month.toString()+'.' +now.year.toString()+' '+now.hour.toString()
        +':'+now.minute.toString()+':'+now.second.toString()+'] ' + message;
    File logFile = File('price-watcher.log');
    if(!logFile.existsSync()){
      logFile.createSync();
    }
    if(logFile.lengthSync() > (1024*1024*4)){
      int count = 1;
      while( File('price-watcher.log.'+count.toString()).existsSync() ){
        count++;
      }
      for(int i = (count-1);i>0;i--){
        File( 'price-watcher.log.'+i.toString()).renameSync('price-watcher.log.'
            +(i+1).toString() );
      }
      File( 'price-watcher.log' ).renameSync( 'price-watcher.log.1' );
      logFile.createSync();
    }
    logFile.writeAsStringSync(fullMessage);
    print(fullMessage);
  }
}