module Nokogiri
  module XML
    class Node

      ###
      # Serialize Node using +options+.  Save options can also be set using a
      # block. See SaveOptions.
      #
      # These two statements are equivalent:
      #
      #  node.serialize(:encoding => 'UTF-8', :save_with => FORMAT | AS_XML)
      #
      # or
      #
      #   node.serialize(:encoding => 'UTF-8') do |config|
      #     config.format.as_xml
      #   end
      #
      def serialize *args, &block
        options = args.first.is_a?(Hash) ? args.shift : {
          :encoding   => args[0],
          :save_with  => args[1] || SaveOptions::FORMAT
        }

        encoding = options[:encoding] || document.encoding

        outstring = ""
        if encoding && outstring.respond_to?(:force_encoding)
          begin
            outstring.force_encoding(Encoding.find(encoding))
          rescue
            outstring.force_encoding(Encoding.find('UTF-8'))
          end
        end
        io = StringIO.new(outstring)
        write_to io, options, &block
        io.string
      end

    end
  end
end
