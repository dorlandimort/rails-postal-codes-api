class PostalCodesController < ApplicationController

  def index
    render json: PostalCodeService.fetch_codes(params[:postal_code])
  end

  def show
    render json: PostalCodeService.fetch_locations(params[:postal_code])
  end

end
