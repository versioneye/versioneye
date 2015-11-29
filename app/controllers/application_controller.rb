class ApplicationController < ActionController::Base

  protect_from_forgery

  include SessionsHelper
  include ProductsHelper
  include UsersHelper
  include ProjectsHelper
  include RefersHelper
  include PlanHelper
  include OrganisationHelper

end
