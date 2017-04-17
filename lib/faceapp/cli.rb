require 'logger'
require 'faceapp'

module Faceapp
  class CLI
    attr_reader :params, :options, :debug, :silent

    OPTION_REGEXP = /\A--(?<name>[^=]+)(?:=(?<value>.+))?\Z/

    PARAMS = [:filter, :input, :output].freeze

    def initialize(args)
      @params, @options = parse_arguments(args)
    end

    def run!
      print_usage if params.empty? || options[:help]

      options[:logger] = Logger.new(STDERR) if debug?

      filter = params[:filter]
      input = parse_input(params[:input])
      output = parse_output(params[:output])

      client = Faceapp::Client.new(options)

      code = client.upload_photo(input)

      info "Successfuly uploaded input photo. Result code = #{code}"
      info "Applying filter '#{filter}'"

      client.apply_filter(code, filter, output)

      info 'Done.'
    rescue => e
      info "Error: #{e.message}"

      debug { e.backtrace.join("\n") }

      exit(-1)
    ensure
      input.close if input.is_a?(File)
      output.close if output.is_a?(File)
    end

    def print_usage
      info <<TEXT
faceapp [options] <filter> <input> [ouput]

  <filter> - Faceapp filter name
    Possible values: #{Faceapp::KNOWN_FILTERS.join(', ')}

  <input> - Input file name
    Use '-' for STDIN

  [output] - Optinal, output file name
    Do not specify or use '-' for STDOUT

  Options:
    --help - Display this message
    --cropped[=true|false] - Crop output image to face region. Enabled by default.
    --api_host=<api_host> - Faceapp API host
    --device_id=<device_id> - DeviceId for Faceapp
    --user_agent=<user_agent> - User-Agent header for Faceapp API requests
    --silent - Keep quiet, it will override `debug`
    --debug - Print HTTP requests/responses to STDERR.

TEXT
      exit(-1)
    end

    private

    def parse_input(input)
      case input
      when '-'
        StringIO.new(STDIN.read)
      when nil
        print_usage
      else
        File.open(input, 'rb')
      end
    rescue => e
      info "Unable to open input: #{e.message}"
      exit(-1)
    end

    def parse_output(output)
      case output
      when String
        File.open(output, 'wb')
      else
        STDOUT
      end
    rescue => e
      info "Unable to open output: #{e.message}"
      exit(-1)
    end

    def parse_arguments(args)
      params = []
      options = {}

      args.each do |arg|
        match = OPTION_REGEXP.match(arg)

        if match
          options[match[:name].to_sym] = parse_option(match[:value])
        else
          params << arg
        end
      end

      params = PARAMS.zip(params).to_h

      [params, options]
    end

    def parse_option(value)
      case value
      when String
        value
      when 'false', '0'
        false
      else
        true
      end
    end

    def debug(text = nil)
      return unless debug?

      STDERR.puts(text) if text
      STDERR.puts(yield) if block_given?
    end

    def info(text = nil)
      return if silent?

      STDERR.puts(text) if text
      STDERR.puts(yield) if block_given?
    end

    def debug?
      options[:debug] && !silent?
    end

    def silent?
      options[:silent]
    end
  end
end
