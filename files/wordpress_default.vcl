#-- https://www.varnish-cache.org/docs/3.0/tutorial/backend_servers.html
#-- Set the local servers loopback ip and to the port running Apache, Nginx,
#   Tomcat, etc (locally)
backend default {
    .host = "127.0.0.1";
    .port = "8080";
#-- Backend timeout setting. If the time limit is reached an error will occur.
#-- The values are double the Varnish defaults.
    .connect_timeout = 7s;         #- Max wait time to connect to backend
    .first_byte_timeout = 120s;    #- Max wait time for first byte from backend
    .between_bytes_timeout = 120s; #- Max wait time for more data from backend
}
 
 
#-- http://www.varnish-cache.org/docs/3.0/tutorial/advanced_backend_servers.html
#-- Set the private IP of the master web server and the port running Apache,
#   Nginx, Tomcat, etc
backend master {
    ### WARNING: Do not pass Varnish to another Varnish instance
    .host = "127.0.0.1";
    ### If the master server has Apache/nginx/appname on port 8080, pass to 8080
    .port = "8080";
    .connect_timeout = 7s;
    .first_byte_timeout = 120s;
    .between_bytes_timeout = 120s;
}
 
 
#-- https://www.varnish-cache.org/docs/3.0/tutorial/purging.html
#-- List of servers allowed to purge the Varnish cache by sending
#-- an http PURGE request
acl purge {
    "localhost";
}
 
 
#-- vcl_hash defines the hash key to be used for a cached object.
#   Or in other words: What separates one cached object from the next.
#-- https://www.varnish-software.com/static/book/VCL_functions.html#vcl-vcl-hash
sub vcl_hash {
  #-- Keep a separate cache for HTTP and HTTPS requests that come in over
  #   an SSL Terminated Load Balancer
  if (req.http.x-forwarded-proto) {
    hash_data(req.http.x-forwarded-proto);
  }
}
 
 
#-- vcl_recv is the first VCL function executed, right after Varnish has decoded
#-- the request into its basic data structure.
#-- https://www.varnish-software.com/static/book/VCL_Basics.html#vcl-vcl-recv
sub vcl_recv {
    ########
    # NOTE #
    ########
    # return(pass)
    #   Bypasses the cache, and executes the rest of the Varnish processing as
    #   normal. It will ask the backend for content, but it will NOT look up
    #   the content in cache or store it to cache.
    #
    # return(pipe)
    #   Pipes the request, telling Varnish to shuffle bytes between the selected
    #   backend and the connected client without looking at the content. Because
    #   Varnish no longer tries to map the content to a request, any subsequent
    #   request sent over the same keep-alive connection will also be piped, and
    #   not appear in any Varnish log. Mainly useful for streaming.
    #
    #   >> !! WARNING !! <<
    #   Use pipe to bypass Varnish for testing only, NEVER use it in production
    #   unless this is the functionality you need!
    #   MORE INFO: https://www.varnish-software.com/blog/using-pipe-varnish
    #
    # return(lookup)
    #   Lookup the request in cache, if not found, fetch it from the backend and
    #   store it in cache before delivering it to the client.
    #
    # error
    #   Generate a synthetic response from Varnish. Typically an error message,
    #   redirect message or response to a health check from a load balancer.
    #
    #-- Request methods: GET,POST,HEAD,PURGE,PUT,DELETE,CONNECT,OPTIONS,TRACE
    #   https://www.varnish-software.com/static/book/HTTP.html
    #
    ########
 
    #-- https://www.varnish-cache.org/docs/3.0/tutorial/purging.html
    #-- Only allow PURGE requests from IPs in the "purge" ACL above.
    if (req.request == "PURGE") {
        if (!client.ip ~ purge) {
            error 405 "Not allowed.";
        }
        return(lookup);
    }
 
    # #-- Example for how to exclude a site from being processed by Varnish
    # if (req.http.host ~ "example.com") {
    #     set req.backend = master;
    #     return(pass);
    # }
 
    #-- If there is a LB, CloudFlare, etc, add the forwarded (real) IP of client
    if (req.restarts == 0) {
        if (req.http.x-forwarded-for) {
            set req.http.X-Forwarded-For =
            req.http.X-Forwarded-For + ", " + client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }
 
    #--------------------------------------------------------------------------#
    #-- Set some custom variables to enable/disable certain functionality.
    #-- NOTE: The variables themselves don't add the functionality, they are
    #-- used later down in the VCL where the implementation actually happens.
    #--------------------------------------------------------------------------#
    #-- Cache the home page
    # PRO: This strips the cookie from the homepage to make it load very fast.
    # CON: You may not want this if your homepage is dynamic (keeps changing).
    set req.http.allow-cache-homepage = true;
 
    #-- Remove the query string from static assets
    # PRO: Improves caching because requests with a query string will ultimately
    #      request the same cached file.
    # CON: If the query string is important, then this should be disabled so
    #      that different cached objects can be made based on the query string.
    set req.http.allow-strip-query-strings = true;
 
    #-- Send 404 responses to the master (which should have the file).
    # PRO: No broken images. The slave will fetch missing files from the master
    #      (eg. If lsync hasn't synced the file yet).
    # CON: If Lsync isn't working, you won't realise because the slave will ask
    #      the master for a missing file. The master also gets extra requests.
    set req.http.allow-sending-404s-to-master = true;
 
    #-- Cache 404 errors responses for static files for a short while.
    # PRO: Useful if the site is attacking (DoS-ing) itself due to missing files
    # CON: If the missing file is added, it won't show until the cache expires
    set req.http.allow-cache-404s = true;
 
    #-- Cache all HTTP errors responses for a while.
    # PRO: Useful if there's high traffic & errors cause more load on the server
    # CON: Errors are cached so if the problem is fixed, it won't show until the
    #      cache expires.
    set req.http.allow-caching-all-other-errors = true;
 
    #-- Send admin-ajax requests locally instead of to the master
    # PRO: If admin-ajax is called a lot, spreading these out to all servers
    #      distributes the load
    # CON: If there is an ajax request that is operating on files directly, then
    #      this should be disabled so they go to the master only.
    set req.http.allow-pass-admin-ajax-locally = true;
 
    #-- Strip the "User-Agent" value from the Vary header
    # PRO: Significantly improves caching because it prevents Varnish from
    #      storing a separate cache for each browser type & version
    # CON: Generally used to identify mobile phones/tablets and enabling this
    #      may cause that not work if the application relies on this header.
    set req.http.remove-vary-useragent = true;
 
    #-- Turn on some extra headers that can be used for debugging.
    set req.http.x-debug = true;
 
    #-- Fix WP Super Cache "feature" to not cache pages longer than 3 seconds
    #-- https://wordpress.org/support/topic/2238913
    # PRO: Pages are cached for a few minutes instead of just 3 seconds.
    #      If false, users can see page updates as quickly as 3 seconds.
    # CON: If false, the Varnish cache hitrate will suffer, because this plugin
    #      will only cache pages for 3 seconds. The plugin also doesn't seem to
    #      set Cache-Control headers for static assets (jpg, css, js, etc), so
    #      they are stored in Varnish up to the default TTL (usually 2 minutes).
    set req.http.wp-supercache-fix = true;
 
    #------------------------------------------------------------------#
 
    #-- Don't cache the these server admin/status pages
    if (req.url ~ "(?i)/(phpmyadmin|apc.php|server-status|munin)") {
      return(pass);
    }
 
    #-- Lookup 404s for static content from master and save it to the cache
    #-- locally (until lsync syncs it).
    if ( req.http.allow-sending-404s-to-master == "true"
         && req.restarts == 1
         && req.http.found404
       ) {
      set req.backend = master;
      unset req.http.cookie;
      return(lookup);
    }
 
    #-- Send admin/login pages or multipart/form-data (file uploads) or
    #-- wp-cron requests to the master server. Note: Some wp-crons start MySQL
    #-- backups that end up on the slave which can then get deleted by Lsync.
    if (req.url ~ "wp-(admin|login|cron)"
        || req.http.Content-Type ~ "multipart/form-data") {
        set req.backend = master;
        set req.http.admin-url = true;
 
        #-- Send admin-ajax requests locally if needed.
        if (req.http.allow-pass-admin-ajax-locally == "true"
            && req.url ~ "admin-ajax.php"
            && !req.http.Content-Type ~ "multipart/form-data") {
              set req.backend = default;
        }
        return(pass);
    }
 
    #-- Always cache these images and other static assets
    if (req.request ~ "GET|HEAD"
         && (req.url ~ "(?i)\.(bmp|bz2|css|eot|gif|gz|ico|img|jpeg|jpg)(\?.*|)$"
            || req.url ~ "(?i)\.(js|lzma|mp3|otf|ogg|pdf|pdf|png|svg)(\?.*|)$"
            || req.url ~ "(?i)\.(swf|tbz|tga|tgz|ttf|txt|wmf|woff|zip)(\?.*|)$"
            )) {
        set req.http.static-asset = true;
        unset req.http.cookie;
 
        #-- Strip query string from static content to allow for better caching
        if (req.http.allow-strip-query-strings == "true") {
            set req.url = regsub(req.url, "\?.*", "");
        }
        return(lookup);
    }
 
    #-- Mark these file types as static even though we may not do a cache lookup
    #-- on them. Used to identify other file types to do 404 handling.
    if (req.request ~ "GET|HEAD" && req.url ~ "(?i)\.(htm|html)(\?.*|)$") {
        set req.http.static-asset = true;
    }
 
    #-- Cache these requests: GETs should NOT be "passed" to XMLRPC only POSTs
    if (req.request ~ "GET|HEAD" && req.url ~ "(xmlrpc.php|wlmanifest.xml)") {
        unset req.http.cookie;
        return(lookup);
    }
 
    #-- Never cache POST requests
    if (req.request == "POST")
    {
        return(pass);
    }
 
    #-- DO cache THIS AJAX request
    if(req.http.X-Requested-With == "XMLHttpRequest"
       && req.url ~ "recent_reviews") {
        return (lookup);
    }
 
    #-- Don't cache other AJAX requests or requests that match these URLs
    if(req.http.X-Requested-With == "XMLHttpRequest"
        || req.url ~ "nocache"
        || req.url ~ "(control.php|wp-comments-post.php|bb-login.php)"
        || req.url ~ "(bb-reset-password.php|register.php)"
        ) {
        return (pass);
    }
 
    #-- Rename the Wordpress Test Cookie to "wpjunk" so we can exclude it later
    if (req.http.Cookie && req.http.Cookie ~ "wordpress_") {
        set req.http.Cookie =
            regsuball(req.http.Cookie, "wordpress_test_cookie=", "; wpjunk=");
    }
 
    #-- Don't cache authenticated sessions (Cookies that have the names below)
    if (req.http.Cookie && req.http.Cookie ~ "(wordpress_|PHPSESSID)") {
        return(pass);
    }
 
    #-- Reduce the Accept-Encoding header to either gzip or deflate with a
    #-- preference for the gzip algorithm, which generally compresses better
    #-- than deflate
    if (req.http.Accept-Encoding) {
        if (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            # Unkown algorithm, so remove the header
            unset req.http.Accept-Encoding;
        }
    }
 
    #-- Remove all cookies except those listed below:
    if (req.http.Cookie)
    {
        set req.http.Cookie = ";" + req.http.Cookie;
        set req.http.Cookie = regsuball(req.http.Cookie, "; +", ";");
        set req.http.Cookie = regsuball(req.http.Cookie
            #-- Strip all cookies except these:
            , ";(vendor_region|themetype2)="
            , "; \1="); # <-- Ignore. It helps to keep only the cookies above
        set req.http.Cookie = regsuball(req.http.Cookie, ";[^ ][^;]*", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "^[; ]+|[; ]+$", "");
 
        #-- If no cookies are left, remove the blank cookie header
        if (req.http.Cookie == "") {
            unset req.http.Cookie;
        }
    }
 
    #-- Cache the homepage if enabled
    if (req.url ~ "^/$") {
        if (req.http.allow-cache-homepage == "false") {
           return(pass); #-- Don't cache the come page
        } else {
          #-- We're caching the homepage, so remove the cookie first
          unset req.http.cookie;
        }
    }
 
    #-- If we get to this point, set the default action to be a "lookup", which
    #-- means we should cache this request.
    return(lookup);
}
 
 
#-- https://www.varnish-software.com/static/book/VCL_functions.html#vcl-vcl-hit
#-- vcl_hit - Called right after an object was been looked up and found (hit)
#--           in the cache.
sub vcl_hit {
    #-- If a PURGE request was sent, remove the object from Varnish's cache
    if (req.request == "PURGE") {
        set obj.ttl = 0s;
        error 200 "Purged.";
    }
}
 
 
#-- https://www.varnish-software.com/static/book/VCL_functions.html#vcl-vcl-miss
#-- vcl_miss - Called right after an object was looked up and not found in
#--            cache. The request will be fetched from the backend and added to
#--            the cache. Also used to do last minute header modifications.
sub vcl_miss {
    #-- If a PURGE request was sent and send back a not found message since it's
    #-  not in cache.
    if (req.request == "PURGE") {
        error 404 "Not in cache.";
    }
 
    #-- Remove the Cookie from the looked up item if it's not an admin url
    if ((req.http.admin-url != "true")) {
        unset req.http.cookie;
    }
 
    #-- Remove the cookie if it's a static asset and optionally strip the
    #-- query string.
    if (req.http.static-asset == "true") {
        unset req.http.cookie;
        if (req.http.allow-strip-query-strings == "true") {
            set req.url = regsub(req.url, "\?.*", "");
        }
    }
 
    #-- If the homepage caching is allowed, remove the cookie so that a generic
    #-  copy of the homepage can eventually be cached.
    if (req.http.allow-cache-homepage == "true" && req.url ~ "^/$") {
        unset req.http.cookie;
    }
}
 
 
#-- https://www.varnish-software.com/static/book/VCL_functions.html#vcl-vcl-pass
#-- vcl_pass - Runs after a "pass" in vcl_recv OR after a "lookup" that returned
#--            a hitpass. NOT run after vcl_fetch. Gets the content from backend.
sub vcl_pass {
    # Mark return(pass) calls so that we can avoid cookie stripping in vcl_fetch
    set req.http.x-pass = true;
}
 
 
#-- https://www.varnish-software.com/blog/using-pipe-varnish
#-- https://www.varnish-cache.org/docs/3.0/reference/vcl.html#subroutines
#-- vcl_pipe - Sends the request to the backend and any further data from either
#--            the client or backend is sent unaltered and uninspected by
#--            Varnish until either end closes the connection
sub vcl_pipe {
    #-- Tell the backend to close the connection as soon as it has responded to
    #-- the request so that the connection doesn't remain open and uninspected.
    set bereq.http.connection = "close";
}
 
 
#-- https://www.varnish-software.com/static/book/VCL_Basics.html#vcl-vcl-fetch
#-- vcl_fetch - Called after a document has been retrieved from the backend.
sub vcl_fetch {
    #-- If enabled, strip the User-Agent value from the Vary header if it exists
    if (beresp.http.Vary ~ "User-Agent"
        && req.http.remove-vary-useragent == "true") {
        set beresp.http.Vary =
            regsuball(beresp.http.Vary, "[, ]*User-Agent(,*)[ ]*", "\1");
        set beresp.http.Vary = regsuball(beresp.http.Vary, "^[, ]*", "");
    }
 
    #-- If "404 Not Found" for static assets, ask the master only once
    if (beresp.status == 404 && req.http.static-asset == "true"
        && req.http.allow-sending-404s-to-master == "true" && req.restarts == 0
    ) {
      set req.http.found404 = true;
      return(restart);
    }
 
    #-- Special 404 handling
    if (beresp.status == 404) {
        #-- Strip the Set-Cookie header that sometimes get sent with 404 errors
        #-- which can cause anonymous users to have a Cookie and not cache pages
        unset beresp.http.set-cookie;
 
        #-- Cache 404 responses for static assets for a short while
        if (req.http.static-asset == "true"
            && req.http.allow-cache-404s == "true") {
          set beresp.ttl = 30s; # Other valid option examples: 10m, 1h, etc
          return(deliver);
        }
    }
 
    #-- Decide how to handle all other errors
    if (beresp.status >= 400) {
      #-- Strip the Set-Cookie header as explained previously
      unset beresp.http.set-cookie;
 
      if (req.http.allow-caching-all-other-errors == "true") {
        #-- Cache all other errors for a short while
        set beresp.ttl = 10s; # Other valid option examples: 10m, 1h, etc
        return(deliver);
      } else {
        #-- Don't cache other errors at all.
        return(hit_for_pass);
      }
    }
 
    #-- Remove the Set-Cookie header if homepage caching is enabled
    if (req.http.allow-cache-homepage == "true" && req.url ~ "^/$") {
        unset beresp.http.set-cookie;
    }
 
    #-- Wordpress Super Cache Fix: Detect "max-age=3" and reset the header so
    #-- that pages will be cached for a while.
    if (beresp.http.Cache-Control ~ "(?i)max-age=3,"
          && req.http.wp-supercache-fix == "true") {
          set beresp.http.Cache-Control =
            regsuball(beresp.http.Cache-Control # <-- Search this HTTP header
              , "max-age=3,"  # <-- Find this value
              , "public,max-age=120,"); # <-- Replace with this value
 
          # Reset Varnish's TTL (i.e. how long it will cache).
          # This must be done because Varnish would have cache for only 3
          # seconds since that was the original "max-age" setting.
          set beresp.ttl = 120s;
    }
 
    #-- Resolve issues with content that is generated and delivered as a stream.
    #-- Deliver the object to the client directly without fetching the whole
    #-- object into Varnish.
    # NOTE: Disabled until needed.
    # if(beresp.http.Content-Type ~ "(?i)(video|stream)") {
    #     set beresp.do_stream = true;
    # }
 
    #-- Strip the Set-Cookie response from the backend for everything EXCEPT
    #-- things that are "passed" or admin urls. It makes the cache more generic
    if (!(req.http.x-pass == "true" || req.http.admin-url == "true")) {
        unset beresp.http.set-cookie;
    }
}
 
# http://www.varnish-software.com/static/book/VCL_functions.html#vcl-vcl-deliver
#-- vcl_deliver - Last function called, often used to add/remove debug-headers
sub vcl_deliver {
  if (req.http.x-debug == "true") {
    # set resp.http.X-Cache-Hits = obj.hits;
    #-- Set headers to indicate if request item HIT or MISSed the cache
    if (obj.hits > 0) {
      set resp.http.X-Cache = resp.http.X-Cache + " HIT";
    } else {
      set resp.http.X-Cache = resp.http.X-Cache + " MISS";
    }
  }
}
