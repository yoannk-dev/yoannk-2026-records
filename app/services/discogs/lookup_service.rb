class Discogs::LookupService < Discogs::BaseService
  def initialize(barcode:, catno:)
    @barcode = barcode.to_s.strip
    @catno   = catno.to_s.strip
  end

  def call
    return failure("invalid_input", :bad_request)        if @barcode.blank? && @catno.blank?
    return failure("not_configured", :service_unavailable) if token.blank?

    results = fetch_results
    return failure("not_found", :not_found) if results.empty?

    success(format_result(results.first))
  rescue StandardError
    failure("network_error", :service_unavailable)
  end

  private

  def fetch_results
    uri = URI("https://api.discogs.com/database/search")
    uri.query = URI.encode_www_form(search_params)
    JSON.parse(http_get(uri).body)["results"] || []
  end

  def search_params
    { token: token, per_page: 1 }.tap do |p|
      p[:barcode] = @barcode if @barcode.present?
      p[:catno]   = @catno   if @catno.present?
    end
  end

  def format_result(result)
    title_parts = result["title"].to_s.split(" - ", 2)
    {
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
      barcode:         @barcode.presence || result["barcode"]&.first
    }
  end
end
