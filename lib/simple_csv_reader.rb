# frozen_string_literal: true

require_relative "simple_csv_reader/reader"
require_relative "simple_csv_reader/version"

module SimpleCsvReader
  def read(path, headers, **options, &block)
    Reader.new(path).read(headers, **options, &block)
  end

  module_function :read
end
