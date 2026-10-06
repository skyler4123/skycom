class DemoController < ApplicationController
  skip_before_action :authenticate

  def index
    respond_to do |format|
      # format.html { render html: "", layout: true }
      format.html
      format.json do
        render json: { title: "Demo" }
      end
    end
  end
end
