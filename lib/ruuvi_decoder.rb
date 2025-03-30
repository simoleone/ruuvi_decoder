# frozen_string_literal: true

require_relative 'ruuvi_decoder/version'
require_relative 'ruuvi_decoder/base_data'
require_relative 'ruuvi_decoder/c5_data'
require_relative 'ruuvi_decoder/v5_data'
require_relative 'ruuvi_decoder/v8_data'

# Decoders for various binary data formats emitted by Ruuvi bluetooth sensors.
# Use classes directly or the static decode method to automatically select one based
# on the version tag.
module RuuviDecoder
  def self.decode(raw_data)
    raw_data = normalize_raw_data(raw_data)

    # TODO(simo): implement more formats :)
    decoder_class = [
      V5Data,
      C5Data,
      V8Data
    ].find { |data_format| data_format.detect(raw_data) }
    raise 'no decoder found' if decoder_class.nil?

    raise 'instantiate V8Data directly, with tag id and password' if decoder_class == V8Data

    decoder_class.new(raw_data)
  end

  def self.normalize_raw_data(raw_data)
    case raw_data
    when Enumerable
      raw_data
    when String
      unless raw_data.encoding == Encoding::ASCII_8BIT
        raise ArgumentError,
              'raw_data must ASCII_8BIT (binary) encoded'
      end

      raw_data.bytes
    else
      raise ArgumentError, "raw_data must be an Enumerable of bytes or a binary-encoded String, got #{raw_data.class}"
    end
  end
end
