# frozen_string_literal: true

require 'rspec'

RSpec.describe RuuviDecoder do
  describe '.decode' do
    subject(:decode) { described_class.decode(value) }

    context 'when v5 data' do
      let(:value) do
        [
          0x05, 0x12, 0xFC, 0x53, 0x94, 0xC3, 0x7C, 0x00,
          0x04, 0xFF, 0xFC, 0x04, 0x0C, 0xAC, 0x36, 0x42,
          0x00, 0xCD, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F
        ]
      end

      it do
        expect(decode).to be_a(RuuviDecoder::V5Data)
      end
    end

    context 'when c5 data' do
      let(:value) do
        [0xC5, 0x12, 0xFC, 0x53, 0x94, 0xC3, 0x7C,
         0xAC, 0x36, 0x42,
         0x00, 0xCD, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F]
      end

      it do
        expect(decode).to be_a(RuuviDecoder::C5Data)
      end
    end

    context 'when v8 data' do
      let(:value) do
        [
          0x08,
          0x99, 0xF9, 0xF2, 0x64, 0x02, 0xB8, 0x1F, 0xE8,
          0x82, 0x69, 0x08, 0xCE, 0xD2, 0xC2, 0x67, 0x88,
          0x3F, 0xCB, 0xB8, 0x33, 0x4C, 0x88, 0x4F
        ]
      end

      it do
        expect { decode }.to raise_error(RuntimeError, 'instantiate V8Data directly, with tag id and password')
      end
    end

    context 'when v3 data' do
      let(:value) { [0x03, 0x29, 0x1A, 0x1E, 0xCE, 0x1E, 0xFC, 0x18, 0xF9, 0x42, 0x02, 0xCA, 0x0B, 0x53] }

      it do
        expect(decode).to be_a(RuuviDecoder::V3Data)
      end
    end

    context 'when unknown data' do
      let(:value) do
        "\x01\x02\03".b
      end

      it do
        expect { decode }.to raise_error(RuntimeError, 'no decoder found')
      end
    end
  end
end
