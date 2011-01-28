=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module UI
module Web

#
#
# Provides nice little wrapper for the Arachni::Report::Manager while also handling<br/>
# conversions, storing etc.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class ReportManager

    FOLDERNAME = "reports"
    EXTENSION  = '.afr'

   def initialize( opts, settings )
        @opts     = opts
        @settings = settings
        populate_available
   end

    #
    # @return    [String]    save directory
    #
    def savedir
        @settings.public + "/#{FOLDERNAME}/"
    end

    #
    # @return    [String]    tmp directory for storage while converting
    #
    def tmpdir
        @settings.tmp + '/'
    end

    #
    # Saves the report to a file
    #
    # @param    [String]        report  YAML serialized audistore object as returned by the Arachni XMLRPC server.
    #                                       Basically an 'afr' report as a string.
    #
    # @return   [String]        the path to the saved report
    #
    def save( report )
        return save_to_file( report, report_to_path( report ) )
    end

    #
    # Gets the path to a given report based on the contents of the report
    #
    # @param    [String]        report  YAML serialized audistore object as returned by the Arachni XMLRPC server.
    #                                       Basically an 'afr' report as a string.
    # @return   [String]
    #
    def report_to_path( report )
        savedir + File.basename( get_filename( report ) + EXTENSION )
    end

    #
    # Checks whether the provided type is a usable report
    #
    # @param    [String]    type    usually html,txt,xml etc
    #
    # @return   [Bool]
    #
    def valid_class?( type )
        classes[type] || false
    end

    #
    # Returns the paths of all saved report files as an array
    #
    # @return    [Array]
    #
    def all
        Dir.glob( savedir + "*#{EXTENSION}" )
    end

    def delete_all
        all.each {
            |report|
            delete( report )
        }
    end

    def delete( report )
        FileUtils.rm( savedir + File.basename( report, '.afr' ) + '.afr' )
    end

    #
    # Generates a filename based on the contents of the report in the form of
    # host:audit_date
    #
    # @param    [String]        report  YAML serialized audistore object as returned by the Arachni XMLRPC server.
    #                                       Basically an 'afr' report as a string.
    #
    # @return   [String]        host:audit_date
    #
    def get_filename( report )
        rep = YAML::load( report )
        filename = "#{URI(rep.options['url']).host}:#{rep.start_datetime}"
    end

    #
    # Returns a stored report as a <type> file. Basically a convertion/export method.
    #
    # @param    [String]    type            html, txt, xml, etc
    # @param    [String]    report_file     path to the report
    #
    # @return   [String]    the converted report
    #
    def get( type, report_file )
        return if !valid_class?( type )

        location = savedir + report_file + EXTENSION
        convert( type, File.read( location ) )
    end

    #
    # Returns all available report types
    #
    # @return   [Array]
    #
    def available
        return @@available
    end

    #
    # Returns all available report classes
    #
    # @return   [Array]
    #
    def classes
        @@available_rep_classes
    end

    private

    def save_to_file( data, file )
        f = File.new( file, 'w' )
        f.write( data )
        f.close

        return f.path
    end

    def convert( type, report )

        opts = {}
        classes[type].info[:options].each {
            |opt|
            opts[opt.name] = opt.default if opt.default
        }
        opts['outfile'] = get_tmp_outfile_name( type, report )

        classes[type].new( YAML::load( report ), opts ).run

        content = File.read( opts['outfile'] )
        FileUtils.rm( opts['outfile'] )
        return content
    end


    def get_tmp_outfile_name( type, report )
        tmpdir + get_filename( report ) + '.' + type
    end

    def has_outfile?( options )
        options.each {
            |opt|
            return true if opt.name == 'outfile'
        }

        return false
    end


    def populate_available
        @@available ||= []
        return @@available if !@@available.empty?

        @@available_rep_classes ||= {}
        report_mgr = ::Arachni::Report::Manager.new( @opts )
        report_mgr.available.each {
            |avail|

            next if !report_mgr[avail].info[:options]
            if has_outfile?( report_mgr[avail].info[:options] )
                @@available << {
                    'name'        => report_mgr[avail].info[:name],
                    'rep_name'    => avail,
                    'description' => report_mgr[avail].info[:description],
                }

                @@available_rep_classes[avail] = report_mgr[avail]

            end
        }
        return @@available
    end

end
end
end
end
