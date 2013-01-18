require 'test_helper'

class SwaggersControllerTest < ActionController::TestCase
  setup do
    @swagger = swaggers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:swaggers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create swagger" do
    assert_difference('Swagger.count') do
      post :create, swagger: {  }
    end

    assert_redirected_to swagger_path(assigns(:swagger))
  end

  test "should show swagger" do
    get :show, id: @swagger
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @swagger
    assert_response :success
  end

  test "should update swagger" do
    put :update, id: @swagger, swagger: {  }
    assert_redirected_to swagger_path(assigns(:swagger))
  end

  test "should destroy swagger" do
    assert_difference('Swagger.count', -1) do
      delete :destroy, id: @swagger
    end

    assert_redirected_to swaggers_path
  end
end
