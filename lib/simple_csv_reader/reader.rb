# frozen_string_literal: true

require 'csv'
require 'nkf'

module SimpleCsvReader
  class Reader
    def initialize(path)
      @path = path
    end

    def read(headers, **options, &block)
      # NOTE: The first line is a header
      csv(headers).each.with_index(2) do |row, row_number|
        hash = row.to_h
        next if hash.compact.empty? # NOTE: blank row

        filtered_hash = options[:include_unspecified_headers] ? hash : hash.slice(*headers.keys)
        yield(filtered_hash, row_number: row_number)
      end
    end

    private

    def csv(headers)
      header_converter = -> { headers.invert.fetch(_1, _1) }
      CSV.parse(content, headers: :first_row, header_converters: header_converter, converters: :integer)
    end

    def content
      NKF.nkf('-w', File.read(@path, universal_newline: true))
    end
  end
end
