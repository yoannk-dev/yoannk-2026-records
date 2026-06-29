class RecordsController < ApplicationController
  before_action :authenticate_user!, only: [ :new, :create, :discogs_lookup, :discogs_tracklist ]
  before_action :find_record, only: [ :show ]

  SORT_OPTIONS = %w[artist_asc artist_desc date_asc date_desc].freeze

  def index
    @genre    = params[:genre].presence
    @q        = params[:q].presence
    @sort     = SORT_OPTIONS.include?(params[:sort]) ? params[:sort] : "artist_asc"
    @genres   = owner_genres
    @page     = (params[:page] || 1).to_i
    base         = apply_sort(owner_records.by_genre(@genre).search(@q), @sort)
    @total_count = base.count
    @records     = base.includes(:label).for_page(@page)
    @has_more    = @total_count > @page * Record::PER_PAGE
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
    @genre    = genre
    @q        = nil
    @sort     = "artist_asc"
    @genres   = owner_genres
    @page     = page
    base         = owner_records.by_genre(genre).by_artist
    @total_count = base.count
    @records     = base.includes(:label).for_page(page)
    @has_more    = @total_count > page * Record::PER_PAGE
  end

  def apply_sort(base, sort)
    case sort
    when "artist_desc" then base.order(Arel.sql("LOWER(artist) DESC"))
    when "date_asc"    then base.order("user_records.added_at ASC")
    when "date_desc"   then base.order("user_records.added_at DESC")
    else                    base.order(Arel.sql("LOWER(artist) ASC"))
    end
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
