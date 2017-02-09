# rootz-quiver


## get started
### install
```
$ gem install sinatra sinatra-contrib thin haml rouge logger sass
$ git clone https://github.com/snailoff/rootz-quiver.git
```

### config your setting

first, copy ``setting.default`` file to ``setting`` file.

```
$ cp setting.default setting

```

then edit 'setting' file.

``` 
{
	"qvlibrary_path" : "public/root/YOUR QUIVER QVLIBRARY'S PATH", 
	"default_notebook" : "DEFAULT NOTEBOOK NAME"
}
```

### run
```
$ cd rootz-quiver
$ thin start
or throuth nohup
$ nohup thin start &

```

### thin & apache

if you want run on apache, and you maybe need mod_proxy.

```
$ cd apache_source_path/module/proxy

$ /your_apache_path/bin/apxs -i -a -c mod_proxy.c proxy_util.c
$ /your_apache_path/bin/apxs -i -a -c mod_proxy_http.c proxy_util.c
```

```
# httpd.conf
...
<VirtualHost *:80>
    ServerName rootz.yourdomain.com

    ProxyPass / http://127.0.0.1:3000/
    ProxyPassReverse / http://127.0.0.1:3000/

    ErrorLog "logs/rootz.error_log"
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    CustomLog "logs/rootz.access_log" combined
</VirtualHost>
...
```


