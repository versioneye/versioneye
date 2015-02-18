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

      di = DockerImage.by_name("veye/rails_app")
      version = di.image_version.to_s
      images["veye/rails_app:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '8080/tcp' => [{'HostPort' => '8080'}]},
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/logs:/rails/log'], 
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }

      di = DockerImage.by_name("veye/rails_api")
      version = di.image_version.to_s
      images["veye/rails_api:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '9090/tcp' => [{'HostPort' => '9090'}]},
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/logs:/rails/log'], 
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }

      di = DockerImage.by_name("veye/tasks")
      version = di.image_version.to_s
      images["veye/tasks:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/tasks/logs:/versioneye-tasks/log'], 
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }

      di = DockerImage.by_name("veye/crawlr")
      version = di.image_version.to_s
      images["veye/crawlr:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/cocoapods:/mnt/cocoapods'], 
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }

      di = DockerImage.by_name("veye/crawlj")
      version = di.image_version.to_s
      images["veye/crawlj:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'], 
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }


      di = DockerImage.by_name("reiz/mongodb")
      version = di.image_version.to_s
      images["reiz/mongodb:#{version}"] = {
        'container_start_opts' => {
          # 'PortBindings' => { '27017/tcp' => [{'HostPort' => '27017'}]},
          'Binds' => ['/mnt/mongodb:/data'], 
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => false,
        'comments' => di.description
      }

      di = DockerImage.by_name("reiz/elasticsearch")
      version = di.image_version.to_s
      images["reiz/elasticsearch:#{version}"] = {
        'container_start_opts' => {
          # 'PortBindings' => { '9200/tcp'  => [{'HostPort' => '9200'}], '9300' => [{'HostPort' => '9300'}]},
          'Binds' => ['/mnt/elasticsearch:/data'], 
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => false,
        'comments' => di.description
      }

      di = DockerImage.by_name("reiz/memcached")
      version = di.image_version.to_s
      images["reiz/memcached:#{version}"] = {
        'container_start_opts' => {
          # 'PortBindings' => { '11211/tcp' => [{'HostPort' => '11211'}]}, 
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => false,
        'comments' => di.description
      }

      di = DockerImage.by_name("reiz/rabbitmq")
      version = di.image_version.to_s
      images["reiz/rabbitmq:#{version}"] = {
        'container_start_opts' => {
          # 'PortBindings' => { '5672/tcp' => [{'HostPort' => '5672'}]}, 
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => false,
        'comments' => di.description
      }

      images
    end

end
