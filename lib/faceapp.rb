module Faceapp
  require_relative 'faceapp/client'

  KNOWN_FILTERS = %w(smile smile_2 hot old young female male)

  class RequestError < StandardError; end
end
