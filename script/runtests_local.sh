#!/bin/bash

export DB_PORT_27017_TCP_ADDR=172.16.148.134
export DB_PORT_27017_TCP_PORT=27017

export ES_PORT_9200_TCP_ADDR=172.16.148.134
export ES_PORT_9200_TCP_PORT=9200

export RM_PORT_5672_TCP_ADDR=172.16.148.134
export RM_PORT_5672_TCP_PORT=5672

export MC_PORT_11211_TCP_ADDR=172.16.148.134
export MC_PORT_11211_TCP_PORT=11211

echo "Going to run all specs"
export RAILS_ENV="test"
echo "Rails mode: $RAILS_ENV"

rspec

export RAILS_ENV="development"
echo "Rails mode: $RAILS_ENV"
