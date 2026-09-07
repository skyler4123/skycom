# app/controllers/jobs_controller.rb

class JobsController < ApplicationController
  skip_before_action :authenticate
end
