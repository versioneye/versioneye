#!/bin/bash

echo "Going to run all specs"
export RAILS_ENV="test"
echo "Rails mode: $RAILS_ENV"

# rake db:drop && rake db:create && rake db:migrate
rspec

export RAILS_ENV="development"
echo "Rails mode: $RAILS_ENV"
