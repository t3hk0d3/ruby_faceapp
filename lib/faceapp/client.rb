require 'uri'
require 'json'
require 'openssl'
require 'net/http'
require 'net/http/post/multipart'

module Faceapp
  class Client
    DEFAULT_API_HOST = 'https://node-01.faceapp.io'.freeze
    DEFAULT_USER_AGENT = 'FaceApp/1.0.229 (Linux; Android 4.4)'.freeze

    DEVICE_ID_LENGTH = 8
    DEVICE_ID_LETTERS = ('a'..'z').to_a.freeze

    KNOWN_FACEAPP_ERRORS = {
      'bad_filter_id' => 'Unknown filter'
    }.freeze

    attr_reader :options

    def initialize(options = {})
      @options = options

      options[:api_host]    ||= DEFAULT_API_HOST
      options[:user_agent]  ||= DEFAULT_USER_AGENT
      options[:device_id]   ||= generate_device_id

      options[:headers] = {
        'User-Agent' => options[:user_agent],
        'X-FaceApp-DeviceID' => options[:device_id]
      }.merge!(options[:headers] || {})
    end

    def upload_photo(photo)
      photo_io = UploadIO.new(photo, 'image/jpeg', 'image.jpg')

      request =
        Net::HTTP::Post::Multipart.new '/api/v2.3/photos',
                                       { 'file' => photo_io },
                                       options[:headers]

      response = http.request(request)

      body = JSON.parse(response.body)

      unless response.is_a?(Net::HTTPSuccess)
        if body.is_a?(Hash) && body['err']
          error = body['err']

          error_message = "(#{error['code']}) #{error['desc']}"
        else
          error_message = response.body.to_s
        end

        raise Faceapp::RequestError, error_message
      end

      body['code']
    end

    def apply_filter(photo_code, filter, io = nil, &block)
      cropped = options.fetch(:cropped, true) ? "true" : "false"

      url = "/api/v2.3/photos/#{photo_code}/filters/#{filter}?cropped=#{cropped}"

      request = Net::HTTP::Get.new(url, options[:headers])

      dest = io ? io : StringIO.new

      http.request(request) do |response|
        unless response.is_a?(Net::HTTPSuccess)
          error_code =
            if response['x-faceapp-errorcode']
              response['x-faceapp-errorcode']
            elsif response.code == '404'
              'bad_photo_code'
            else
              'unknown_error'
            end

          error_message = KNOWN_FACEAPP_ERRORS.fetch(error_code, error_code)
          error_message = format(error_message, photo_code, filter)

          raise Faceapp::RequestError, error_message
        end

        dest = handler_filter_response(response, dest, &block)
      end

      dest.rewind if !io && !block_given?

      dest
    end

    private

    def http
      @http ||= begin
        uri = URI.parse(options[:api_host])

        http = Net::HTTP.new(uri.hostname, uri.port)

        http.set_debug_output(options[:logger]) if options[:logger]

        if uri.scheme == 'https'
          http.use_ssl = { verify_mode: OpenSSL::SSL::VERIFY_PEER }
        end

        http
      end
    end

    def handler_filter_response(response, dest)
      if block_given?
        cursor = 0
        total = response.content_length

        response.read_body do |chunk|
          yield chunk, cursor, total
          cursor += chunk.size
        end

        total # return total size
      else
        response.read_body(dest)

        dest
      end
    end

    def generate_device_id(length = DEVICE_ID_LENGTH)
      Array.new(length) { DEVICE_ID_LETTERS.sample }.join
    end
  end
end
