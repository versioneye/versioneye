#!/bin/bash

case "$1" in
        update)
                git checkout Gemfile
                git checkout Gemfile.lock
                git checkout config/database.yml
                git checkout config/mongoid.yml
                git pull
                cp ../database.yml config/database.yml
                cp ../mongoid.yml config/mongoid.yml
                bundle install
                rake assets:precompile
                ;;
        *)
                echo "Usage: $0 {update}"
                ;;
esac