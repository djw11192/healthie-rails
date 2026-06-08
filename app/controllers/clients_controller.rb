# frozen_string_literal: true

class ClientsController < ApplicationController
  before_action :set_client, only: %i[show providers]

  # GET /clients?limit=50&offset=0
  def index
    limit  = params.fetch(:limit,  50).to_i.clamp(1, 100)
    offset = [params.fetch(:offset, 0).to_i, 0].max
    render json: Client.order(:created_at).limit(limit).offset(offset)
  end

  # GET /clients/:id
  def show
    render json: @client
  end

  # GET /clients/:id/providers  (query 2: all providers for a given client)
  # Includes the plan the client has with each provider (lives on the join).
  def providers
    payload = @client.enrollments.includes(:provider).map do |enrollment|
      enrollment.provider.as_json(only: %i[id name email]).merge(plan: enrollment.plan)
    end
    render json: payload
  end

  private

  def set_client
    @client = Client.find(params[:id])
  end
end
