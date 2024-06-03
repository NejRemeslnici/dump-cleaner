module DumpCleaner
  module Cleanup
    module BytesizeHelpers
      # inspired by https://stackoverflow.com/a/67825008/1544012
      def truncate_to_bytes(string, max_bytes:)
        return string unless string.bytesize > max_bytes

        just_over = (0...string.size).bsearch { string[0.._1].bytesize > max_bytes }
        string[0...just_over]
      end

      def replace_suffix(string, suffix:, padding: " ")
        front_max_bytes = string.bytesize - suffix.bytesize

        front = truncate_to_bytes(string, max_bytes: front_max_bytes)
        front = "#{front}#{padding}" while front.bytesize < front_max_bytes

        "#{front}#{suffix}"
      end
    end
  end
end
