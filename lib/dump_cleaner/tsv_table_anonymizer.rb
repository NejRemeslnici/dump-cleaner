class DumpCleaner::TsvTableAnonymizer
  require "yaml"
  require "json"
  require "zlib"
  require "random/formatter"

  cattr_accessor :fake_data

  def initialize(table, config:, table_info:)
    @table = table
    @config = config
    @table_info = table_info
    self.class.fake_data = {}
  end

  def run
    table["columns"].each do |column|

    end
  end

  # columns = YAML.load_file("config/columns_to_anonymize.yml")
  # p columns

  # table = ARGV[1]
  # column = ARGV[2]

  # columns = JSON.parse(File.read("/home/matous/projekty/nejremeslnici/web/db/nere-db-backup-2024-04-22T01:15:01/nere_production@users.json"))
  # p columns
  # column_index = columns.dig("options", "columns").index("street")
  column_index = 5

  data = YAML.load_file("lib/data/street.yml")

  n = 1
  STDIN.each_line do |line|
    if line =~ /[\u0080-\u009f]/
      STDERR.puts "=== Warning: input contains invalid UTF-8 characters"
      STDERR.puts line.split("").map(&:codepoints).map { |c| c.any? { _1.between?(0x80, 0x9f) } ? c.map { "\\u00#{_1.to_s(16)}" } : c.pack("U*")  }.join
      # break
    end

    line.gsub!(/[\u0080-\u009f]/, "  ")

    record = line.split("\t")
    unless (column = record[column_index]) == "\\N"
      id = record[0]
      fake_data_pool = data[column.bytes.length]

      if fake_data_pool
        chosen_fake_data_index = Zlib.crc32(id.to_s) % fake_data_pool.size
        record[column_index] = fake_data_pool[chosen_fake_data_index]
      else
        STDERR.puts "ID #{id}: Cannot find appropriate fake data for '#{column}', using some random string instead."
        record[column_index] = ("anonymized street " * 10).slice(0...column.bytes.length)
      end
    end

    STDOUT.write record.join("\t")

    n += 1
    # break if n == 1000
  end
end
