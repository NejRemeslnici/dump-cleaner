module DumpCleaner
  module Cleanup
    module BytesizeHelpers
      # inspired by https://stackoverflow.com/a/67825008/1544012
      def truncate_to_bytesize(string, max_bytesize:, padding: " ")
        return string unless string.bytesize > max_bytesize

        check_padding_bytesize(padding)

        just_over = (0...string.size).bsearch { string[0.._1].bytesize > max_bytesize }
        string = string[0...just_over]

        string << padding while string.bytesize < max_bytesize
        string
      end

      def replace_suffix(string, suffix:, padding: " ")
        front_max_bytes = string.bytesize - suffix.bytesize
        front = truncate_to_bytesize(string, max_bytesize: front_max_bytes, padding:)

        "#{front}#{suffix}"
      end

      private

      def check_padding_bytesize(padding)
        return unless padding.bytesize > 1

        raise ArgumentError,
              "Use only a single-byte string in the padding otherwise it may prevent adjusting the result precisely."
      end
    end
  end
end
