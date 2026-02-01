class Retail::Management::SubscriptionsController < Retail::Management::ApplicationController
  def index
    respond_to do |format|
      format.html { render html: "", layout: true }
      format.json do
        @subscriptions = @retail.cached_subscriptions
        render json: { subscriptions: @subscriptions }
      end
    end
  end
end
