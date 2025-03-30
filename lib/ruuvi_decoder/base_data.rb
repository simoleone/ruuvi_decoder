# frozen_string_literal: true

module RuuviDecoder
  # Abstract base class for decoders.
  class BaseData
    def initialize(raw_data)
      @raw_data = RuuviDecoder.normalize_raw_data(raw_data)

      raise ArgumentError, 'data is not valid for this format' unless self.class.detect(@raw_data)
    end

    def self.detect(_raw_data)
      raise 'subclass must implement this method'
    end

    protected

    attr_reader :raw_data

    def decode_16_bits_signed(bytes, multiplier: 1, invalid: nil, offset: 0)
      return if !invalid.nil? && bytes == [invalid].pack('s>').bytes

      signed_int = bytes.pack('C*').unpack1('s>')
      (signed_int + offset) * multiplier
    end

    def decode_16_bits_unsigned(bytes, multiplier: 1, invalid: nil, offset: 0)
      return if !invalid.nil? && bytes == [invalid].pack('S>').bytes

      signed_int = bytes.pack('C*').unpack1('S>')
      (signed_int + offset) * multiplier
    end

    def decode_bitmasked_unsigned(value, mask, multiplier: 1, invalid: nil, offset: 0)
      value &= mask
      return if !invalid.nil? && value == invalid

      (value + offset) * multiplier
    end
  end
end
