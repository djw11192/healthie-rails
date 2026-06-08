# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound,  with: :not_found
  # A concurrent duplicate write can slip past model-layer uniqueness validation
  # and be caught only by the DB constraint. Map it to 409 rather than 500.
  rescue_from ActiveRecord::RecordNotUnique, with: :conflict

  private

  def not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def conflict
    render json: { error: "Record already exists" }, status: :conflict
  end
end
