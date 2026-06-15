class Discogs::TracklistService < Discogs::BaseService
  def initialize(discogs_id:)
    @discogs_id = discogs_id.to_s.strip
  end

  def call
    return failure("invalid_id", :bad_request)           if @discogs_id.blank?
    return failure("not_configured", :service_unavailable) if token.blank?

    success(tracklist: fetch_tracklist)
  rescue StandardError
    failure("network_error", :service_unavailable)
  end

  private

  def fetch_tracklist
    uri = URI("https://api.discogs.com/releases/#{@discogs_id}")
    uri.query = URI.encode_www_form(token: token)
    data = JSON.parse(http_get(uri).body)

    (data["tracklist"] || []).each_with_object({}) do |t, sides|
      side = t["position"].to_s.match(/\A([a-z])/i)&.[](1)&.downcase || "a"
      (sides[side] ||= []) << t["title"].to_s
    end
  end
end
