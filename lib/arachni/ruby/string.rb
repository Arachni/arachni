=begin
    Copyright 2010-2017 Sarosys LLC <http://www.sarosys.com>

    This file is part of the Arachni Framework project and is subject to
    redistribution and commercial restrictions. Please see the Arachni Framework
    web site for more information on licensing and terms of use.
=end

require 'zlib'

# Overloads the {String} class.
#
# @author Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
class String

    HAS_HTML_TAG_CACHE = Arachni::Support::Cache::LeastRecentlyPushed.new( 1_000 )
    BINARY_CACHE       = Arachni::Support::Cache::LeastRecentlyPushed.new( 1_000 )

    # @param    [Regexp]    regexp
    #   Regular expression with named captures.
    #
    # @return   [Hash]
    #   Grouped matches.
    def scan_in_groups( regexp )
        raise ArgumentError, 'Regexp does not contain any names.' if regexp.names.empty?
        return {} if !(matches = scan( regexp ).first)

        Hash[regexp.names.zip( matches )].reject { |_, v| v.empty? }
    end

    # @param    [String] tag
    #   Tag name to look for, in lower case.
    # @param    [String,Regexp] attributes
    #   Content to look for in attributes, in lower case.
    def has_html_tag?( tag, attributes = nil )
        HAS_HTML_TAG_CACHE.fetch [self, tag, attributes] do
            if attributes
                attributes = ".*#{attributes}"
            end

            self =~ /<\s*#{tag}#{attributes}.*?>/mi
        end
    end

    # @param    [Regexp]    regexp
    #   Regular expression with named captures.
    # @param    [Hash]    substitutions
    #   Hash (with capture names as keys) with which to replace the `regexp`
    #   matches.
    #
    # @return   [String]
    #   Updated copy of self.
    def sub_in_groups( regexp, substitutions )
        dup.sub_in_groups!( regexp, substitutions )
    end

    def escape_double_quote
        gsub( '"', '\"' )
    end

    # @param    [Regexp]    regexp
    #   Regular expression with named captures.
    # @param    [Hash]    updates
    #   Hash (with capture names as keys) with which to replace the `regexp`
    #   matches.
    #
    # @return   [String]
    #   Updated self.
    def sub_in_groups!( regexp, updates )
        return if !(match = regexp.match( self ))

        # updates.reject! { |k| !(match.offset( k ) rescue nil) }

        keys_in_order = updates.keys.sort_by { |k| match.offset( k ) }.reverse
        keys_in_order.each do |k|
            offsets_for_group = match.offset( k )
            self[offsets_for_group.first...offsets_for_group.last] = updates[k]
        end

        self
    end

    # Gets the reverse diff between self and str on a word level.
    #
    #
    #     str = <<END
    #     This is the first test.
    #     Not really sure what else to put here...
    #     END
    #
    #     str2 = <<END
    #     This is the second test.
    #     Not really sure what else to put here...
    #     Boo-Yah!
    #     END
    #
    #     str.rdiff( str2 )
    #     # => "This is the test.\nNot really sure what else to put here...\n"
    #
    #
    # @param [String] other
    #
    # @return [String]
    def rdiff( other )
        return self if self == other

        # get the words of the first text in an array
        s_words = words

        # get what hasn't changed (the rdiff, so to speak) as a string
        (s_words - (s_words - other.words)).join
    end

    # Calculates the difference ratio (at a word level) between `self` and `other`
    #
    # @param    [String]    other
    #
    # @return   [Float]
    #   `0.0` (identical strings) to `1.0` (completely different)
    def diff_ratio( other )
        return 0.0 if self == other
        return 1.0 if empty? || other.empty?

        s_words = self.words( true )
        o_words = other.words( true )

        common = (s_words & o_words).size.to_f
        union  = (s_words | o_words).size.to_f

        (union - common) / union
    end

    # Returns the words in `self`.
    #
    # @param    [Bool]  strict
    #   Include *only* words, no boundary characters (like spaces, etc.).
    #
    # @return   [Array<String>]
    def words( strict = false )
        splits = split( /\b/ )
        splits.reject! { |w| !(w =~ /\w/) } if strict
        splits
    end

    # @return [String]
    #   Shortest word.
    def shortest_word
        words( true ).sort_by { |w| w.size }.first
    end

    # @return [String]
    #   Longest word.
    def longest_word
        words( true ).sort_by { |w| w.size }.last
    end

    # @return   [Integer]
    #   In integer with the property of:
    #
    #   If `str1 == str2` then `str1.persistent_hash == str2.persistent_hash`.
    #
    #   It basically has the same function as Ruby's `#hash` method, but does
    #   not use a random seed per Ruby process -- making it suitable for use
    #   in distributed systems.
    def persistent_hash
        Zlib.crc32 self
    end

    def recode!
        force_encoding( 'utf-8' )
        encode!( 'utf-8', invalid: :replace, undef: :replace )
        self
    end

    def recode
        dup.recode!
    end

    def binary?
        # Stolen from YAML.
        BINARY_CACHE.fetch self do
            ( index("\x00") ||
                count("\x00-\x7F", "^ -~\t\r\n").fdiv(length) > 0.3)
        end
    end

end
