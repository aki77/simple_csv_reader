# frozen_string_literal: true

require 'tempfile'

RSpec.describe SimpleCsvReader do
  def create_tmp_file(basename, content)
    Tempfile.open(basename) do |tmp|
      tmp.write(content)
      tmp.flush
      tmp
    end
  end

  def create_csv_file(content)
    create_tmp_file(%w[test .csv], content)
  end

  describe '#read' do
    let(:csv_reader) { SimpleCsvReader::Reader.new(csv_file.path) }
    let(:proc) do
      ->(hash, row_number:) { results[row_number] = hash }
    end
    let(:headers) { { company_name: '会社名', user_name: 'ユーザ名' } }
    let(:csv_content) do
      <<~CSV
        会社名,ユーザ名
        テスト株式会社,tester1
        テスト株式会社,tester2
      CSV
    end
    let(:expected_results) do
      {
        2 => { company_name: 'テスト株式会社', user_name: 'tester1' },
        3 => { company_name: 'テスト株式会社', user_name: 'tester2' },
      }
    end
    let(:results) { {} }

    context 'Character code is utf-8' do
      let(:csv_file) { create_csv_file(csv_content) }

      it 'block is executed with the hash of the row and the row number as args' do
        csv_reader.read(headers, &proc)
        expect(results).to eq expected_results
      end
    end

    context 'Character code is utf-8 and line break code is \r' do
      let(:csv_file) { create_csv_file(csv_content.gsub(/\R/, "\r")) }

      it 'block is executed with the hash of the row and the row number as args' do
        csv_reader.read(headers, &proc)
        expect(results).to eq expected_results
      end
    end

    context 'Character code is utf-8 with bom' do
      let(:csv_file) { create_csv_file("\xEF\xBB\xBF" + csv_content) }

      it 'block is executed with the hash of the row and the row number as args' do
        csv_reader.read(headers, &proc)
        expect(results).to eq expected_results
      end
    end

    context 'Character code is SJIS' do
      let(:csv_file) { create_csv_file(csv_content.encode(Encoding::Shift_JIS, Encoding::UTF_8)) }

      it 'block is executed with the hash of the row and the row number as args' do
        csv_reader.read(headers, &proc)
        expect(results).to eq expected_results
      end
    end
  end
end
