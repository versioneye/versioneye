class KeywordsController < ApplicationController


  def show
    keyword = params[:id]
    @lang   = get_lang_value( params[:language] )
    query = []
    if @lang.to_s.empty? || @lang.to_s.eql?(",")
      query = Product.where(:tags => keyword)
    else
      languages = get_language_array(@lang)
      query = Product.where(:tags => keyword, :language.in => languages)
    end
    @products = query.desc(:used_by_count).paginate(:page => params[:page])
    @languages = Product::A_LANGS_FILTER
  end


end
