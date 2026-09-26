require "net/http"
require "openssl"
require "uri"

module RailsRefdocs
  module Http
    ATTEMPTS = 3
    MAX_REDIRECTS = 5
    RETRY_DELAY = 2
    TRANSIENT_ERRORS = [
      IOError, EOFError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError,
      Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Errno::EHOSTUNREACH
    ].freeze

    class Failure < Error; end
    class Transient < Failure; end

    module_function

    def get(url)
      body = +""
      request(url) { |response| response.read_body { |chunk| body << chunk } }
      body.force_encoding(Encoding::UTF_8)
    end

    def download(url, path)
      FileUtils.mkdir_p(File.dirname(path))
      request(url) do |response|
        File.open(path, "wb") { |file| response.read_body { |chunk| file.write(chunk) } }
      end
      path
    end

    def request(url, &block)
      attempt = 0
      begin
        attempt += 1
        follow(URI(url), MAX_REDIRECTS, &block)
      rescue Transient, *TRANSIENT_ERRORS => e
        raise Failure, "GET #{url}: #{e.message}" if attempt >= ATTEMPTS
        sleep RETRY_DELAY
        retry
      end
    end

    def follow(uri, redirects, &block)
      location = nil
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 30, read_timeout: 300) do |http|
        http.request(Net::HTTP::Get.new(uri, "User-Agent" => "rails-refdocs/#{VERSION}")) do |response|
          case response
          when Net::HTTPSuccess then yield response
          when Net::HTTPRedirection then location = URI.join(uri, response["location"])
          when Net::HTTPTooManyRequests, Net::HTTPServerError then raise Transient, "HTTP #{response.code}"
          else raise Failure, "GET #{uri}: HTTP #{response.code}"
          end
        end
      end
      return unless location
      raise Failure, "GET #{uri}: too many redirects" if redirects.zero?
      follow(location, redirects - 1, &block)
    end
  end
end
