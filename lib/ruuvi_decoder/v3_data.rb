# frozen_string_literal: true

module RuuviDecoder
  # Decoder for V5 formatted data.
  # https://docs.ruuvi.com/communication/bluetooth-advertisements/data-format-5-rawv2
  class V3Data < BaseData
    MANUFACTURER_ID = 0x0499
    DATA_LENGTH_BYTES = 14
    VERSION_TAG = 0x03

    def self.detect(raw_data)
      raw_data.size == DATA_LENGTH_BYTES && raw_data[0] == VERSION_TAG
    end

    def humidity_pct
      return @humidity_pct if defined?(@humidity_pct)

      @humidity_pct = raw_data[1] * 0.5
    end

    def temperature_c
      return @temperature_c if defined?(@temperature_c)

      sign = raw_data[2].nobits?(0x80) ? 1 : -1
      decimal = raw_data[2] & 0x7F
      return @temperature_c = nil if decimal > 127

      fraction = raw_data[3] * 0.01
      return @temperature_c = nil if raw_data[3] > 99

      @temperature_c = sign * (decimal + fraction)
    end

    def pressure_hpa
      return @pressure_hpa if defined?(@pressure_hpa)

      @pressure_hpa = decode_16_bits_unsigned(raw_data[4..5], offset: 50_000, multiplier: 0.01)
    end

    def acceleration_x_g
      return @acceleration_x_g if defined?(@acceleration_x_g)

      @acceleration_x_g = decode_16_bits_signed(raw_data[6..7], multiplier: 0.001)
    end

    def acceleration_y_g
      return @acceleration_y_g if defined?(@acceleration_y_g)

      @acceleration_y_g = decode_16_bits_signed(raw_data[8..9], multiplier: 0.001)
    end

    def acceleration_z_g
      return @acceleration_z_g if defined?(@acceleration_z_g)

      @acceleration_z_g = decode_16_bits_signed(raw_data[10..11], multiplier: 0.001)
    end

    def battery_v
      return @battery_v if defined?(@battery_v)

      @battery_v = decode_16_bits_unsigned(raw_data[12..13], multiplier: 0.001)
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
        >
      INSPECT
    end
  end
end
