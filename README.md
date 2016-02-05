# Overview

Using SSL/TLS-based certificate authentication via an Apache reverse
proxy in a Flask application 

Flask is a popular microframework for building Python web
applications.  SSL/TLS are the standard cryptographic protocols for
Internet security.  The Apache HTTP server is a popular web
application that easily works as a reverse proxy.

This repository contains a complete example of using client
certificates (or other forms of server-based authentication) to
provide authentication to a Flask application.  This can be useful in
a variety of contexts such as enterprise scenarios where
authentication is handled by the web server and authorization is
handled by the web application. 

# Contents

* Steps for generating self-signed certificate keychains mimicking a complete certificate authority
* a Dockerfile containing a minimal Flask application using secure
  headers via flask-login to authenticate a user session, and using conda dependencies
* a Dockerfile containing a compatible Apache installation and configuration
* Instructions for building and running the web server and Flask
  application as independent, then linked Docker containers
* Instructions for installing the client into OS X and accessing the services through a web browser and the command line.

# Generating a Certificate Authority and CA-signed certificates

The script here loosely follows the tutorial
[Creating Your Own SSL Certificate Authority (and Dumping Self Signed Certs)](http://datacenteroverlords.com/2012/03/01/creating-your-own-ssl-certificate-authority/)
and borrows from a script in [self-signed-ssl-certificates](https://serversforhackers.com/self-signed-ssl-certificates).

Run the script `generate-keys.sh`:

```
bash generate-keys.sh
```

You should see output similar to:

```
Generating RSA private key, 2048 bit long modulus
........................................+++
.....................+++
e is 65537 (0x10001)
No value provided for Subject Attribute O, skipped
No value provided for Subject Attribute organizationalUnitName, skipped
No value provided for Subject Attribute emailAddress, skipped
Generating RSA private key, 2048 bit long modulus
.....................................................................+++
...................+++
e is 65537 (0x10001)
Generating RSA private key, 2048 bit long modulus
......................+++
................+++
e is 65537 (0x10001)
Generating RSA private key, 2048 bit long modulus
...................................................................+++
.....+++
e is 65537 (0x10001)
No value provided for Subject Attribute O, skipped
No value provided for Subject Attribute organizationalUnitName, skipped
No value provided for Subject Attribute emailAddress, skipped
No value provided for Subject Attribute O, skipped
No value provided for Subject Attribute organizationalUnitName, skipped
No value provided for Subject Attribute emailAddress, skipped
No value provided for Subject Attribute O, skipped
No value provided for Subject Attribute organizationalUnitName, skipped
No value provided for Subject Attribute emailAddress, skipped
Signature ok
subject=/C=US/ST=Virginia/CN=*.flask.local
Getting CA Private Key
Signature ok
subject=/C=US/ST=Virginia/CN=Grace Hopper
Getting CA Private Key
Signature ok
subject=/C=US/ST=Virginia/CN=Cecilia Payne
Getting CA Private Key
flask-local/server.crt: OK
flask-local/grace.crt: OK
flask-local/cecilia.crt: OK
copying server.crt and server.key to dockerfiles/apache
exporting client certificates in pkcs12
1 certificate imported.
1 certificate imported.
```

See the script itself for more details.  The contents of the
`flask-local` directory will now contain a root CA (root.pem), as well
as three certificates that will represent the server and two users.

You can now add the client certificates to your security toolchain.
On OS X:

```
security import ./flask-local/grace.p12  -P password
security import ./flask-local/cecilia.p12  -P password
```

As an optional final step, you can install the root certificate into
your local system.  This will allow your web browser and system tools
such as curl to treat the server certificate as trusted.

On OS X, the command looks like:

```
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain flask-local/root.pem
```

# Building the Apache image

If you have Docker correctly installed and configured on your machine
(I use Docker Machine on OS X), you should be able to build an image
that contains the basic SSL configuration and signed keys with the
following commands:

```
cd dockerfiles/apache
docker build -t apache-ssl .
```

You can then run the Apache server (detached):

```
docker run --name=apache-ssl -d -p 443:443 apache-ssl
```

In order to connect to your development server, you may need to add
the following line to /etc/hosts:

```
127.0.0.1 flask.local
```

You may also need to forward port 443 to your docker machine, e.g. for a
docker machine named `base`:

```
sudo ssh -i ~/.docker/machine/machines/base/id_rsa -L 443:localhost:443 docker@$(docker-machine ip base)
```

If everything is working correctly, you should be able to securely
connect to the server using either your web browser (`open https://flask.local`) or curl:

```
curl -v --cert "Grace Hopper" https://flask.local/
*   Trying 127.0.0.1...
* Connected to flask.local (127.0.0.1) port 443 (#0)
* Client certificate: Grace Hopper
* TLS 1.2 connection using TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384
* Server certificate: flask.local
* Server certificate: Root Flask Local Certificate Authority
> GET / HTTP/1.1
> Host: flask.local
> User-Agent: curl/7.43.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Date: Fri, 05 Feb 2016 10:25:28 GMT
< Server: Apache/2.2.22 (Debian)
< Last-Modified: Fri, 05 Feb 2016 09:30:54 GMT
< ETag: "e3-b1-52b0281f80f80"
< Accept-Ranges: bytes
< Content-Length: 177
< Vary: Accept-Encoding
< Content-Type: text/html
<
<html><body><h1>It works!</h1>
<p>This is the default web page for this server.</p>
<p>The web server software is running but no content has been added, yet.</p>
</body></html>
* Connection #0 to host flask.local left intact
```

# Building the Flask Server image

Starting from the root directory of this repository:

```
cd dockerfiles/flask-server
docker build -t flask-server .
```

You can then run the Flask server.  It's best not to detach the server
so you can see requests:

```
docker run --name=flask-server -p 5000:5000 flask-server
```

Again, you may need to do some additional port forwarding work on OS
X:

```
sudo ssh -i ~/.docker/machine/machines/base/id_rsa -L 5000:localhost:5000 -L 443:localhost:443 docker@$(docker-machine ip base)
```

You can either `curl localhost:5000` or use your web browser to
trigger some logging output:

```
 * Running on http://0.0.0.0:5000/ (Press CTRL+C to quit)
 * Restarting with stat
 * Debugger is active!
 * Debugger pin code: 299-046-169
{'view_args': {}, 'environ': {'REQUEST_METHOD': 'GET', 'CONTENT_LENGTH': '', 'wsgi.url_scheme': 'http', 'REMOTE_ADDR': '172.17.42.1', 'HTTP_CONNECTION': 'keep-alive', 'wsgi.errors': <_io.TextIOWrapper name='<stderr>' mode='w' encoding='ANSI_X3.4-1968'>, 'wsgi.multithread': False, 'SCRIPT_NAME': '', 'SERVER_SOFTWARE': 'Werkzeug/0.11.3', 'wsgi.version': (1, 0), 'HTTP_ACCEPT_LANGUAGE': 'en-US,en;q=0.8', 'PATH_INFO': '/', 'SERVER_NAME': '0.0.0.0', 'wsgi.input': <_io.BufferedReader name=8>, 'HTTP_ACCEPT': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8', 'REMOTE_PORT': 49674, 'werkzeug.request': <Request 'http://localhost:5000/' [GET]>, 'wsgi.multiprocess': False, 'HTTP_HOST': 'localhost:5000', 'HTTP_CACHE_CONTROL': 'max-age=0', 'QUERY_STRING': '', 'SERVER_PORT': '5000', 'HTTP_UPGRADE_INSECURE_REQUESTS': '1', 'werkzeug.server.shutdown': <function WSGIRequestHandler.make_environ.<locals>.shutdown_server at 0x7fee4aa28f28>, 'HTTP_COOKIE': 'csrftoken=oZs3xAGhBl4BMMtRnt0DFcOr4UkBUaHb; wakari.a=ab504c01bf59db44eedd7cbedc2a880074f3ed5f; x_csrf_token=1449256394##78c037ab2672c5f11901cd183b5379dbfda49527; XSRF-TOKEN=1449256394##78c037ab2672c5f11901cd183b5379dbfda49527; wakari.enterprise.session=.eJw9zLEKwjAQgOFXkZsdNIlLoYNgkQh3pVIsuaVgq8RLo6BC0dJ3N5Pz__NN0N56yCZYnCEDlJMvdxRJOoPRfrixo5NqxRLWpCqDYhWqY0g9h3kJ3et5bd-PcLn_CW6KDUmhy_rgcW81135w0ofEfDlSLBseULmRhYb0GayDpm2euPkHML0s9w.CUNpOg.PncaDFJMiMZ-YOLT4K7se_PkBAA', 'HTTP_USER_AGENT': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.97 Safari/537.36', 'HTTP_ACCEPT_ENCODING': 'gzip, deflate, sdch', 'wsgi.run_once': False, 'CONTENT_TYPE': '', 'SERVER_PROTOCOL': 'HTTP/1.1'}, 'url_rule': <Rule '/' (HEAD, GET, OPTIONS) -> hello>, 'url': 'http://localhost:5000/', 'shallow': False}
172.17.42.1 - - [05/Feb/2016 08:35:19] "GET / HTTP/1.1" 200 -
```

In your web browser or curl you should see:

```
Hello Unauthorized!%
```

# Linking the Apache and Flask Server

In order to link the Apache server on to Flask, you need to run the
Apache container with an additional link argument:

```
docker run --name=apache-ssl -p 443:443 --link flask-server:flask-server apache-ssl
```

Note that you may need to destroy and remove your earlier container
named apache-ssl in order to execute this one correctly.

You can test that the SSL proxy authentication is executing correctly
with the following commands:

```
curl --cert "Grace Hopper" https://flask.local/flask/
Hello Grace Hopper!
curl --cert "Cecilia Payne" https://flask.local/flask/
Hello Cecilia Payne!
```

# Using this approach in enterprise security

The Apache reverse proxy configuration summarized below is sufficient
for providing certificate-based authentication to Flask applications:

```
<VirtualHost *:443>

SSLVerifyClient require
SSLVerifyDepth 1

SSLCertificateFile    conf/server.crt
SSLCertificateKeyFile conf/server.key
SSLCACertificateFile conf/root.pem
SSLEngine on
SSLProtocol all -SSLv2
SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM

# Proxy configuration
RequestHeader set SSL_CLIENT_S_DN    ""
RequestHeader set SSL_CLIENT_I_DN    ""
RequestHeader set SSL_SERVER_S_DN_OU ""
RequestHeader set SSL_CLIENT_VERIFY  ""

ProxyRequests off
ProxyPass /flask/ http://flask-server:5000/
ProxyHTMLURLMap http://flask-server:5000 /flask

<Location /flask/>
     RequestHeader set SSL_CLIENT_S_DN "%{SSL_CLIENT_S_DN}s"
     RequestHeader set SSL_CLIENT_I_DN "%{SSL_CLIENT_I_DN}s"
     RequestHeader set SSL_SERVER_S_DN_OU "%{SSL_SERVER_S_DN_OU}s"
     RequestHeader set SSL_CLIENT_VERIFY "%{SSL_CLIENT_VERIFY}s"
     ProxyPassReverse /
     ProxyHTMLInterp On
     ProxyHTMLURLMap  /      /flask/
     RequestHeader    unset  Accept-Encoding
</Location>

</VirtualHost>
```

The most important directive here is setting the SSL_CLIENT_S_DN
header.  Note that it is first set to the empty string to prevent
spoofing attacks, then set from the subject's name in their
certificate, which is in turn trusted by the certificate authority
we installed earlier.

On the Flask side, this header can be used to provide authentication:

```
@app.route('/')
def hello():
    s_dn = request.environ.get('HTTP_SSL_CLIENT_S_DN')
    if s_dn:
        name = dict([x.split('=') for x in s_dn.split('/')[1:]])['CN']
        return 'Hello {}!\n'.format(name)
    else:
        return "Hello Unauthorized!"
```

A more complicated example would login from an LDAP or other service
given the client's certificate:

```
@login_manager.request_loader
def load_user_from_request(request):
    s_dn = request.environ.get('HTTP_SSL_CLIENT_S_DN')
    if s_dn:
        name = dict([x.split('=') for x in s_dn.split('/')[1:]])['CN']
        user = User.query.filter_by(name=name).first()
        if user:
            return user
	# no authentication, don't log in.
    return None
```

Note that Apache can be configured to allow anonymous browsing access
or to strictly deny clients without certificates or other security tokens.
