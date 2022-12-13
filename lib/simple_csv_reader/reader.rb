# frozen_string_literal: true

require 'csv'
require 'nkf'

module SimpleCsvReader
  class Reader
    def initialize(path, headers, **options)
      @path = path
      @headers = headers
      @options = options
    end

    def each(&block)
      return enum_for(:each) unless block_given?

      # NOTE: The first line is a header
      csv.each.with_index(2) do |row, row_number|
        hash = row.to_h
        next if hash.compact.empty? # NOTE: blank row

        filtered_hash = @options[:include_unspecified_headers] ? hash : hash.slice(*@headers.keys)
        yield(filtered_hash, row_number: row_number)
      end
    end

    def self.default_converters
      instance_variable_defined?(:@default_converters) ? @default_converters : :numeric
    end

    def self.default_converters=(converters)
      @default_converters = converters
    end

    def self.default_nil_value
      instance_variable_defined?(:@default_nil_value) ? @default_nil_value : nil
    end

    def self.default_nil_value=(value)
      @default_nil_value = value
    end

    private

    def csv
      header_converter = -> { @headers.invert.fetch(_1, _1) }
      CSV.parse(content, headers: :first_row, header_converters: header_converter, converters: converters, nil_value: nil_value)
    end

    def converters
      @options.fetch(:converters) { self.class.default_converters }
    end

    def nil_value
      @options.fetch(:nil_value) { self.class.default_nil_value }
    end

    def content
      NKF.nkf('-w', File.read(@path, universal_newline: true))
    end
  end
end
