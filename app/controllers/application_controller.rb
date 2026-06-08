class ApplicationController < ActionController::API
  # Return a clean JSON 404 instead of an unhandled exception when an :id is bad.
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found(error)
    render json: { error: error.message }, status: :not_found
  end
end
