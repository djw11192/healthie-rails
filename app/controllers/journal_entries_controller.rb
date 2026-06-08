class JournalEntriesController < ApplicationController
  before_action :set_client

  # GET /clients/:client_id/journal_entries  (query 3: a client's entries, newest first)
  def index
    render json: @client.journal_entries.by_recent.as_json(only: %i[id body created_at])
  end

  # POST /clients/:client_id/journal_entries
  # Body: { "journal_entry": { "body": "..." } }
  def create
    entry = @client.journal_entries.build(journal_entry_params)

    if entry.save
      render json: entry.as_json(only: %i[id body created_at client_id]), status: :created
    else
      render json: { errors: entry.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def journal_entry_params
    params.require(:journal_entry).permit(:body)
  end
end
