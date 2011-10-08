=begin
                  Arachni
  Copyright (c) 2010-2011 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'datamapper'

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
# @version: 0.1.1
#
class ReportManager

    FOLDERNAME = "reports"
    EXTENSION  = '.afr'

    class Report
        include DataMapper::Resource

        property :id,           Serial
        property :host,         String
        property :issue_count,  Integer
        property :filename,     String
        property :datestamp,    DateTime
    end


    def initialize( opts, settings )
        @opts     = opts
        @settings = settings
        populate_available

        DataMapper::setup( :default, "sqlite3://#{@settings.db}/default.db" )
        DataMapper.finalize

        Report.auto_upgrade!

        migrate_files
    end

    #
    # Migrates AFR reports from the savedir folder into the DB
    # so that users will be able to manage them via the WebUI
    #
    def migrate_files
        Dir.glob( "#{savedir}*" + EXTENSION ).each {
            |file|
            next if Report.first( :filename => File.basename( file, EXTENSION ) )

            begin
                data = File.read( file )
                Report.create(
                    :issue_count => get_issue_count( data ),
                    :host        => get_host( data ),
                    :filename    => File.basename( file, EXTENSION ),
                    :datestamp   => get_finish_datetime( data )
                )
            rescue
            end
        }
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
    # @param    [Arachni::AuditStore]    report   audistore object as returned by the Arachni RPC server.
    #                                       Basically an 'afr' report as a string.
    #
    # @return   [String]        the path to the saved report
    #
    def save( report )
        report = report.to_yaml
        @settings.log.report_saved( {}, get_filename( report ) )
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
    def all( *args )
        Report.all( *args )
    end

    def delete_all
        all.each {
            |report|
            delete( report.id )
        }
        all.destroy
    end

    def delete( id )
        report = Report.get( id )
        begin
            FileUtils.rm( savedir + Report.get( id ).filename + EXTENSION )
        rescue
        end

        begin
            report.destroy
        rescue
        end
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
        rep = unserialize( report )
        filename = "#{URI(rep.options['url']).host}:#{rep.start_datetime}"
    end

    def get_issue_count( report )
        unserialize( report ).issues.size
    end

    def get_host( report )
        return URI(unserialize( report ).options['url']).host
    end

    def get_finish_datetime( report )
        return unserialize( report ).finish_datetime
    end

    #
    # Returns a stored report as a <type> file. Basically a convertion/export method.
    #
    # @param    [String]    type      html, txt, xml, etc
    # @param    [Integer]   id        report id
    #
    # @return   [String]    the converted report
    #
    def get( type, id )
        return if !valid_class?( type )

        begin
            location = savedir + Report.get( id ).filename + EXTENSION
            convert( type, File.read( location ) )
        rescue Exception => e
            ap e
            ap e.backtrace
            return nil
        end
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

    def unserialize( data )
         begin
            Marshal.load( data )
         rescue
             YAML.load( data )
         end
    end

    def save_to_file( data, file )
        return file if File.exists?( file )

        f = File.new( file, 'w' )
        f.write( data )
        f.close

        Report.create(
            :issue_count => get_issue_count( data ),
            :host        => get_host( data ),
            :filename    => File.basename( f.path, EXTENSION ),
            :datestamp   => Time.now.asctime
        )

        return f.path
    end

    def convert( type, report )

        opts = {}
        classes[type].info[:options].each {
            |opt|
            opts[opt.name] = opt.default if opt.default
        }
        opts['outfile'] = get_tmp_outfile_name( type, report )

        classes[type].new( unserialize( report ), opts ).run

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
                    'version'     => report_mgr[avail].info[:version],
                    'author'      => report_mgr[avail].info[:author]
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
