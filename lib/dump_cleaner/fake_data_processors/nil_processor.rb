module DumpCleaner::FakeDataProcessors
  class NilProcessor
    def self.process(data)
      data
    end
  end
end
