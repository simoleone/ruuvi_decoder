# frozen_string_literal: true

module RuuviDecoder
  # Decoder for V5 formatted data.
  # https://docs.ruuvi.com/communication/bluetooth-advertisements/data-format-5-rawv2
  class V5Data < BaseData
    MANUFACTURER_ID = 0x0499
    DATA_LENGTH_BYTES = 24
    VERSION_TAG = 0x05

    def self.detect(raw_data)
      raw_data.size == DATA_LENGTH_BYTES && raw_data[0] == VERSION_TAG
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

    def sequence_number
      return @sequence_number if defined?(@sequence_number)

      @sequence_number = decode_16_bits_unsigned(raw_data[16..17], multiplier: 1, invalid: 65_535)
    end

    def movement_counter
      return @movement_counter if defined?(@movement_counter)

      @movement_counter = decode_16_bits_unsigned([0, raw_data[15]], multiplier: 1, invalid: 255)
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

    def acceleration_x_g
      return @acceleration_x_g if defined?(@acceleration_x_g)

      @acceleration_x_g = decode_16_bits_signed(raw_data[7..8], invalid: 0x8000, multiplier: 0.001)
    end

    def acceleration_y_g
      return @acceleration_y_g if defined?(@acceleration_y_g)

      @acceleration_y_g = decode_16_bits_signed(raw_data[9..10], invalid: 0x8000, multiplier: 0.001)
    end

    def acceleration_z_g
      return @acceleration_z_g if defined?(@acceleration_z_g)

      @acceleration_z_g = decode_16_bits_signed(raw_data[11..12], invalid: 0x8000, multiplier: 0.001)
    end

    def pressure_hpa
      return @pressure_hpa if defined?(@pressure_hpa)

      @pressure_hpa = decode_16_bits_unsigned(raw_data[5..6], offset: 50_000, invalid: 65_535, multiplier: 0.01)
    end

    def humidity_pct
      return @humidity_pct if defined?(@humidity_pct)

      @humidity_pct = decode_16_bits_unsigned(raw_data[3..4], multiplier: 0.0025, invalid: 65_535)
    end

    def temperature_c
      return @temperature_c if defined?(@temperature_c)

      @temperature_c = decode_16_bits_signed(raw_data[1..2], multiplier: 0.005, invalid: 0x8000)
    end

    def inspect
      <<~INSPECT.chomp
        <#{self.class.name}
           temperature: #{temperature_c} C,
           humidity: #{humidity_pct} %,
           pressure: #{pressure_hpa} hPa,
           acceleration_x: #{acceleration_x_g} G,
           acceleration_y: #{acceleration_y_g} G,
           acceleration_z: #{acceleration_z_g} G,
           battery: #{battery_v} V,
           tx_power: #{tx_power_dbm} dBm,
           movement_counter: #{movement_counter},
           sequence_number: #{sequence_number},
           mac_address: #{mac_address}
        >
      INSPECT
    end

    private

    def raw_power_info
      @raw_power_info = decode_16_bits_unsigned(raw_data[13..14])
    end
  end
end
