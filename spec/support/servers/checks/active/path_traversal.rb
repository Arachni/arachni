require 'nokogiri'
require 'json'
require 'sinatra'
require 'sinatra/contrib'

def default
    "default.html"
end

FILE_TO_PLATFORM = {
    '/boot.ini'          => :windows,
    '/windows/win.ini'   => :windows,
    '/winnt/win.ini'     => :windows,
    '/etc/passwd'        => :unix,
    '/proc/self/environ' => :unix,
    '/WEB-INF/web.xml'   => :java
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
',
    java: '<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://java.sun.com/xml/ns/javaee" xmlns:web="http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd" xsi:schemaLocation="http://java.sun.com/xml/ns/javaee http://java.sun.com/xml/ns/javaee/web-app_2_5.xsd" id="WebApp_ID" version="2.5">
  <display-name>VulnerabilityDetectionChallenge</display-name>
  <welcome-file-list>
    <welcome-file>index.html</welcome-file>
    <welcome-file>index.htm</welcome-file>
    <welcome-file>index.jsp</welcome-file>
    <welcome-file>default.html</welcome-file>
    <welcome-file>default.htm</welcome-file>
    <welcome-file>default.jsp</welcome-file>
  </welcome-file-list>

  <!-- Define a Security Constraint on this Application -->
  <security-constraint>
    <web-resource-collection>
     <web-resource-name>Weak authentication - basic</web-resource-name>
     <url-pattern>/passive/session/weak-authentication-basic.jsp</url-pattern>
    </web-resource-collection>
    <auth-constraint>
     <role-name>tomcat</role-name>
     <role-name>role1</role-name>
    </auth-constraint>
  </security-constraint>

  <!-- Define the Login Configuration for this Application -->
  <login-config>
    <auth-method>BASIC</auth-method>
    <realm-name>Application</realm-name>
    <!--realm-name>Weak authentication - basic</realm-name-->
  </login-config>

  <!-- Security roles referenced by this web application -->
  <security-role>
    <description>
      The role that is required to access protected pages
    </description>
     <role-name>tomcat</role-name>
  </security-role>

  <security-role>
    <description>
      The role that is required to access protected pages
    </description>
     <role-name>role1</role-name>
  </security-role>
'
}

def get_variations( system, str )
    return if !str

    require 'ap'

    str = str.split( "\0" ).first
    str = str.split( 'file:/' ).last
    str = str.split( 'c:' ).last

    file = str.gsub( /\.{2,}/, '' ).gsub( '\\', '/' ).gsub( /\/+/, '/' )
    file = "/#{file}" if file[0] != '/'

    OUT[FILE_TO_PLATFORM[file]] if system == FILE_TO_PLATFORM[file]
end

before do
    request.body.rewind
    begin
        @json = JSON.parse( request.body.read )
    rescue JSON::ParserError
    end
    request.body.rewind

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
            <a href="/#{system_str}/link?input=default">Link</a>
            <a href="/#{system_str}/form">Form</a>
            <a href="/#{system_str}/cookie">Cookie</a>
            <a href="/#{system_str}/header">Header</a>
            <a href="/#{system_str}/link-template">Link template</a>
            <a href="/#{system_str}/json">JSON</a>
            <a href="/#{system}/xml">XML</a>
        EOHTML
    end

    get "/#{system_str}/link" do
        <<-EOHTML
            <a href="/#{system_str}/link/straight?input=#{default}">Link</a>
            <a href="/#{system_str}/link/with_null?input=#{default}">Link</a>
        EOHTML
    end

    get "/#{system_str}/link/straight" do
        return if params['input'].start_with?( default ) || params['input'].include?( "\0" )
        get_variations( system, params['input'] )
    end

    get "/#{system_str}/link/with_null" do
        return if !params['input'].end_with?( "\00.html" )
        get_variations( system, params['input'].split( "\0.html" ).first )
    end

    get "/#{system_str}/link-template" do
        <<-EOHTML
        <a href="/#{system_str}/link-template/straight/input/default/stuff">Link</a>
        <a href="/#{system_str}/link-template/with_null/input/default/stuff">Link</a>
        EOHTML
    end

    get "/#{system_str}/link-template/straight/input/*/stuff" do
        val = params[:splat].first
        default = 'default'
        return if val.start_with?( default )

        get_variations( system, val.split( default ).last )
    end

    get "/#{system_str}/link-template/with_null/input/*/stuff" do
        val = params[:splat].first
        default = 'default'
        return if !val.end_with?( "\00.html" )

        get_variations( system, val.split( default ).last )
    end

    get "/#{system_str}/form" do
        <<-EOHTML
            <form action="/#{system_str}/form/straight" method='post'>
                <input name='input' value='#{default}' />
            </form>

            <form action="/#{system_str}/form/with_null" method='post'>
                <input name='input' value='#{default}' />
            </form>

        EOHTML
    end

    post "/#{system_str}/form/straight" do
        return if params['input'].start_with?( default ) || params['input'].include?( "\0" )
        get_variations( system, params['input'] )
    end

    post "/#{system_str}/form/with_null" do
        return if !params['input'].end_with?( "\00.html" )
        get_variations( system, params['input'].split( "\0.html" ).first )
    end

    get "/#{system_str}/cookie" do
        <<-HTML
            <a href="/#{system_str}/cookie/straight">Cookie</a>
            <a href="/#{system_str}/cookie/with_null">Cookie</a>
        HTML
    end

    get "/#{system_str}/cookie/straight" do
        cookies['cookie'] ||= default
        return if cookies['cookie'].start_with?( default ) || cookies['cookie'].include?( "\0" )

        get_variations( system, cookies['cookie'] )
    end

    get "/#{system_str}/cookie/with_null" do
        cookies['cookie1'] ||= default
        return if !cookies['cookie1'].include?( "\00." )

        get_variations( system, cookies['cookie1'] )
    end

    get "/#{system_str}/header" do
        <<-EOHTML
            <a href="/#{system_str}/header/straight">Header</a>
        EOHTML
    end

    get "/#{system_str}/header/straight" do
        default = 'arachni_user'
        return if env['HTTP_USER_AGENT'].start_with?( default )

        get_variations( system, env['HTTP_USER_AGENT'] )
    end

    get "/#{system_str}/json" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system_str}/json/straight", true);
                http_request.send( '{"input": "#{default}"}' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system_str}/json/with_null", true);
                http_request.send( '{"input": "#{default}"}' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system_str}/json/append", true);
                http_request.send( '{"input": "#{default}"}' );
            </script>
        EOHTML
    end

    post "/#{system_str}/json/straight" do
        return if !@json
        return if @json['input'].start_with?( default )

        get_variations( system, @json['input'] )
    end

    post "/#{system_str}/json/with_null" do
        return if !@json
        return if !@json['input'].include?( "\00." )

        get_variations( system, @json['input'] )
    end

    post "/#{system_str}/json/append" do
        return if !@json
        return if !@json['input'].start_with?( default )

        get_variations( system, @json['input'].split( default ).last )
    end

    get "/#{system}/xml" do
        <<-EOHTML
            <script type="application/javascript">
                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system}/xml/text/straight", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system}/xml/text/append", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system}/xml/text/with_null", true);
                http_request.send( '<input>arachni_user</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system}/xml/attribute/straight", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system}/xml/attribute/with_null", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );

                http_request = new XMLHttpRequest();
                http_request.open( "POST", "/#{system}/xml/attribute/append", true);
                http_request.send( '<input my-attribute="arachni_user">stuff</input>' );
            </script>
        EOHTML
    end

    post "/#{system}/xml/text/straight" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first.content

        return if input.start_with?( default )

        get_variations( system, input )
    end

    post "/#{system}/xml/text/with_null" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first.content

        return if !input.include?( "\00." )

        get_variations( system, input.split( default ).last )
    end

    post "/#{system}/xml/text/append" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first.content

        return if !input.start_with?( default )

        get_variations( system, input.split( default ).last )
    end

    post "/#{system}/xml/attribute/straight" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if input.start_with?( default )

        get_variations( system, input )
    end

    post "/#{system}/xml/attribute/with_null" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if !input.include?( "\00." )

        get_variations( system, input.split( default ).last )
    end

    post "/#{system}/xml/attribute/append" do
        return if !@xml

        default = 'arachni_user'
        input = @xml.css('input').first['my-attribute']

        return if !input.start_with?( default )

        get_variations( system, input.split( default ).last )
    end

end
