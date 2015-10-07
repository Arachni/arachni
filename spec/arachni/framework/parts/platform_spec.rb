require 'spec_helper'

describe Arachni::Framework::Parts::Platform do
    include_examples 'framework'

    describe '#list_platforms' do
        it 'returns information about all valid platforms' do
            expect(subject.list_platforms).to eq({
                'Operating systems' => {
                    unix:    'Generic Unix family',
                    linux:   'Linux',
                    bsd:     'Generic BSD family',
                    aix:     'IBM AIX',
                    solaris: 'Solaris',
                    windows: 'MS Windows'
                },
                'Databases' => {
                    sql:        'Generic SQL family',
                    access:     'MS Access',
                    db2:        'DB2',
                    emc:        'EMC',
                    firebird:   'Firebird',
                    frontbase:  'Frontbase',
                    hsqldb:     'HSQLDB',
                    informix:   'Informix',
                    ingres:     'IngresDB',
                    interbase:  'InterBase',
                    maxdb:      'SaP Max DB',
                    mssql:      'MSSQL',
                    mysql:      'MySQL',
                    oracle:     'Oracle',
                    pgsql:      'Postgresql',
                    sqlite:     'SQLite',
                    sybase:     'Sybase',
                    nosql:      'Generic NoSQL family',
                    mongodb:    'MongoDB'
                },
                'Web servers' => {
                    apache:   'Apache',
                    iis:      'IIS',
                    jetty:    'Jetty',
                    nginx:    'Nginx',
                    tomcat:   'TomCat',
                    gunicorn: 'Gunicorn',
                },
                'Programming languages' => {
                    asp:    'ASP',
                    aspx:   'ASP.NET',
                    java:   'Java',
                    perl:   'Perl',
                    php:    'PHP',
                    python: 'Python',
                    ruby:   'Ruby'
                },
                'Frameworks' => {
                    rack:     'Rack',
                    django:   'Django',
                    rails:    'Ruby on Rails',
                    aspx_mvc: 'ASP.NET MVC',
                    jsf:      'JavaServer Faces',
                    cherrypy: 'CherryPy',
                    cakephp:  'CakePHP',
                    symfony:  'Symfony',
                    nette:    'Nette'
                }
            })
        end
    end

end
