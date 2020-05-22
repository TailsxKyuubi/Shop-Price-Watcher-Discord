library config;

import 'dart:io';
Map config = {};

loadConfig( Map configJson ){
  if(configJson['discord-token'] == null || configJson['discord-token'] == ''){
    print('no discord token given');
    exit(0);
  }else{
    config['discord-token'] = configJson['discord-token'];
  }
}