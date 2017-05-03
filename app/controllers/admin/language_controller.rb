class Admin::LanguageController < ApplicationController

  # before_action :admin_user

  def index
    @languages = Language.all.desc(:updated_at)
  end

  def show
    language = Language.where(param_name: params[:id]).first
    render partial: 'language_block', locals: {language: language}
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

    if new_lang.save
      flash[:success] = 'Language is added successfully.'
      redirect_to admin_language_index_path
    else
      flash[:error] = "Can not save language: #{new_lang.errors.full_messages.to_sentence}"
      redirect_to :back
    end
  end

  def update
    updated_language = params[:language]
    old_language = Language.where(name: updated_language[:name]).first
    old_language.update_attributes!(updated_language)
    if old_language.save
      flash[:success] = 'Language is now updated.'
      redirect_to admin_language_index_path
    else
      flash[:error] = "Can't save updates."
      redirect_to :back
    end
  end

  def destroy
    lang = Language.by_language(params[:id]).shift
    if lang.nil?
      flash[:error] = "Failure: can't delete language `#{params[:id]}`."
    else
      lang.remove
      flash[:success] = "Success: #{lang[:name]} is now removed."
    end

    redirect_to :back
  end

  def upload_json
    docs = JSON::parse(params[:json_file].read)
    docs.each do |doc|
      doc = whitelisted_language_doc_fields(doc)
      next if doc.nil?

      current_doc = Language.by_language(doc['name']).shift
      if current_doc.nil?
        new_doc = Language.new doc
        new_doc.save!
      else
        current_doc.update_attributes(doc)
      end
    end

    flash[:success] = 'Uploaded successfully'
    redirect_to :back
  end

  def download_json
    render json: Language.all.to_json
  end

  private

  def whitelisted_language_doc_fields(doc)
    doc.slice('name', 'description', 'irc', 'irc_url', 'supported_managers',
              'latest_version', 'stable_version', 'licence', 'licence_url',
              'main_url', 'wiki_url', 'repo_url', 'issue_url', 'mailinglist_url',
              'irc_url', 'irc', 'twitter_name')
  end

  def admin_user
    redirect_to(root_path) unless signed_in_admin?
  end

end
