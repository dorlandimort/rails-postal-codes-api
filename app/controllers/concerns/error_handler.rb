module ErrorHandler
  #provides the more graceful 'included' method
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::RoutingError do |e|
      json_response( { message: e.message }, :not_found)
    end
  end
end