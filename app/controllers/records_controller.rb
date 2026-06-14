require "net/http"

class RecordsController < ApplicationController
  PER_PAGE = 24

  def index
    base = @owner ? @owner.records.includes(:label) : Record.none
    base = base.by_genre(params[:genre]) if params[:genre].present?
    base = base.order(created_at: :desc)

    @genre    = params[:genre]
    @genres   = @owner ? @owner.records.distinct.pluck(:genre).compact.sort : []
    @page     = (params[:page] || 1).to_i
    @records  = base.limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    @has_more = base.count > @page * PER_PAGE
  end

  def show
    @record      = @owner&.records&.find(params[:id])
    @user_record = @owner&.user_records&.find_by(record: @record)

    unless turbo_frame_request?
      @open_record = @record
      base         = @owner ? @owner.records.includes(:label) : Record.none
      @genre       = nil
      @genres      = @owner ? @owner.records.distinct.pluck(:genre).compact.sort : []
      @page        = 1
      @records     = base.order(created_at: :desc).limit(PER_PAGE)
      @has_more    = base.count > PER_PAGE
      render :index
    end
  end

  def new
    authenticate_user!
    @record = Record.new(
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
    )
    @label_name    = params[:label]
    @condition     = "VG+"
    @tracklist_json = params[:tracklist]
  end

  def discogs_lookup
    authenticate_user!

    barcode = params[:barcode].to_s.strip
    catno   = params[:catno].to_s.strip
    return render(json: { error: "invalid_input" }, status: :bad_request) if barcode.blank? && catno.blank?

    token = ENV["DISCOGS_TOKEN"]
    return render(json: { error: "not_configured" }, status: :service_unavailable) if token.blank?

    search_params = { token: token, per_page: 1 }
    search_params[:barcode] = barcode if barcode.present?
    search_params[:catno]   = catno   if catno.present?

    uri = URI("https://api.discogs.com/database/search")
    uri.query = URI.encode_www_form(search_params)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = "VinylRecordsApp/1.0"
      http.request(req)
    end

    data    = JSON.parse(response.body)
    results = data["results"] || []

    return render(json: { error: "not_found" }, status: :not_found) if results.empty?

    result      = results.first
    title_parts = result["title"].to_s.split(" - ", 2)

    render json: {
      discogs_id:      result["id"].to_s,
      artist:          title_parts.first,
      title:           title_parts.last,
      label:           result["label"]&.first,
      year:            result["year"],
      genre:           result["genre"]&.first,
      country:         result["country"],
      cover_image_url: result["cover_image"],
      format:          result["format"]&.first,
      catalog_number:  result["catno"],
      barcode:         barcode.presence || result["barcode"]&.first
    }
  rescue StandardError
    render json: { error: "network_error" }, status: :service_unavailable
  end

  def discogs_tracklist
    authenticate_user!

    discogs_id = params[:discogs_id].to_s.strip
    return render(json: { error: "invalid_id" }, status: :bad_request) if discogs_id.blank?

    token = ENV["DISCOGS_TOKEN"]
    return render(json: { error: "not_configured" }, status: :service_unavailable) if token.blank?

    uri = URI("https://api.discogs.com/releases/#{discogs_id}")
    uri.query = URI.encode_www_form(token: token)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      req = Net::HTTP::Get.new(uri)
      req["User-Agent"] = "VinylRecordsApp/1.0"
      http.request(req)
    end

    data      = JSON.parse(response.body)
    tracklist = (data["tracklist"] || []).each_with_object({}) do |t, sides|
      side = t["position"].to_s.match(/\A([a-z])/i)&.[](1)&.downcase || "a"
      (sides[side] ||= []) << t["title"].to_s
    end

    render json: { tracklist: tracklist }
  rescue StandardError
    render json: { error: "network_error" }, status: :service_unavailable
  end

  def create
    authenticate_user!

    cp = create_record_params

    label = Label.find_or_create_by!(name: cp[:label_name]) if cp[:label_name].present?

    @record = Record.new(
      artist:          cp[:artist],
      title:           cp[:title],
      year:            cp[:year].presence,
      genre:           cp[:genre].presence,
      country:         cp[:country].presence,
      format:          cp[:format].presence,
      catalog_number:  cp[:catalog_number].presence,
      barcode:         cp[:barcode].presence,
      cover_image_url: cp[:cover_image_url].presence,
      discogs_id:      cp[:discogs_id].presence,
      tracklist:       cp[:tracklist].present? ? JSON.parse(cp[:tracklist]) : nil,
      label:           label
    )

    if @record.save
      @user_record = current_user.user_records.create!(
        record:    @record,
        condition: cp[:condition].presence,
        added_at:  Time.current
      )
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
      @label_name = cp[:label_name]
      @condition  = cp[:condition]
      render :new, status: :unprocessable_entity
    end
  end

  private

  def create_record_params
    params.require(:record).permit(
      :artist, :title, :year, :genre, :country, :format,
      :catalog_number, :barcode, :cover_image_url, :discogs_id,
      :tracklist, :label_name, :condition
    )
  end
end
