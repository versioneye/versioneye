class DockerController < ApplicationController

  def update_image
    updated = false
    api = Api.where(:api_key => params[:api_key]).first
    if api && api.update_di == true
      di = DockerImage.by_name( params[:image] )
      di.image_version = params[:version]
      updated = di.save
    end

    respond_to do |format|
      format.json {
        render :json => {'updated': updated}
      }
    end
  end

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

      di = DockerImage.by_name("versioneye/rails_app")
      version = di.image_version.to_s
      images["versioneye/rails_app:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '8080/tcp' => [{'HostPort' => '8080'}]},
          'NetworkSettings' => { 'Ports' => { '8080/tcp' => [{'HostPort' => '8080'}] }  },
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/logs:/app/log'],
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }

      di = DockerImage.by_name("versioneye/rails_api")
      version = di.image_version.to_s
      images["versioneye/rails_api:#{version}"] = {
        'container_start_opts' => {
          'PortBindings' => { '9090/tcp' => [{'HostPort' => '9090'}] },
          'NetworkSettings' => { 'Ports' => { '9090/tcp' => [{'HostPort' => '9090'}] }  },
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/logs:/app/log'],
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }

      di = DockerImage.by_name("versioneye/tasks")
      version = di.image_version.to_s
      images["versioneye/tasks:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/logs:/app/log'],
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }

      di = DockerImage.by_name("versioneye/crawlr")
      version = di.image_version.to_s
      images["versioneye/crawlr:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/cocoapods:/mnt/cocoapods', '/mnt/logs:/app/log'],
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }

      di = DockerImage.by_name("versioneye/crawlj")
      version = di.image_version.to_s
      images["versioneye/crawlj:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/logs:/mnt/logs'],
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }

      di = DockerImage.by_name("versioneye/crawlj_worker")
      version = di.image_version.to_s
      images["versioneye/crawlj_worker:#{version}"] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc', 'rabbitmq:rm'],
          'Binds' => ['/mnt/logs:/mnt/logs'],
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => true,
        'comments' => di.description
      }


      di = DockerImage.by_name("versioneye/mongodb")
      version = di.image_version.to_s
      images["versioneye/mongodb:#{version}"] = {
        'container_start_opts' => {
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
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => false,
        'comments' => di.description
      }

      di = DockerImage.by_name("reiz/rabbitmq")
      version = di.image_version.to_s
      images["reiz/rabbitmq:#{version}"] = {
        'container_start_opts' => {
          'RestartPolicy' => {'Name' => 'always'}
        },
        'auth' => false,
        'comments' => di.description
      }

      images
    end

end
