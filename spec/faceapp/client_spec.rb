require 'spec_helper'

describe Faceapp::Client do
  subject { described_class.new(options) }

  let(:options) do
    { device_id: 'latifwch' }
  end

  describe '#upload_photo' do
    let(:test_photo_path) { File.expand_path('../../support/hitler.jpg', __FILE__) }

    context 'success', vcr: { cassette_name: 'upload_photo_success' } do
      let(:result) do
        File.open(test_photo_path, 'rb') do |file|
          subject.upload_photo(file)
        end
      end

      it 'returns result code' do
        expect(result).to match(/[0-9a-zA-Z]{18}/)
      end
    end

    context 'error', vcr: { cassette_name: 'upload_photo_error' } do
      let(:result) do
        subject.upload_photo(StringIO.new('foobar'))
      end

      it 'raise Faceapp::RequestError exception' do
        expect { result }.to raise_error(
          Faceapp::RequestError,
          '(photo_bad_type) Photo payload is not an image'
        )
      end
    end
  end

  describe '#apply_filter' do
    let(:code) { '20170417145829yocc' }
    let(:filter) { 'female' }

    context 'success', vcr: { cassette_name: 'apply_filter_success' } do
      context 'no specified IO' do
        it 'returns String IO' do
          result = subject.apply_filter(code, filter)
          expect(result).to be_kind_of(StringIO) &
                            have_attributes(length: 10174, pos: 0)
        end
      end

      context 'specified IO' do
        it 'fill specified IO and return it' do
          io = StringIO.new
          expect(subject.apply_filter(code, filter, io)).to be_kind_of(StringIO)
          expect(io).to have_attributes(length: 10174, pos: 10174)
        end
      end

      context 'block' do
        it 'calls specified block for each chunk and return size' do
          # block is called only once because of VCR
          expect do |b|
            subject.apply_filter(code, filter, &b)
          end.to yield_with_args(
            be_kind_of(String) & have_attributes(length: 10174), # current chunk
            Fixnum, # cursor
            10174 # total size
          )
        end
      end
    end

    context 'bad code', vcr: { cassette_name: 'apply_filter_badcode' } do
      let(:code) { 'foobar' }

      it 'raise Faceapp::RequestError exception' do
        expect { subject.apply_filter(code, filter) }.to raise_error(
          Faceapp::RequestError, "Specified photo code (#{code}) not found"
        )
      end
    end

    context 'bad filter', vcr: { cassette_name: 'apply_filter_badfilter' } do
      let(:filter) { 'foobar' }

      it 'raise Faceapp::RequestError exception' do
        expect { subject.apply_filter(code, filter) }.to raise_error(
          Faceapp::RequestError, 'bad_filter_id'
        )
      end
    end

    context 'error', vcr: { cassette_name: 'apply_filter_error' } do
    end
  end
end
