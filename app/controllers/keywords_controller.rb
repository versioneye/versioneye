class KeywordsController < ApplicationController


  def show 
    keyword = params[:id]
    language = params[:language]
    query = []
    if language.to_s.empty? 
      query = Product.where(:tags => keyword)
    else 
      language = Product.decode_language language
      query = Product.where(:tags => keyword, :language => language)
    end
    @products = query.desc(:used_by_count).paginate(:page => params[:page])
  end


end
