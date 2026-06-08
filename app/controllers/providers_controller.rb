class ProvidersController < ApplicationController
  before_action :set_provider, only: %i[show clients journal_entries]

  # GET /providers
  def index
    render json: Provider.order(:id)
  end

  # GET /providers/:id
  def show
    render json: @provider
  end

  # GET /providers/:id/clients  (query 1: all clients for a given provider)
  # Includes each client's plan with *this* provider, which lives on the join.
  def clients
    payload = @provider.enrollments.includes(:client).map do |enrollment|
      enrollment.client.as_json(only: %i[id name email]).merge(plan: enrollment.plan)
    end
    render json: payload
  end

  # GET /providers/:id/journal_entries  (query 4: across all of a provider's clients, by date)
  def journal_entries
    entries = @provider.journal_entries.by_recent.includes(:client)
    render json: entries.as_json(
      only: %i[id body created_at],
      include: { client: { only: %i[id name] } }
    )
  end

  private

  def set_provider
    @provider = Provider.find(params[:id])
  end
end
