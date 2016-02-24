FROM        versioneye/ruby-base:1.9.2
MAINTAINER  Robert Reiz <reiz@versioneye.com>

ADD . /app

ADD veye_deploy_rsa /root/.ssh/id_rsa

RUN chmod go-rwx /root/.ssh/id_rsa && \
    cd /root/.ssh; ssh-agent -s; eval $(ssh-agent); ssh-add id_rsa && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN bundle install

EXPOSE 8080

CMD bundle exec puma -C config/puma.rb
