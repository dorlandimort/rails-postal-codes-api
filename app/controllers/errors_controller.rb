class ErrorsController < ApplicationController
  include Response

  def not_found
    json_response( { message: 'invalid route' }, :bad_request)
  end

  def internal_server_error
    json_response( { message: 'internal_server_error' }, :internal_server_error)
  end
end
