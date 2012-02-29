#!/bin/bash
# josh 11-23-2004
# shell script to ...

#set the full path to the programs we need to use
UNICORN=/var/lib/gems/1.9.1/bin/unicorn_rails
KILLALL=/usr/bin/killall

case "$1" in
        deploy)
                git checkout Gemfile
                git checkout Gemfile.lock
                git checkout config/database.yml
                git checkout config/mongoid.yml
                git pull
                cp ../database.yml config/database.yml
                cp ../mongoid.yml config/mongoid.yml
                bundle install
                rake db:migrate
                rake assets:precompile
                unicorn_rails -p8080 -D
                ;;
        start)
                #run ntop for web monitoring
                echo "Starting app1..."
                $UNICORN -p8080 -D
                ;;
        stop)
                #kill ntop
                echo "Stopping nXtop..."
                $KILLALL UNICORN
                ;;
        restart)
                $0 stop
                $0 start
                ;;
        status)
                ;;
        *)
                echo "Usage: $0 {start|stop|restart|status}"
                ;;
esac