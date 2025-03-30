# frozen_string_literal: true

require 'openssl'

module RuuviDecoder
  # Decoder for V8 formatted encrypted data. (DRAFT specification subject to change!)
  # https://docs.ruuvi.com/communication/bluetooth-advertisements/data-format-8-encrypted-environmental
  class V8Data < BaseData
    MANUFACTURER_ID = 0x0499
    DATA_LENGTH_BYTES = 24
    VERSION_TAG = 0x08
    # https://github.com/ruuvi/ruuvi.endpoints.c/blob/master/src/ruuvi_endpoints.c#L8
    CRC8_TABLE = [ # rubocop:disable Metrics/CollectionLiteralLength
      0x00, 0x07, 0x0E, 0x09, 0x1C, 0x1B, 0x12, 0x15,
      0x38, 0x3F, 0x36, 0x31, 0x24, 0x23, 0x2A, 0x2D,
      0x70, 0x77, 0x7E, 0x79, 0x6C, 0x6B, 0x62, 0x65,
      0x48, 0x4F, 0x46, 0x41, 0x54, 0x53, 0x5A, 0x5D,
      0xE0, 0xE7, 0xEE, 0xE9, 0xFC, 0xFB, 0xF2, 0xF5,
      0xD8, 0xDF, 0xD6, 0xD1, 0xC4, 0xC3, 0xCA, 0xCD,
      0x90, 0x97, 0x9E, 0x99, 0x8C, 0x8B, 0x82, 0x85,
      0xA8, 0xAF, 0xA6, 0xA1, 0xB4, 0xB3, 0xBA, 0xBD,
      0xC7, 0xC0, 0xC9, 0xCE, 0xDB, 0xDC, 0xD5, 0xD2,
      0xFF, 0xF8, 0xF1, 0xF6, 0xE3, 0xE4, 0xED, 0xEA,
      0xB7, 0xB0, 0xB9, 0xBE, 0xAB, 0xAC, 0xA5, 0xA2,
      0x8F, 0x88, 0x81, 0x86, 0x93, 0x94, 0x9D, 0x9A,
      0x27, 0x20, 0x29, 0x2E, 0x3B, 0x3C, 0x35, 0x32,
      0x1F, 0x18, 0x11, 0x16, 0x03, 0x04, 0x0D, 0x0A,
      0x57, 0x50, 0x59, 0x5E, 0x4B, 0x4C, 0x45, 0x42,
      0x6F, 0x68, 0x61, 0x66, 0x73, 0x74, 0x7D, 0x7A,
      0x89, 0x8E, 0x87, 0x80, 0x95, 0x92, 0x9B, 0x9C,
      0xB1, 0xB6, 0xBF, 0xB8, 0xAD, 0xAA, 0xA3, 0xA4,
      0xF9, 0xFE, 0xF7, 0xF0, 0xE5, 0xE2, 0xEB, 0xEC,
      0xC1, 0xC6, 0xCF, 0xC8, 0xDD, 0xDA, 0xD3, 0xD4,
      0x69, 0x6E, 0x67, 0x60, 0x75, 0x72, 0x7B, 0x7C,
      0x51, 0x56, 0x5F, 0x58, 0x4D, 0x4A, 0x43, 0x44,
      0x19, 0x1E, 0x17, 0x10, 0x05, 0x02, 0x0B, 0x0C,
      0x21, 0x26, 0x2F, 0x28, 0x3D, 0x3A, 0x33, 0x34,
      0x4E, 0x49, 0x40, 0x47, 0x52, 0x55, 0x5C, 0x5B,
      0x76, 0x71, 0x78, 0x7F, 0x6A, 0x6D, 0x64, 0x63,
      0x3E, 0x39, 0x30, 0x37, 0x22, 0x25, 0x2C, 0x2B,
      0x06, 0x01, 0x08, 0x0F, 0x1A, 0x1D, 0x14, 0x13,
      0xAE, 0xA9, 0xA0, 0xA7, 0xB2, 0xB5, 0xBC, 0xBB,
      0x96, 0x91, 0x98, 0x9F, 0x8A, 0x8D, 0x84, 0x83,
      0xDE, 0xD9, 0xD0, 0xD7, 0xC2, 0xC5, 0xCC, 0xCB,
      0xE6, 0xE1, 0xE8, 0xEF, 0xFA, 0xFD, 0xF4, 0xF3
    ].freeze

    def initialize(raw_data, ruuvi_tag_id, password)
      super(raw_data)

      @ruuvi_tag_id = RuuviDecoder.normalize_raw_data(ruuvi_tag_id)
      @password = case password
                  when String
                    password.bytes
                  when Enumerable
                    password
                  else
                    raise 'password must be a String or Enumerable of bytes'
                  end

      raise ArgumentError, 'ruuvi_tag_id must be 8 bytes' if @ruuvi_tag_id.size != 8
      # fixed 16 byte key size is a quirk
      # https://github.com/ruuvi/ruuvi.firmware.c/blob/f5e159e82d150f76988a41acf39f9d2699debc85/src/app_dataformats.c#L34
      raise ArgumentError, 'password must be at least 8 bytes' if @password.size != 16
    end

    def self.detect(raw_data)
      raw_data.size == DATA_LENGTH_BYTES && raw_data[0] == VERSION_TAG
    end

    def temperature_c
      return @temperature_c if defined?(@temperature_c)

      @temperature_c = decode_16_bits_signed(decrypted_raw_data[0..1], multiplier: 0.005, invalid: 0x8000)
    end

    def humidity_pct
      return @humidity_pct if defined?(@humidity_pct)

      @humidity_pct = decode_16_bits_unsigned(decrypted_raw_data[2..3], multiplier: 0.0025, invalid: 65_535)
    end

    def pressure_hpa
      return @pressure_hpa if defined?(@pressure_hpa)

      @pressure_hpa = decode_16_bits_unsigned(decrypted_raw_data[4..5], offset: 50_000, invalid: 65_535,
                                                                        multiplier: 0.01)
    end

    def tx_power_dbm
      return @tx_power_dbm if defined?(@tx_power_dbm)

      @tx_power_dbm = decode_bitmasked_unsigned(raw_power_info, 0x001F, offset: -20, multiplier: 2, invalid: 31)
    end

    def battery_v
      return @battery_v if defined?(@battery_v)

      @battery_v = decode_bitmasked_unsigned(raw_power_info >> 5, 0x07FF, offset: 1600, multiplier: 0.001,
                                                                          invalid: 2047)
    end

    def movement_counter
      return @movement_counter if defined?(@movement_counter)

      @movement_counter = decode_16_bits_unsigned(decrypted_raw_data[8..9], invalid: 65_535)
    end

    def sequence_number
      return @sequence_number if defined?(@sequence_number)

      @sequence_number = decode_16_bits_unsigned(decrypted_raw_data[10..11], invalid: 65_535)
    end

    def mac_address
      return @mac_address if defined?(@mac_address)

      @mac_address =
        begin
          bytes = raw_data[18..24]
          if bytes.all?(0xff)
            nil
          else
            bytes.map { |b| format('%02x', b) }.join(':')
          end
        end
    end

    def inspect
      <<~INSPECT.chomp
        <#{self.class.name}
           temperature: #{temperature_c} C,
           humidity: #{humidity_pct} %,
           pressure: #{pressure_hpa} hPa,
           battery: #{battery_v} V,
           tx_power: #{tx_power_dbm} dBm,
           movement_counter: #{movement_counter},
           sequence_number: #{sequence_number},
           mac_address: #{mac_address}
        >
      INSPECT
    end

    private

    def aes_key
      return @aes_key if defined?(@aes_key)

      aes_key = @password.dup
      (0...8).each do |idx|
        aes_key[idx] = aes_key[idx] ^ @ruuvi_tag_id[idx]
      end
      @aes_key = aes_key.pack('C*')
    end

    def decrypted_raw_data
      return @decrypted_raw_data if defined?(@decrypted_raw_data)

      cipher = OpenSSL::Cipher.new('AES-128-ECB').decrypt
      cipher.key = aes_key
      cipher.padding = 0 # disable padding
      @decrypted_raw_data = cipher.update(raw_data[1..16].pack('C*'))
      @decrypted_raw_data << cipher.final
      @decrypted_raw_data = @decrypted_raw_data.bytes
      check_crc8!
      @decrypted_raw_data
    end

    def check_crc8!
      crc = @decrypted_raw_data.reduce(0x00) { |crc, byte| CRC8_TABLE[crc ^ byte] }
      raise 'calculated CRC-8 does not match.' if crc != raw_data[17]
    end

    def raw_power_info
      @raw_power_info = decode_16_bits_unsigned(decrypted_raw_data[6..7])
    end
  end
end
