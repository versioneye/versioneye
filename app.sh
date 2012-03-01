#!/bin/bash

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
        *)
                echo "Usage: $0 {deploy}"
                ;;
esac