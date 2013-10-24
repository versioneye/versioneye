Runtime-Dependencies
====================

Install binary dependencies with Homebrew on OS X

```sh
brew install elasticsearch mongodb
```

## ElasticSearch

```
Data:    /usr/local/var/elasticsearch/elasticsearch_anjaresmer/
Logs:    /usr/local/var/log/elasticsearch/elasticsearch_anjaresmer.log
Plugins: /usr/local/var/lib/elasticsearch/plugins/

To have launchd start elasticsearch at login:
    ln -sfv /usr/local/opt/elasticsearch/*.plist ~/Library/LaunchAgents
Then to load elasticsearch now:
    launchctl load ~/Library/LaunchAgents/homebrew.mxcl.elasticsearch.plist
Or, if you don't want/need launchctl, you can just run:
    elasticsearch -f -D es.config=/usr/local/opt/elasticsearch/config/elasticsearch.yml
```


## Mongodb

```
To have launchd start mongodb at login:
    ln -sfv /usr/local/opt/mongodb/*.plist ~/Library/LaunchAgents
Then to load mongodb now:
    launchctl load ~/Library/LaunchAgents/homebrew.mxcl.mongodb.plist
Or, if you don't want/need launchctl, you can just run:
    mongod
```
