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

      images['reiz/memcached:1.0.0']     = {
        'container_start_opts' => {'PortBindings' => { '11211/tcp' => [{'HostPort' => '11211'}]}},
        'comments' => 'First version' }

      images['reiz/mongodb:1.0.0']       = {
        'container_start_opts' => {'PortBindings' => { '27017/tcp' => [{'HostPort' => '27017'}]},
        'Binds' => ['/mnt/mongodb:/data']},
        'comments' => 'First version' }

      images['reiz/elasticsearch:1.0.1'] = {
        'container_start_opts' => {'PortBindings' => { '9200/tcp'  => [{'HostPort' => '9200'}], '9300' => [{'HostPort' => '9200'}]},
        'Binds' => ['/mnt/elasticsearch:/data']},
        'comments' => 'First version'
      }
      images
    end

end
