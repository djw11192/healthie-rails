# frozen_string_literal: true

class JournalEntriesController < ApplicationController
  before_action :set_client

  # GET /clients/:client_id/journal_entries?limit=25  (query 3: a client's entries, newest first)
  def index
    limit = params.fetch(:limit, 25).to_i.clamp(1, 100)
    render json: @client.journal_entries.by_recent.limit(limit)
                        .as_json(only: %i[id body recorded_at])
  end

  # POST /clients/:client_id/journal_entries
  # Body: { "journal_entry": { "body": "...", "recorded_at": "2026-06-01T09:00:00Z" } }
  # recorded_at is optional; omit it to default to the current time.
  def create
    entry = @client.journal_entries.build(journal_entry_params)

    if entry.save
      render json: entry.as_json(only: %i[id body recorded_at client_id]), status: :created
    else
      render json: { errors: entry.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def journal_entry_params
    params.require(:journal_entry).permit(:body, :recorded_at)
  end
end
