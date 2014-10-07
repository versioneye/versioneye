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

      version = DockerImage.version("veye/rails_app")
      version = '2.6.14' if version.to_s.empty?
      images["veye/rails_app:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '8080/tcp' => [{'HostPort' => '8080'}]},
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/logs:/rails/log']
        },
        'auth' => true,
        'comments' => 'With License Whitelist'
      }

      version = DockerImage.version("veye/rails_api")
      version = '2.1.12' if version.to_s.empty?
      images["veye/rails_api:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '9090/tcp' => [{'HostPort' => '9090'}]},
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/logs:/rails/log']
        },
        'auth' => true,
        'comments' => 'With updated versioneye-core'
      }

      version = DockerImage.version("veye/tasks")
      version = '1.7.4' if version.to_s.empty?
      images["veye/tasks:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/tasks/logs:/versioneye-tasks/log']
        },
        'auth' => true,
        'comments' => 'With new scheduler'
      }

      version = DockerImage.version("veye/crawlr")
      version = '1.1.1' if version.to_s.empty?
      images["veye/crawlr:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/cocoapods:/mnt/cocoapods']
        },
        'auth' => true,
        'comments' => 'Improvements for CocoaPods'
      }

      version = DockerImage.version("veye/crawlj")
      version = '1.0.0' if version.to_s.empty?
      images["veye/crawlj:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm']
        },
        'auth' => true,
        'comments' => 'First version'
      }


      version = DockerImage.version("veye/mongodb")
      version = '1.0.2' if version.to_s.empty?
      images["reiz/mongodb:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '27017/tcp' => [{'HostPort' => '27017'}]},
          'Binds' => ['/mnt/mongodb:/data']
        },
        'auth' => false,
        'comments' => 'With MongoDB 2.6.3'
      }

      version = DockerImage.version("veye/elasticsearch")
      version = '0.9.0' if version.to_s.empty?
      images["reiz/elasticsearch:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '9200/tcp'  => [{'HostPort' => '9200'}], '9300' => [{'HostPort' => '9300'}]},
          'Binds' => ['/mnt/elasticsearch:/data']
        },
        'auth' => false,
        'comments' => 'With ElasticSearch 1.0.0'
      }

      version = DockerImage.version("veye/memcached")
      version = '1.0.0' if version.to_s.empty?
      images["reiz/memcached:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '11211/tcp' => [{'HostPort' => '11211'}]}
        },
        'auth' => false,
        'comments' => 'First version'
      }

      version = DockerImage.version("veye/rabbitmq")
      version = '1.0.0' if version.to_s.empty?
      images["reiz/rabbitmq:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '5672/tcp' => [{'HostPort' => '5672'}]}
        },
        'auth' => false,
        'comments' => 'Run the Rabbit!'
      }

      images
    end

end
