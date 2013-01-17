class SwaggersController < ApplicationController
  # GET /swaggers
  # GET /swaggers.json
  def index
    @swaggers = Swagger.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @swaggers }
    end
  end

  # GET /swaggers/1
  # GET /swaggers/1.json
  def show
    @swagger = Swagger.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @swagger }
    end
  end

  # GET /swaggers/new
  # GET /swaggers/new.json
  def new
    @swagger = Swagger.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @swagger }
    end
  end

  # GET /swaggers/1/edit
  def edit
    @swagger = Swagger.find(params[:id])
  end

  # POST /swaggers
  # POST /swaggers.json
  def create
    @swagger = Swagger.new(params[:swagger])

    respond_to do |format|
      if @swagger.save
        format.html { redirect_to @swagger, notice: 'Swagger was successfully created.' }
        format.json { render json: @swagger, status: :created, location: @swagger }
      else
        format.html { render action: "new" }
        format.json { render json: @swagger.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /swaggers/1
  # PUT /swaggers/1.json
  def update
    @swagger = Swagger.find(params[:id])

    respond_to do |format|
      if @swagger.update_attributes(params[:swagger])
        format.html { redirect_to @swagger, notice: 'Swagger was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @swagger.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /swaggers/1
  # DELETE /swaggers/1.json
  def destroy
    @swagger = Swagger.find(params[:id])
    @swagger.destroy

    respond_to do |format|
      format.html { redirect_to swaggers_url }
      format.json { head :no_content }
    end
  end
end
