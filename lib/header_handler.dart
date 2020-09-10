class HeaderHandler {
  Map<String,Map<String,String>> _headers = {};
  Map<String,Map<String,String>> cookies = {};


  _setDefaultHeaders(domain){
    this._headers[domain] = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:78.0) Gecko/20100101 Firefox/78.0',
      'Accept': '*/*',
      'Accept-Language': 'de,en-US;q=0.7,en;q=0.3',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Pragma': 'no-cache',
      'Cache-Control': 'no-cache',
      'TE': 'Trailers',
    };
  }

  getHeaders(domain){
    if(this._headers[domain] == null){
      this._setDefaultHeaders(domain);
    }
    return this._headers[domain];
  }
  setHeaderField(key,value,domain){
    if(this._headers[domain] == null){
      this._setDefaultHeaders(domain);
    }
    this._headers[domain][key] = value;
  }

  writeCookiesInHeader(String domain){
    if(this._headers[domain] == null){
      this._setDefaultHeaders(domain);
    }
    this._headers[domain]['Cookie'] = '';
    this.cookies[domain].forEach((String key,String content){
      this._headers[domain]['Cookie'] += "${key}=${content}\; ";
    });
  }

  setCookie(String key,String value, String domain){
    if(this.cookies[domain] == null){
      this.cookies[domain] = Map<String,String>();
    }
    this.cookies[domain][key] = value;
  }

  decodeCookiesString(cookieString,String domain){
    List<String> cookies = cookieString.split(RegExp(',(?![(,&^(Mon\ ,|Tue\ ,|Wed\ ,|Thu\ ,|Fri\ ,|Sat\ ,|Sun\ ,))])'));
    cookies.forEach((String cookie){
      List cookieMap = cookie.split(';')[0].split('=');
      this.cookies[domain][cookieMap[0]] = cookieMap[1];
    });
    writeCookiesInHeader(domain);
  }
}