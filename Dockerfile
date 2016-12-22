FROM        versioneye/ruby-base:2.4.5
MAINTAINER  Robert Reiz <reiz@versioneye.com>

ADD . /app

RUN cd /app/ && bundle install;

EXPOSE 8080

CMD bundle exec puma -C config/puma.rb
