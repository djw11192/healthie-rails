# frozen_string_literal: true

class ProvidersController < ApplicationController
  before_action :set_provider, only: %i[show clients journal_entries]

  # GET /providers?limit=50&offset=0
  def index
    limit  = params.fetch(:limit,  50).to_i.clamp(1, 100)
    offset = [params.fetch(:offset, 0).to_i, 0].max
    render json: Provider.order(:created_at).limit(limit).offset(offset)
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
    limit   = params.fetch(:limit, 25).to_i.clamp(1, 100)
    entries = @provider.journal_entries.by_recent.limit(limit).includes(:client)
    render json: entries.as_json(
      only: %i[id body recorded_at],
      include: { client: { only: %i[id name] } }
    )
  end

  private

  def set_provider
    @provider = Provider.find(params[:id])
  end
end
