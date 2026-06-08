class ClientsController < ApplicationController
  before_action :set_client, only: %i[show providers]

  # GET /clients
  def index
    render json: Client.order(:id)
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
