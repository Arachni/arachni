require 'arachni'

include Arachni

$options = Marshal.load( Base64.strict_decode64( ARGV.pop ) )

Options.update $options.delete(:options)

load ARGV.pop
