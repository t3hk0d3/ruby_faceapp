# Faceapp

Faceapp is neural-network face manipulation application for smartphones.

https://play.google.com/store/apps/details?id=io.faceapp&hl=ru
https://itunes.apple.com/us/app/faceapp-free-neural-face-transformations/id1180884341

This gem provides command-line utility and Ruby library to utilize Faceapp API without using smartphone application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faceapp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faceapp

## Usage

### Commandline utility

```bash
faceapp [options] <filter> <input> [ouput]

  <filter> - Faceapp filter name
    Possible values: smile, smile_2, hot, old, young, female, male

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
```

**Example:**

```bash
$ faceapp female hitler.jpg adolfina.jpg
```

### Ruby library

```ruby
require 'faceapp'

client = Faceapp::Client.new

file = File.open('hitler.jpg', 'rb')
filter = 'female' # smile, smile_2, hot, old, young, male

# File could be String or IO

code = client.upload_photo(file)
# => "2017blablabla"

# By default it will return StringIO
result = client.apply_filter(code, filter)
# => StringIO

output = File.open('output.jpg', 'wb')

# Third argument might be an IO object
result = client.apply_filter(code, filter, output)
# => File

# Or you may specify block, it will receive response chunks
client.apply_filter(code, filter) do |chunk, cursor, total|
    # chunk is String
    puts chunk.bytesize
    # render fancy progress bar
end
# => 100500 # Returns total bytes count

```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

