FROM        versioneye/ruby-base:2.3.3-8
MAINTAINER  Robert Reiz <reiz@versioneye.com>

RUN rm -Rf /app; \
    mkdir /app

ADD . /app

RUN cd /app/ && bundle install;

EXPOSE 8080

CMD /app/start.sh
