require "net/http"

module Discogs
  class BaseService
    Result = Struct.new(:success?, :data, :error, :status)

    private

    USER_AGENT = "VinylRecordsApp/1.0"

    def token
      ENV["DISCOGS_TOKEN"]
    end

    def http_get(uri)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
        req = Net::HTTP::Get.new(uri)
        req["User-Agent"] = USER_AGENT
        http.request(req)
      end
    end

    def success(data)
      Result.new(true, data, nil, :ok)
    end

    def failure(error, status)
      Result.new(false, nil, error, status)
    end
  end
end
