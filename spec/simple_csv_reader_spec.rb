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

  describe '#each' do
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
      let(:csv_reader) { SimpleCsvReader::Reader.new(csv_file.path, headers) }
      let(:csv_file) { create_csv_file(csv_content) }

      it 'block is executed with the hash of the row and the row number as args' do
        csv_reader.each(&proc)
        expect(results).to eq expected_results
      end
    end

    context 'unless block given' do
      let(:csv_reader) { SimpleCsvReader::Reader.new(csv_file.path, headers) }
      let(:csv_file) { create_csv_file(csv_content) }

      it 'return Enumerator' do
        enum = csv_reader.each
        expect(enum.to_a).to eq [
          [{ company_name: 'テスト株式会社', user_name: 'tester1' }, { row_number: 2 }],
          [{ company_name: 'テスト株式会社', user_name: 'tester2' }, { row_number: 3 }],
        ]
      end
    end

    context 'Character code is utf-8 and line break code is \r' do
      let(:csv_reader) { SimpleCsvReader::Reader.new(csv_file.path, headers) }
      let(:csv_file) { create_csv_file(csv_content.gsub(/\R/, "\r")) }

      it 'block is executed with the hash of the row and the row number as args' do
        csv_reader.each(&proc)
        expect(results).to eq expected_results
      end
    end

    context 'Character code is utf-8 with bom' do
      let(:csv_reader) { SimpleCsvReader::Reader.new(csv_file.path, headers) }
      let(:csv_file) { create_csv_file("\xEF\xBB\xBF" + csv_content) }

      it 'block is executed with the hash of the row and the row number as args' do
        csv_reader.each(&proc)
        expect(results).to eq expected_results
      end
    end

    context 'Character code is SJIS' do
      let(:csv_reader) { SimpleCsvReader::Reader.new(csv_file.path, headers) }
      let(:csv_file) { create_csv_file(csv_content.encode(Encoding::Shift_JIS, Encoding::UTF_8)) }

      it 'block is executed with the hash of the row and the row number as args' do
        csv_reader.each(&proc)
        expect(results).to eq expected_results
      end
    end

    context 'unnecessary columns exist' do
      let(:csv_reader) { SimpleCsvReader::Reader.new(csv_file.path, headers) }
      let(:csv_content) do
        <<~CSV
          会社名,ユーザ名,dummy
          テスト株式会社,tester1,dummy1
          テスト株式会社,tester2,dummy2
        CSV
      end
      let(:csv_file) { create_csv_file(csv_content) }

      it 'ignored' do
        csv_reader.each(&proc)
        expect(results).to eq expected_results
      end
    end

    context 'unnecessary columns exist with include_unspecified_headers option' do
      let(:csv_content) do
        <<~CSV
          会社名,ユーザ名,dummy,id
          テスト株式会社,tester1,dummy1,1
          テスト株式会社,tester2,dummy2,2
        CSV
      end
      let(:csv_file) { create_csv_file(csv_content) }
      let(:expected_results) do
        {
          2 => { company_name: 'テスト株式会社', "dummy" => 'dummy1', "id" =>  1, user_name: 'tester1' },
          3 => { company_name: 'テスト株式会社', "dummy" => 'dummy2', "id" => 2, user_name: 'tester2' },
        }
      end
      let(:csv_reader) { SimpleCsvReader::Reader.new(csv_file.path, headers, include_unspecified_headers: true) }

      it 'included' do
        csv_reader.each(&proc)
        expect(results).to eq expected_results
      end
    end

    context 'zero padding numeric' do
      let(:csv_content) do
        <<~CSV
          会社名,ユーザ名,社員ID
          テスト株式会社,tester1,0001
          テスト株式会社,tester2,0002
        CSV
      end
      let(:csv_file) { create_csv_file(csv_content) }
      let(:headers) { { company_name: '会社名', user_name: 'ユーザ名', id: '社員ID' } }
      let(:expected_results) do
        {
          2 => { company_name: 'テスト株式会社', user_name: 'tester1', id:  '0001' },
          3 => { company_name: 'テスト株式会社', user_name: 'tester2', id:  '0002' },
        }
      end

      it 'Read as string when converters is nil' do
        csv_reader = SimpleCsvReader::Reader.new(csv_file.path, headers, converters: nil)
        csv_reader.each(&proc)
        expect(results).to eq expected_results
      end

      it 'Read as string when default_converters is nil' do
        SimpleCsvReader::Reader.default_converters = nil
        csv_reader = SimpleCsvReader::Reader.new(csv_file.path, headers)
        csv_reader.each(&proc)
        expect(results).to eq expected_results
        SimpleCsvReader::Reader.default_converters = :numeric
      end
    end

    context 'nil value' do
      let(:csv_content) do
        <<~CSV
          会社名,ユーザ名,社員ID
          テスト株式会社,tester1,
        CSV
      end
      let(:csv_file) { create_csv_file(csv_content) }
      let(:headers) { { company_name: '会社名', user_name: 'ユーザ名', id: '社員ID' } }

      it 'value is nil when default' do
        csv_reader = SimpleCsvReader::Reader.new(csv_file.path, headers)
        result = csv_reader.each.to_a.first
        expect(result[0][:id]).to eq nil
      end

      it 'value is empty string when nil_value is empty string' do
        csv_reader = SimpleCsvReader::Reader.new(csv_file.path, headers, nil_value: '')
        result = csv_reader.each.to_a.first
        expect(result[0][:id]).to eq ''
      end

      it 'value is empty string when default_nil_value is empty string' do
        SimpleCsvReader::Reader.default_nil_value = ''
        csv_reader = SimpleCsvReader::Reader.new(csv_file.path, headers)
        result = csv_reader.each.to_a.first
        expect(result[0][:id]).to eq ''
        SimpleCsvReader::Reader.default_nil_value = nil
      end
    end
  end
end
