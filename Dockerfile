FROM        versioneye/ruby-base:1.9.2
MAINTAINER  Robert Reiz <reiz@versioneye.com>

ADD . /app

RUN mkdir -p /root/.ssh; \
    cp /app/veye_deploy_rsa /root/.ssh/id_rsa; \
    chmod go-rwx /root/.ssh/id_rsa && \
    cd /root/.ssh; ssh-agent -s; eval $(ssh-agent); ssh-add id_rsa && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts \
    cd /app/ && bundle install; \
    rm /root/.ssh/id_rsa

EXPOSE 8080

CMD bundle exec puma -C config/puma.rb
