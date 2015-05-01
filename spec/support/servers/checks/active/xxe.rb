require 'nokogiri'
require 'sinatra'

FILE_TO_PLATFORM = {
    '%SYSTEMDRIVE%\boot.ini' => :windows,
    '%WINDIR%\win.ini'       => :windows,
    '/etc/passwd'            => :unix,
    '/proc/self/environ'     => :unix
}

OUT = {
    unix:    'root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/sh
mail:x:8:8:mail:/var/mail:/bin/sh

DOCUMENT_ROOT=/home/www/web424/htmlGATEWAY_INTERFACE=CGI/1.1HTTP_ACCEPT=text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8HTTP_ACCEPT_ENCODING=gzip, deflateHTTP_ACCEPT_LANGUAGE=en-US,en;q=0.5HTTP_CONNECTION=keep-aliveHTTP_DNT=1HTTP_HOST=www.kaffeehausleclub.deHTTP_USER_AGENT=Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:22.0) Gecko/20100101 Firefox/22.0PATH=/bin:/usr/binPHPRC=/etc/apache2/confixx_php/web424/1QUERY_STRING=inhalt=/proc/self/environREDIRECT_STATUS=200REMOTE_ADDR=79.107.71.228REMOTE_PORT=48720REQUEST_METHOD=GETREQUEST_URI=/inhalt/start.php?inhalt=/proc/self/environSCRIPT_FILENAME=/home/www/web424/html/inhalt/start.phpSCRIPT_NAME=/inhalt/start.phpSERVER_ADDR=87.119.215.14SERVER_ADMIN=[no address given]SERVER_NAME=www.kaffeehausleclub.deSERVER_PORT=80SERVER_PROTOCOL=HTTP/1.1SERVER_SIGNATURE=
Apache/2.2.16 (Debian) Server at www.kaffeehausleclub.de Port 80
SERVER_SOFTWARE=Apache/2.2.16 (Debian)UNIQUE_ID=Uf6y2Fd31w4AAHYyW8AAAAAk
',
    windows: '[boot loader]
timeout=30
default=multi(0)disk(0)rdisk(0)partition(1)\WINDOWS
[operating systems]
multi(0)disk(0)rdisk(0)partition(1)\WINDOWS="Microsoft Windows XP Professional" /fastdetect

; for 16-bit app support
[fonts]
[extensions]
[mci extensions]
[files]
[Mail]
MAPI=1
CMC=1
CMCDLLNAME32=mapi32.dll
CMCDLLNAME=mapi.dll
MAPIX=1
'
}

def get_variations( system )
    return if !@xml.to_s.include?( '<input>&xxe_entity;</input>')

    file = @xml.to_s.scan( /SYSTEM "(.*)">/ ).first.first

    return if system != FILE_TO_PLATFORM[file]

    p @xml.to_s

    OUT[FILE_TO_PLATFORM[file]]
end

before do
    begin
        @xml = Nokogiri::XML( request.body.read )
    rescue JSON::ParserError
    end
    request.body.rewind
end

OUT.keys.each do |system|
    system_str = system.to_s

    get '/' + system_str do
        <<-EOHTML
            <a href="/#{system_str}/xml">XML</a>
        EOHTML
    end

    get "/#{system_str}/xml" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system_str}/xml/text/straight", true);
                http_request.send( '<input>arachni_user</input>' );
            </script>
        EOHTML
    end

    post "/#{system_str}/xml/text/straight" do
        return if !@xml

        get_variations( system )
    end

end
