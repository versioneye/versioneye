class AuthorsController < ApplicationController


  def show 
    name_id = params[:id]
    @author = Author.find_by :name_id => name_id
  end


end
