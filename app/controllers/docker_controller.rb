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

      images['veye/rails_app:1.0.0'] = {
        'container_start_opts' => {
          'PortBindings' => { '8080/tcp' => [{'HostPort' => '8080'}]},
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc']
        },
        'comments' => 'First version'
      }

      images['veye/rails_api:1.0.0'] = {
        'container_start_opts' => {
          'PortBindings' => { '9090/tcp' => [{'HostPort' => '9090'}]},
          'Links' => ['mongodb:db', 'elasticsearch:es', 'memcached:mc']
        },
        'comments' => 'First version'
      }

      images['veye/crawlr:1.0.0'] = {
        'container_start_opts' => {
          'Links' => ['mongodb:db'],
          'Binds' => ['/mnt/cocoapods:/mnt/cocoapods']
        },
        'comments' => 'First version'
      }

      images['reiz/mongodb:1.0.0'] = {
        'container_start_opts' => {
          'PortBindings' => { '27017/tcp' => [{'HostPort' => '27017'}]},
          'Binds' => ['/mnt/mongodb:/data']
        },
        'comments' => 'First version'
      }

      images['reiz/elasticsearch:1.0.1'] = {
        'container_start_opts' => {
          'PortBindings' => { '9200/tcp'  => [{'HostPort' => '9200'}], '9300' => [{'HostPort' => '9200'}]},
          'Binds' => ['/mnt/elasticsearch:/data']
        },
        'comments' => 'First version'
      }

      images['reiz/memcached:1.0.0'] = {
        'container_start_opts' => {
          'PortBindings' => { '11211/tcp' => [{'HostPort' => '11211'}]}
        },
        'comments' => 'First version'
      }

      images
    end

end
