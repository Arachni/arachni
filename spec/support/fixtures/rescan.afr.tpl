--- !ruby/object:Arachni::AuditStore
delta_time: "00:00:01"
finish_datetime: Sat Jul 14 02:08:49 2012
issues: []

options:
  dir:
    root: /home/zapotek/workspace/arachni/
    gfx: /home/zapotek/workspace/arachni/gfx/
    conf: /home/zapotek/workspace/arachni/conf/
    logs: /home/zapotek/workspace/arachni/logs/
    data: /home/zapotek/workspace/arachni/data/
    modules: /home/zapotek/workspace/arachni/modules/
    reports: /home/zapotek/workspace/arachni/reports/
    plugins: /home/zapotek/workspace/arachni/plugins/
    path_extractors: /home/zapotek/workspace/arachni/path_extractors/
    lib: /home/zapotek/workspace/arachni/lib/arachni/
    mixins: /home/zapotek/workspace/arachni/lib/arachni/mixins/
    arachni: /home/zapotek/workspace/arachni/lib/arachni
  datastore: {}

  redundant: {}

  obey_robots_txt: false
  depth_limit: -1
  link_count_limit: -1
  redirect_limit: 20
  lsmod: []

  lsrep: []

  http_req_limit: 20
  mods: []

  reports:
    stdout: {}

  exclude: []

  exclude_cookies: []

  exclude_vectors: []

  include: []

  lsplug: []

  plugins: {}

  rpc_instance_port_range:
  - 1025
  - 65535
  load_profile:
  restrict_paths: []

  extend_paths: []

  custom_headers: {}

  min_pages_per_instance: 30
  max_slaves: 10
  url: __URL__
  user_agent: Arachni/v0.4.1dev
  audit_links: true
  audit_forms: true
  audit_cookies: true
  start_datetime: 2012-07-14 02:08:48.019416 +03:00
  cookies: {}

  finish_datetime: 2012-07-14 02:08:49.155443 +03:00
  delta_time: 1.136027072
plugins:
  content_types:
    :results:
      image/png:
      - :url: __URL____sinatra__/404.png
        :method: GET
        :params:
    :name: Content-types
    :description: |-
      Logs content-types of server responses.
                      It can help you categorize and identify publicly available file-types
                      which in turn can help you identify accidentally leaked files.
    :author: Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    :version: 0.1.4
    :options:
    - !ruby/object:Arachni::Component::Options::String
      default: text
      desc: Exclude content-types that match this regular expression.
      enums: []

      name: exclude
      required: false
  profiler:
    :results: []

    :name: Profiler
    :description: |-
      Examines the behavior of the web application gathering general statistics
                      and performs taint analysis to determine which inputs affect the output.

                      It does not perform any vulnerability assessment nor does it send attack payloads.
    :author: Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    :version: 0.1.5
  resolver:
    :results: {}

    :name: Resolver
    :description: Resolves vulnerable hostnames to IP addresses.
    :author: Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    :tags:
    - ip address
    - hostname
    :version: 0.1.1
  healthmap:
    :results:
      :map:
      - :safe: __URL__
      - :safe: __URL__1
      - :safe: __URL__2
      - :safe: __URL__3
      - :safe: __URL__4
      - :safe: __URL____sinatra__/404.png
      - :safe: __URL__5
      - :safe: __URL__6
      :total: 8
      :safe: 8
      :unsafe: 0
      :issue_percentage: 0
    :name: Health map
    :description: Generates a simple list of safe/unsafe URLs.
    :author: Tasos "Zapotek" Laskos <tasos.laskos@arachni-scanner.com>
    :version: 0.1.3
sitemap:
- __URL__
- __URL__1
- __URL__2
- __URL__3
- __URL__4
- __URL____sinatra__/404.png
- __URL__5
- __URL__6
start_datetime: Sat Jul 14 02:08:48 2012
version: 0.4.1dev
