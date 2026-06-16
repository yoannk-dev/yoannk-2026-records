class RecordsController < ApplicationController
  before_action :authenticate_user!, only: [ :new, :create, :discogs_lookup, :discogs_tracklist ]
  before_action :find_record, only: [ :show ]

  def index
    @genre    = params[:genre].presence
    @genres   = owner_genres
    @page     = (params[:page] || 1).to_i
    base      = owner_records.by_genre(@genre).by_artist
    @records  = base.includes(:label).for_page(@page)
    @has_more = base.count > @page * Record::PER_PAGE
  end

  def show
    @user_record = @owner.user_records.find_by(record: @record)

    unless turbo_frame_request?
      @open_record = @record
      setup_index(page: 1, genre: nil)
      render :index
    end
  end

  def new
    @record         = Record.new(record_attributes_from_discogs)
    @label_name     = params[:label]
    @condition      = "VG+"
    @tracklist_json = params[:tracklist]
  end

  def discogs_lookup
    result = Discogs::LookupService.new(barcode: params[:barcode], catno: params[:catno]).call

    if result.success?
      render json: result.data
    else
      render json: { error: result.error }, status: result.status
    end
  end

  def discogs_tracklist
    result = Discogs::TracklistService.new(discogs_id: params[:discogs_id]).call

    if result.success?
      render json: result.data
    else
      render json: { error: result.error }, status: result.status
    end
  end

  def create
    result = Records::ImportService.new(current_user, create_record_params).call

    if result.success?
      @record      = result.record
      @user_record = result.user_record
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("records-grid", partial: "records/record", locals: { record: @record }),
            turbo_stream.replace("panel_content", template: "records/show")
          ]
        end
        format.html { redirect_to @record, notice: "Added to your collection." }
      end
    else
      @record     = result.record
      @label_name = create_record_params[:label_name]
      @condition  = create_record_params[:condition]
      render :new, status: :unprocessable_entity
    end
  end

  private

  def find_record
    @record = @owner&.records&.includes(:label)&.find(params[:id]) ||
              raise(ActiveRecord::RecordNotFound)
  end

  def setup_index(page:, genre:)
    base      = owner_records.by_genre(genre).by_artist
    @genre    = genre
    @genres   = owner_genres
    @page     = page
    @records  = base.includes(:label).for_page(page)
    @has_more = base.count > page * Record::PER_PAGE
  end

  def owner_records
    @owner ? @owner.records : Record.none
  end

  def owner_genres
    @owner ? @owner.records.available_genres : []
  end

  def record_attributes_from_discogs
    {
      artist:          params[:artist],
      title:           params[:title],
      year:            params[:year],
      genre:           params[:genre],
      country:         params[:country],
      format:          params[:format],
      catalog_number:  params[:catalog_number],
      barcode:         params[:barcode],
      cover_image_url: params[:cover_image_url],
      discogs_id:      params[:discogs_id],
      tracklist:       params[:tracklist].present? ? JSON.parse(params[:tracklist]) : nil
    }
  end

  def create_record_params
    @create_record_params ||= params.require(:record).permit(
      :artist, :title, :year, :genre, :country, :format,
      :catalog_number, :barcode, :cover_image_url, :discogs_id,
      :tracklist, :label_name, :condition
    )
  end
end
