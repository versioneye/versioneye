class Admin::LanguageController < ApplicationController
  #before_filter :admin_user

  def index
    @languages = Language.all.desc(:updated_at)
  end

  def show
    language = Language.where(param_name: params[:id]).first
    render partial: "language_block", locals: {language: language}
  end

  def new
    @language = Language.new
  end

  def edit
    lang_name = Product.decode_language(params[:id])
    @language = Language.where(name: lang_name).first
  end

  def create
    new_lang = Language.new(params[:language])
    new_lang[:param_name] = Product.encode_language(new_lang[:name])

    if new_lang.save
      flash[:success] = "Language is added successfully."
      redirect_to admin_language_index_path
    else
      flash[:error] = "Cant save language: #{new_lang.errors.full_messages.to_sentence}"
      redirect_to :back
    end
  end

  def update
    updated_language = params[:language]
    old_language = Language.where(name: updated_language[:name]).first
    old_language.update_attributes!(updated_language)
    if old_language.save
      flash[:success] = "Language is now updated."
      redirect_to admin_language_path
    else
      flash[:error] = "Cant save updates."
      redirect_to :back
    end
  end
  
  private

  def admin_user
    redirect_to(root_path) unless signed_in_admin?
  end

end
