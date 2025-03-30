# frozen_string_literal: true

require 'spec_helper'

# test vectors from
# https://github.com/ruuvi/ruuvi.endpoints.c/blob/f56e6eb048b28a4798afefab01298b17a13e0800/test/test_ruuvi_endpoint_3.c
RSpec.describe RuuviDecoder::V3Data do
  subject { described_class.new(value) }

  context 'with valid test vector' do
    let(:value) { [0x03, 0x29, 0x1A, 0x1E, 0xCE, 0x1E, 0xFC, 0x18, 0xF9, 0x42, 0x02, 0xCA, 0x0B, 0x53] }

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::V3Data
           temperature: 26.3 C,
           humidity: 20.5 %,
           pressure: 1027.66 hPa,
           acceleration_x: -1.0 G,
           acceleration_y: -1.726 G,
           acceleration_z: 0.714 G,
           battery: 2.899 V,
        >
      SNAP
    end
  end

  context 'with max values test vector' do
    let(:value) { [0x03, 0xFF, 0x7F, 0x63, 0xFF, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0x7F, 0xFF, 0xFF, 0xFF] }

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::V3Data
           temperature: 127.99 C,
           humidity: 127.5 %,
           pressure: 1155.3500000000001 hPa,
           acceleration_x: 32.767 G,
           acceleration_y: 32.767 G,
           acceleration_z: 32.767 G,
           battery: 65.535 V,
        >
      SNAP
    end
  end

  context 'with min values test vector' do
    let(:value) { [0x03, 0x00, 0xFF, 0x63, 0x00, 0x00, 0x80, 0x01, 0x80, 0x01, 0x80, 0x01, 0x00, 0x00] }

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::V3Data
           temperature: -127.99 C,
           humidity: 0.0 %,
           pressure: 500.0 hPa,
           acceleration_x: -32.767 G,
           acceleration_y: -32.767 G,
           acceleration_z: -32.767 G,
           battery: 0.0 V,
        >
      SNAP
    end
  end
end
