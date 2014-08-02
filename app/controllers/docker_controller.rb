class DockerController < ApplicationController

  def remote_images
    images = remote_images_hash
    respond_to do |format|
      format.json {
        render :json => images.to_json
      }
      format.html {
        @r_images = images
      }
    end
  end

  private

    def remote_images_hash
      images = {}

      images['veye/rails_app:2.3.5'] = {
        'container_start_opts' => {
          'PortBindings' => { '8080/tcp' => [{'HostPort' => '8080'}]},
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm']
        },
        'auth' => true,
        'comments' => 'First version'
      }

      images['veye/tasks:1.0.11'] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm']
        },
        'auth' => true,
        'comments' => 'First version'
      }

      images['veye/rails_api:1.0.3'] = {
        'container_start_opts' => {
          'PortBindings' => { '9090/tcp' => [{'HostPort' => '9090'}]},
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc']
        },
        'auth' => true,
        'comments' => 'First version'
      }

      images['veye/crawlr:1.0.0'] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db'],
          'Binds' => ['/mnt/cocoapods:/mnt/cocoapods']
        },
        'auth' => true,
        'comments' => 'First version'
      }

      images['reiz/mongodb:1.0.2'] = {
        'container_start_opts' => {
          'PortBindings' => { '27017/tcp' => [{'HostPort' => '27017'}]},
          'Binds' => ['/mnt/mongodb:/data']
        },
        'auth' => false,
        'comments' => 'With MongoDB 2.6.3'
      }

      images['reiz/elasticsearch:0.9.0'] = {
        'container_start_opts' => {
          'PortBindings' => { '9200/tcp'  => [{'HostPort' => '9200'}], '9300' => [{'HostPort' => '9300'}]},
          'Binds' => ['/mnt/elasticsearch:/data']
        },
        'auth' => false,
        'comments' => 'With ElasticSearch 1.0.0'
      }

      images['reiz/memcached:1.0.0'] = {
        'container_start_opts' => {
          'PortBindings' => { '11211/tcp' => [{'HostPort' => '11211'}]}
        },
        'auth' => false,
        'comments' => 'First version'
      }

      images['reiz/rabbitmq:1.0.0'] = {
        'container_start_opts' => {
          'PortBindings' => { '5672/tcp' => [{'HostPort' => '5672'}]}
        },
        'auth' => false,
        'comments' => 'Run the Rabbit!'
      }

      images
    end

end
