#!/bin/bash

case "$1" in
        update)
                git checkout Gemfile
                git checkout Gemfile.lock
                git checkout config/mongoid.yml
                git pull
                cp ../mongoid.yml config/mongoid.yml
                bundle install
                ;;
        *)
                echo "Usage: $0 {update}"
                ;;
esac