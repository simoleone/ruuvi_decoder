# frozen_string_literal: true

require 'spec_helper'

# test vectors from
# https://github.com/ruuvi/ruuvi.endpoints.c/blob/master/test/test_ruuvi_endpoint_8.c#L93
RSpec.describe RuuviDecoder::V8Data do
  subject { described_class.new(value, tag_id, password) }

  context 'with valid test vector' do
    # This test value was manually created. encryption is entirely stubbed in the firmware code and there
    # are no real test vectors there.
    let(:password) { 'RuuviComRuuviTag' }
    let(:tag_id) { "\xAA\xBB\xCC\xDD\xEE\xFF\x00\x11".b }
    let(:value) do
      [
        0x08,
        0x99, 0xF9, 0xF2, 0x64, 0x02, 0xB8, 0x1F, 0xE8,
        0x82, 0x69, 0x08, 0xCE, 0xD2, 0xC2, 0x67, 0x88,
        0x3F, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F
      ]
    end

    it do
      expect(subject.inspect).to match_inline_snapshot(<<~SNAP.chomp)
        <RuuviDecoder::V8Data
           temperature: 24.3 C,
           humidity: 53.49 %,
           pressure: 1000.44 hPa,
           battery: 2.977 V,
           tx_power: 4 dBm,
           movement_counter: 6607,
           sequence_number: 205,
           mac_address: cb:b8:33:4c:88:4f
        >
      SNAP
    end
  end

  context 'with a CRC check failure' do
    let(:password) { 'RuuviComRuuviTag' }
    let(:tag_id) { "\xAA\xBB\xCC\xDD\xEE\xFF\x00\x11".b }
    let(:value) do
      [
        0x08,
        0x99, 0xF9, 0xF2, 0x64, 0x02, 0xB8, 0x1F, 0xE8,
        0x82, 0x69, 0x08, 0xCE, 0xD2, 0xC2, 0x67, 0x88,
        0xFF, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F
      ]
    end

    it do
      expect { subject.temperature_c }.to raise_error(RuntimeError, 'calculated CRC-8 does not match.')
    end
  end

  context 'with wrong key' do
    let(:password) { 'xxxviComRuuviTag' }
    let(:tag_id) { "\xAA\xBB\xCC\xDD\xEE\xFF\x00\x11".b }
    let(:value) do
      [
        0x08,
        0x99, 0xF9, 0xF2, 0x64, 0x02, 0xB8, 0x1F, 0xE8,
        0x82, 0x69, 0x08, 0xCE, 0xD2, 0xC2, 0x67, 0x88,
        0x3F, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F
      ]
    end

    it do
      # NB: AES ECB mode gives us no good option to detect the wrong key, we rely on the CRC
      expect { subject.temperature_c }.to raise_error(RuntimeError, 'calculated CRC-8 does not match.')
    end
  end

  context 'with wrong tag ID' do
    let(:password) { 'RuuviComRuuviTag' }
    let(:tag_id) { "\xFF\xFF\xCC\xDD\xEE\xFF\x00\x11".b }
    let(:value) do
      [
        0x08,
        0x99, 0xF9, 0xF2, 0x64, 0x02, 0xB8, 0x1F, 0xE8,
        0x82, 0x69, 0x08, 0xCE, 0xD2, 0xC2, 0x67, 0x88,
        0x3F, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F
      ]
    end

    it do
      # NB: AES ECB mode gives us no good option to detect the wrong key, we rely on the CRC
      expect { subject.temperature_c }.to raise_error(RuntimeError, 'calculated CRC-8 does not match.')
    end
  end
end
