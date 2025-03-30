# frozen_string_literal: true

require 'rspec'

RSpec.describe RuuviDecoder do
  describe '.decode' do
    subject(:decode) { described_class.decode(value) }

    context 'when v5 data' do
      let(:value) do
        "\x05\x12\xFC\x53\x94\xC3\x7C\x00\x04\xFF\xFC\x04\x0C\xAC\x36\x42\x00\xCD\xCB\xB8\x33\x4C\x88\x4F".b
      end

      it do
        expect(decode).to be_a(RuuviDecoder::V5Data)
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
