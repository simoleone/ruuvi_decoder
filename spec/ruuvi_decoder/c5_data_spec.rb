# frozen_string_literal: true

require 'spec_helper'

#  test vectors from
#  https://github.com/ruuvi/ruuvi.endpoints.c/blob/f56e6eb048b28a4798afefab01298b17a13e0800/test/test_ruuvi_endpoint_c5.c
RSpec.describe RuuviDecoder::C5Data do
  subject { described_class.new(value) }

  context 'with valid test vector' do
    let(:value) do
      [0xC5, 0x12, 0xFC, 0x53, 0x94, 0xC3, 0x7C,
       0xAC, 0x36, 0x42,
       0x00, 0xCD, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F]
    end

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::C5Data
           temperature: 24.3 C,
           humidity: 53.49 %,
           pressure: 1000.44 hPa,
           battery: 2.977 V,
           tx_power: 4 dBm,
           movement_counter: 66,
           sequence_number: 205,
           mac_address: cb:b8:33:4c:88:4f
        >
      SNAP
    end
  end

  context 'with max values test vector' do
    let(:value) do
      [0xC5, 0x7F, 0xFF, 0xFF, 0xFE, 0xFF, 0xFE,
       0xFF, 0xDE, 0xFE,
       0xFF, 0xFE, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F]
    end

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::C5Data
           temperature: 163.835 C,
           humidity: 163.835 %,
           pressure: 1155.34 hPa,
           battery: 3.646 V,
           tx_power: 20 dBm,
           movement_counter: 254,
           sequence_number: 65534,
           mac_address: cb:b8:33:4c:88:4f
        >
      SNAP
    end
  end

  context 'with min values test vector' do
    let(:value) do
      [
        0xC5, 0x80, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00,
        0x00, 0x00, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F
      ]
    end

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::C5Data
           temperature: -163.835 C,
           humidity: 0.0 %,
           pressure: 500.0 hPa,
           battery: 1.6 V,
           tx_power: -40 dBm,
           movement_counter: 0,
           sequence_number: 0,
           mac_address: cb:b8:33:4c:88:4f
        >
      SNAP
    end
  end

  context 'with invalid values test vector', :aggregate_failures do
    let(:value) do
      [
        0xC5, 0x80, 0x00, 0xFF, 0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF,
        0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
      ]
    end

    it do
      expect(subject.temperature_c).to be_nil
      expect(subject.humidity_pct).to be_nil
      expect(subject.pressure_hpa).to be_nil
      expect(subject.battery_v).to be_nil
      expect(subject.tx_power_dbm).to be_nil
      expect(subject.movement_counter).to be_nil
      expect(subject.sequence_number).to be_nil
      expect(subject.mac_address).to be_nil
    end
  end
end
