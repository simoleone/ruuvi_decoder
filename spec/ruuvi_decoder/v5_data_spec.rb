# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RuuviDecoder::V5Data do
  subject { described_class.new([value].pack('H*').bytes) }

  context 'with valid test vector' do
    let(:value) { '0512FC5394C37C0004FFFC040CAC364200CDCBB8334C884F' }

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::V5Data
           temperature: 24.3 C,
           humidity: 53.49 %,
           pressure: 1000.44 hPa,
           acceleration_x: 0.004 G,
           acceleration_y: -0.004 G,
           acceleration_z: 1.036 G,
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
    let(:value) { '057FFFFFFEFFFE7FFF7FFF7FFFFFDEFEFFFECBB8334C884F' }

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::V5Data
           temperature: 163.835 C,
           humidity: 163.835 %,
           pressure: 1155.34 hPa,
           acceleration_x: 32.767 G,
           acceleration_y: 32.767 G,
           acceleration_z: 32.767 G,
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
    let(:value) { '058001000000008001800180010000000000CBB8334C884F' }

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::V5Data
           temperature: -163.835 C,
           humidity: 0.0 %,
           pressure: 500.0 hPa,
           acceleration_x: -32.767 G,
           acceleration_y: -32.767 G,
           acceleration_z: -32.767 G,
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
    let(:value) { '058000FFFFFFFF800080008000FFFFFFFFFFFFFFFFFFFFFF' }

    it do
      expect(subject.temperature_c).to be_nil
      expect(subject.humidity_pct).to be_nil
      expect(subject.pressure_hpa).to be_nil
      expect(subject.acceleration_x_g).to be_nil
      expect(subject.acceleration_y_g).to be_nil
      expect(subject.acceleration_z_g).to be_nil
      expect(subject.battery_v).to be_nil
      expect(subject.tx_power_dbm).to be_nil
      expect(subject.movement_counter).to be_nil
      expect(subject.sequence_number).to be_nil
      expect(subject.mac_address).to be_nil
    end
  end
end
