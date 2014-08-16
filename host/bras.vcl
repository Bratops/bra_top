vcl 4.0;
# Default backend definition.  Set this to point to your content server.

backend default {
  .host = "127.0.0.1";
  .port = "8008";
  .connect_timeout = 5s;
  .first_byte_timeout = 30s;
  .between_bytes_timeout = 60s;
  .max_connections = 800;
}


sub vcl_recv {
  #set the correct IP so my backends don’t log all requests as coming from Varnish
  if (req.restarts == 0) {
    if (req.http.x-forwarded-for) {
      set req.http.X-Forwarded-For =
        req.http.X-Forwarded-For + ", " + client.ip;
    } else {
      set req.http.X-Forwarded-For = client.ip;
    }
  }
  #remove port, so that hostname is normalized
  set req.http.Host = regsub(req.http.Host, ":[0-9]+", "");
  #part of Varnish’s default config
  if (req.method != "GET" &&
      req.method != "HEAD" &&
      req.method != "PUT" &&
      req.method != "POST" &&
      req.method != "TRACE" &&
      req.method != "OPTIONS" &&
      req.method != "DELETE") {
    /* Non-RFC2616 or CONNECT which is weird. */
    return (pipe);
  }
  if (req.method != "GET" && req.method != "HEAD") {
    /* We only deal with GET and HEAD by default */
    return (pass);
  }
  #do not cache large static files
  if (req.url ~ "\.(avi|flv|mp(e?)g|mp4|mp3|gz|tgz|bz2|tbz|ogg)$") {
    return(pass);
  }
  # force lookup for static assets
  if (req.url ~ "\.(png|gif|jpg|swf|css|js|html|ico)$") {
    return(hash);
  }
  # part of Varnish’s default config
  if (req.http.Authorization || req.http.Cookie) {
    /* Not cacheable by default */
    return (pass);
  }
  return (hash);
}

sub vcl_pipe {
  #we need to copy the upgrade header
  if (req.http.upgrade) {
    set bereq.http.upgrade = req.http.upgrade;
  }
  #closing the connection is necessary for some applications –
  # I haven’t had any issues with websockets keeping the line below uncommented
  #set bereq.http.Connection = "close";
  return (pipe);
}
