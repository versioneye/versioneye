class AuthorsController < ApplicationController


  def index
    @authors = Author.desc(:products_count).paginate(:page => params[:page], :per_page => 100)
  end


  def show 
    name_id = params[:id]
    @author = Author.find_by :name_id => name_id
  end


end
