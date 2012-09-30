=begin
    Copyright 2010-2012 Tasos Laskos <tasos.laskos@gmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
=end

module Arachni
module UI
module Web

#
#
# Provides nice little wrapper for the Arachni::Report::Manager while also handling<br/>
# conversions, storing etc.
#
# @author Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      
# @version 0.2
#
class ReportManager

    FOLDERNAME = "reports"
    EXTENSION  = '.afr'

    class Report
        include DataMapper::Resource

        property :id,           Serial
        property :host,         Text
        property :issue_count,  Integer
        property :filename,     Text
        property :datestamp,    DateTime
    end

    def initialize( opts, settings )
        @opts     = opts
        @settings = settings
        populate_available

        DataMapper::setup( :default, "sqlite3://#{@settings.db}/default.db" )
        DataMapper.finalize

        # Report.raise_on_save_failure = true
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
                report = ::Arachni::AuditStore.load( file )
                Report.create(
                    :issue_count => get_issue_count( report ),
                    :host        => get_host( report ),
                    :filename    => File.basename( file, EXTENSION ),
                    :datestamp   => get_finish_datetime( report )
                )
            rescue Exception => e
                # p file
                # ap e
                # ap e.backtrace
            end
        }
    end

    #
    # @return    [String]    save directory
    #
    def savedir
        @settings.public_folder + "/#{FOLDERNAME}/"
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
    # @param    [Arachni::AuditStore]    report
    #
    # @return   [String]        the path to the saved report
    #
    def save( report )
        @settings.log.report_saved( {}, report_to_filename( report ) )
        return save_to_file( report, report_to_path( report ) )
    end

    #
    # Gets the path to a given report based on the contents of the report
    #
    # @param    [Arachni::AuditStore]   report
    # @return   [String]
    #
    def report_to_path( report )
        savedir + File.basename( report_to_filename( report ) + EXTENSION )
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
    # @param    [Arachni::AuditStore]    report
    #
    # @return   [String]        host.audit_date.ext
    #
    def report_to_filename( report )
        filename = "#{URI(report.options['url']).host}:#{report.start_datetime}"
        filename.gsub( ':', '.' ).gsub( ' ', '_' ).gsub( '-', '_' ).gsub( '__', '_' )
    end

    def get_issue_count( report )
        report.issues.size
    end

    def get_host( report )
        return URI( report.options['url'] ).host
    end

    def get_finish_datetime( report )
        return report.finish_datetime
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

        # begin
            location = savedir + Report.get( id ).filename + EXTENSION

            # if it's the default report type don't waste time converting
            if '.' + type == EXTENSION
                return File.read( location )
            else
                return convert( type, ::Arachni::AuditStore.load( location ) )
            end
        # rescue Exception => e
            # ap e
            # ap e.backtrace
            # return nil
        # end
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

    def save_to_file( report, file )
        report.save( file )
        Report.create(
            :issue_count => get_issue_count( report ),
            :host        => get_host( report ),
            :filename    => File.basename( file, EXTENSION ),
            :datestamp   => DateTime.now
        )

        return file
    end

    def convert( type, report )
        opts = {}

        classes[type].info[:options].each {
            |opt|
            opts[opt.name] = opt.default if opt.default
        }

        opts['outfile'] = get_tmp_outfile_name( type, report )

        classes[type].new( report, opts ).run

        content = File.read( opts['outfile'] )
        FileUtils.rm( opts['outfile'] )
        return content
    end

    def get_tmp_outfile_name( type, report )
        tmpdir + report_to_filename( report ) + '.' + type
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
                    'author'      => [report_mgr[avail].info[:author]].flatten
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
