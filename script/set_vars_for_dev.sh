#!/bin/bash

# MongoDB
export DB_PORT_27017_TCP_ADDR=127.0.0.1
export DB_PORT_27017_TCP_PORT=27017

# ElasticSearch
export ES_PORT_9200_TCP_ADDR=127.0.0.1
export ES_PORT_9200_TCP_PORT=9200

# RabbitMQ
export RM_PORT_5672_TCP_ADDR=127.0.0.1
export RM_PORT_5672_TCP_PORT=5672

# Memcache
export MC_PORT_11211_TCP_ADDR=127.0.0.1
export MC_PORT_11211_TCP_PORT=11211

# Stripe test credentials
export STRIPE_PUBLIC_KEY=
export STRIPE_SECRET_KEY=

# AWS veye_test user
export AWS_S3_ACCESS_KEY_ID=
export AWS_S3_SECRET_ACCESS_KEY=
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

# bitbucket credentials for the OAuth client
export BITBUCKET_TOKEN=
export BITBUCKET_SECRET=

# bitbucket user credentials
export BITBUCKET_USERNAME=
export BITBUCKET_PASSWORD=
export BITBUCKET_USER_TOKEN=
export BITBUCKET_USER_SECRET=

export GITHUB_CLIENT_ID=
export GITHUB_CLIENT_SECRET=

export RAILS_ENV="development"
echo "Rails mode: $RAILS_ENV"
