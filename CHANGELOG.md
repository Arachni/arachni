# ChangeLog

## _Under development_

- Executables:
    - Added
        - `arachni_restore` (`UI::CLI::RestoredFramework`)
            - Restores snapshots of suspended scans.
            - Prints snapshot metadata.
        - `arachni_report` (`UI::CLI::Report`)
            - Creates reports from `.afr` files.
    - `arachni` (`UI::CLI::Framework`)
        - `Ctrl+C` (`SIGINT`) now aborts the scan.
        - Hitting `Enter` now toggles between the progress message and the
            command screens.
        - Updated to provide access to the new suspend-to-disk feature.
        - Moved reporting functionality to `arachni_report`.
- `Framework`
    - `#audit_page` -- Updated to perform DOM/JS/AJAX analysis on the page and
        feed DOM page snapshots and new paths back to the `Framework`.
- Added `State` -- Stores and provides access to the system's state.
    - `Plugins` -- Stores plugin runtime states when suspending.
    - `HTTP` -- Stores client headers and cookies.
    - `Audit` -- Stores audit operations.
    - `ElementFilter` -- Stores seen elements.
    - `Framework` -- Stores the `Framework` state.
        - `RPC` -- Stores the `RPC::Server::Framework` state.
- Added `Data` -- Stores and provides access to the system's data.
    - `Issues` -- Stores logged `Issue` objects.
    - `Plugins` -- Stores plugin results.
    - `Framework` -- Stores the `Framework` audit workload.
        - `RPC` -- Stores the `RPC::Server::Framework` audit workload.
- Added `Snapshot`
    - Dumps and loads `State` and `Data` to and from disk to suspend and restore
        active scans.
- Removed the `Spider`.
    - The Framework has grown to encompass a process providing the same
        functionality as a result of `Browser` analysis.
- `Element`
    - Cleaned up initializers.
        - Now passed a single Hash argument with configuration options.
    - Added `GenericDOM`
        - Provides an interface similar to traditional elements in order for
            generic DOM elements to be logged and assigned as vectors to issues.
    - `Form`
        - Added `#dom` pointing to a `Auditable::DOM` object handling browser-based
            form submissions/audits.
    - `Link`
        - Added `#dom` pointing to a `Auditable::DOM` object handling browser-based
            link submissions/audits.
    - `Cookie`
        - Added `#dom` pointing to a `Auditable::DOM` object handling browser-based
            cookie submissions/audits.
    - `Capabilities::Auditable`
        - Removed `#use_anonymous_auditor`
        - `#auditable` => `#inputs`
        - `#orig` => `#default_inputs`
        - `#opts` => `#audit_options`
        - `#audit` - Callback now get passed the HTTP response and element mutation
            instead of response, audit options and mutation -- options can now be
            accessed via the element's `#audit_options` attribute.
        - Added `DOM` -- To handle DOM submission/auditing of elements.
        - Split into the following `Capabilities`:
            - `Analyzable`
                - `Timeout`
                    - General refactoring and code cleanup.
                    - Updated the algorithm to ensure server responsiveness before each phase.
                - `RDiff` => `Differential`
                - `Taint`
            - `Submitable`
            - `Inputable`
- `RPC::Server`
    - `Dispatcher`
        - `#dispatch` -- Returns `false` when the pool is empty as a signal to check
            back later.
    - `Instance`
        - Removed `#output`.
    - `Framework`
        - Removed `#output`.
        - `#progress` -- Removed `:messages`.
- `HTTP` expanded to be a complete wrapper around Typhoeus, providing:
    - `Headers`
    - `Message`
    - `Request`
    - `Response`
    - `Client`
        - `#request` options:
            - `:params` => `:parameters`
            - `:async` => `:mode` (with values of `:async` and `:sync`)
            - Added `:http_max_response_size`.
    - `ProxyServer` -- Moved the proxy server out of the `Proxy` plugin and
        updated it to work with `Arachni::HTTP` objects.
- `Browser` -- Real browser driver providing DOM/JS/AJAX support.
- `BrowserCluster` -- Maintains a pool of `Arachni::Browser` instances
    and distributes the analysis workload of multiple resources.
- `Page`
    - Cleaned-up attributes.
    - Attributes (`#links`, `#forms`, `#paths` etc.) are lazy-parsed on-demand.
    - Added:
        - `#response` -- Associated `HTTP::Response`.
        - `#dom` -- Associated `Arachni::Page::DOM`.
- `Page::DOM` -- Static DOM snapshot as computed by a real browser.
- `Parser` -- Updated to **only** operate under the context of the
    `HTTP::Response` with which it was initialized -- no longer supports parsing
    data from external sources.
- `Options` -- Rewritten with renamed option names and grouped relevant options together.
- `AuditStore`
    - `#save` -- Updated to store a compressed `Marshal` dump of the instance.
    - `.load` -- Updated to load the new `#save` format.
- `Component::Options` -- Refactored initializers and API.
- Reports
    - Removed `metareport`.
- Plugins
    - `resolver` -- Removed as the report now contains that information in the
        responses associated with each issue.
    - `proxy`
        - Updated to use `HTTP::ProxyServer`.
    - `autologin`
        - `params` option renames to `parameters`.
        - Changed results to include `status` (`Symbol`) and `message` (`String`)
            instead of `code` (`Integer`) and `msg` (`String`).
    - `content_types`
        - Renamed `params` in logged results to `parameters`.
- Path extractors
    - Added:
        - Extract partial paths from HTML comments (`comments`).
        - `script` - Extract partial paths from scripts.
- Moved all Framework components (`modules`, `plugins`, `reports`, etc.)
    under `components/`.
- Renamed `modules` to `checks`, also:
    - _Audit_ checks renamed to _Active_ checks.
    - _Recon_ checks renamed to _Passive_ checks.
- Checks
    - Active
        - New
            - `xss_dom` -- Injects HTML code via DOM-based links, forms and cookies.
            - `xss_dom_inputs` -- Injects HTML code via orphan text inputs with
                associated DOM events.
            - `xss_dom_script_context` -- Injects JavaScript code via DOM-based
                links, forms and cookies.
        - `xss` -- Added support for Browser-based taint-analysis.
        - `xss_script_context` -- Added support for Browser-based taint-analysis.
            - Renamed from `xss_script_tag`.

## 0.4.6 _(January 1, 2014)_

- CLI user interfaces
    - `--lsmod`
        - Longer pauses every 3 modules, it lists all of them at once.
        - Updated to show the _Severity_ of the issues the module logs.
    - `Ctrl+C` screen optimized to use less resources when printing scan data.
- Options
    - `--cookie-string` -- Updated to also handle cookies in the form of `Set-Cookie` headers.
    - Added:
        - `--external-address` -- The external address of a Dispatcher.
        - `--http-queue-size` -- Maximum amount of requests to keep in the queue,
            bigger size means better scheduling and better performance, smaller
            means less RAM consumption.
- `Session`
    - `#ensure_logged_in` -- Retry on login failure.
- `Spider`
    - Don't apply scope restrictions to the seed URL.
- `Framework`
    - Audit
        - Stored pages are now offloaded to disk to lower RAM consumption.
- `Trainer`
    - `#push` -- Prints verbose messages in cases of scope violations.
- `HTTP`
    - Maximum request-queue size lowered from 5000 to 500, to decrease RAM usage
        by preventing the storage of large amounts of requests for extended periods of time.
    - Updated to use the new `Support::Signature` class for custom-404 signatures.
- `RPC::Server::Dispatcher`
    - Now supports specifying an external address to allow for deployments behind NATs.
- `Element::Capabilities::Auditable::RDiff`
    - Updated to use the new `Support::Signature` class to perform response body comparisons.
    - Updated the algorithm to use a `false` as the control.
    - Added integrity check for the analysis process.
    - Optimized scheduling of data gathering.
    - Reduced total amount of performed requests.
    - Massively reduced RAM consumption for data storage and analysis.
- `Element::Capabilities::Auditable::Timeout`
    - Updated the algorithm to use an approximated web application processing
        time instead of the HTTP timeout based on the total request-response process.
    - Made analysis corruption checks more stringent to diminish the chances of
        false positives.
    - Fixed bug causing non-vetted inputs to reach the final stages of analysis
        which sometimes resulted in false positives.
    - Added a cool-off period after Phase 2 to ensure webapp responsiveness post-attack.
    - Improved status messages.
- `Element::Capabilities::Auditable::Taint`
    - Added longest-word-optimization -- Checks if the longest word of a regexp
        exists in the response body prior to matching the full-blown regexp.
- `Element::Capabilities::Auditable#audit`
    - Added option `:skip_like`, accepting blocks used to filter the mutations
        about to be audited.
    - Fixed bug causing audits with constantly changing tokens to fail.
    - Updated to use `#each_mutation` instead of `#mutations`.
- `Element::Capabilities::Mutable`
    - Added `#each_mutation` to generate mutations on the fly instead of relying
        on `#mutations` to generate an array of mutations.
    - Updated `#mutations` to delegate to `#each_mutation`.
- `Element::Cookie#encode`
    - Allow `=` to remain un-encoded in the cookie value.
- `Element::Form` -- Buttons are now treated as inputs as well.
- `Options#load` -- Updated to support serialized `Hash` objects.
- Added `Support::Signature` -- Signature class used to generate and refine signatures
    from `String` objects.
- Modules
    - Audit
        - `path_traversal` -- Updated to use double-slashes for *nix payloads.
        - `file_inclusion` -- Added evasive payloads using '\'.
        - `source_code_disclosure`
            - Increased coverage by following the directory tree of each file one
                level at a time.
        - `xss_script_tag` -- Updated to check for the existence of encoding operations.
        - `sqli`
            - Updated to cache the compiled regular expressions.
            - Updated to use the longest-word-optimization of the taint analysis
                implementation for faster analysis.
        - `sqli_blind_rdiff`
            - Massively reduced injected payloads.
        - `os_cmd_injection_timing` -- Decreased the time delay.
    - Recon
        - `localstart_asp`
            - Check for an ASP platform instead of a Windows one.
            - Fixed `LocalJumpError`.
- Plugins
    - `autologin`
        - Changed `print_bad` to `print_error` so that errors are written to the
            error log.
        - Scan remains paused and awaits user action upon failure.
    - `proxy`
        - Updated request URL encoding to handle malformed URLs.
        - Disabled reverse DNS lookup on requests to increase performance.
    - `content_types` -- Moved out of `defaults/'.
    - `cookie_collector`
        - Added `filter` option used to determine which cookies to log based on
            a pattern matched against cookie names.
- Reports -- Added `content_type` to all reports with `outfile` option in `.info`.
    - `xml` -- Escaped parameter values in XML report.

## 0.4.5.2 _(September 18, 2013)_

- `gemspec`
    - Added `bundler` as a runtime dependency.
- Path extractors
    - Removed:
        - `comments` -- Extracts partial paths from HTML comments.
            - Could cause infinite crawls, pending further research.

## 0.4.5.1 _(September 14, 2013)_

- `Element::Capabilities::Auditable::Taint`
    - Fixed bug appearing when modules don't have per-platform payloads.

## 0.4.5 _(September 12, 2013)_

- `Element::Capabilities::Auditable::Taint`
    - Patterns can now be per-platform which results in improved fingerprinting
        during the audit phase and less CPU stress when analyzing responses.
- Modules
    - Audit
        - Path traversal (`path_traversal`)
            - Updated `/etc/passwd` signatures to be more generic.
            - Updated MS Windows payloads to include dot truncation.
            - Detection patterns organized per platform.
            - Moved non-traversal payloads to the `file_inclusion` module.
        - SQL Injection (`sqli`)
            - Added support for:
                - Firebird
                - SAP Max DB
                - Sybase
                - Frontbase
                - IngresDB
                - HSQLDB
                - MS Access
        - OS command injection (`os_cmd_injection`)
            - Detection patterns organized per platform.
        - Added:
            - File inclusion (`file_inclusion`) -- Extracted from `path_traversal`.
                - Uses common server-side files and errors to identify issues.
    - Recon
        - Added:
            - localstart.asp (`localstart_asp`)
                - Checks if `localstart.asp` is accessible.
- Plugins
    - Added:
        - Uncommon headers (`uncommon_headers`) -- Logs uncommon headers.
- Path extractors
    - Added:
        - Extract partial paths from HTML comments (`comments`).

## 0.4.4 _(August 10, 2013)_

- Options
    - Added:
        - `--http-username` -- Username for HTTP authentication.
        - `--http-password` -- Password for HTTP authentication.
- `Element::Capabilities::Auditable::RDiff` -- Optimized and improved accuracy
    of analysis.
- Reports
    - HTML -- Fixed display of untrusted issues.
- Modules
    - Recon
        - Added:
            - X-Forwarded-For Access Restriction Bypass (`x_forwarded_for_access_restriction_bypass`)
                - Retries denied requests with a `X-Forwarded-For` header
                  to try and trick the web application into thinking that the
                  request originates from `localhost` and checks whether the
                  restrictions were bypassed.
            - Form-based upload (`form_upload`)
                - Flags file-upload forms as they require manual testing.
        - .htaccess LIMIT misconfiguration (`htaccess_limit`)
            - Updated to use verb tampering as well.
    - Audit
        - Added:
            - Source code disclosure (`source_code_disclosure`)
                - Checks whether or not the web application can be forced to
                    reveal source code.
            - Code execution via the php://input wrapper (`code_execution_php_input_wrapper`)
                - It injects PHP code into the HTTP request body and uses the
                php://input wrapper to try and load it
        - Blind SQL Injection (Boolean/Differential analysis) (`sqli_blind_rdiff`)
            - Improved accuracy of results.
        - Path traversal (`path_traversal`)
            - Severity set to "High".
            - Updated to start with `/` and go all the way up to
                `/../../../../../../`.
            - Added fingerprints for `/proc/self/environ`.
            - Improved coverage for MS Windows.
        - Remote file inclusion (`rfi`)
            - Updated to handle cases where the web application appends its own
                extension to the injected string.

## 0.4.3.2 _(July 16, 2013)_

- Plugins
    - Proxy -- Fixed bug causing it to ignore the shutdown URL.

## 0.4.3.1 _(July 14, 2013)_

- `Session#find_login_form` -- Stores cookies set by the page containing the login form.
- Plugins
    - AutoLogin -- All responses now update the framework cookies.
    - Proxy -- Fixed out-of-scope error for `TemplateScope` helper class.
- Modules
    - Audit
        - Path traversal (`path_traversal`)
            - Added more fingerprints for `/etc/passwd`.

## Version 0.4.3 _(July 06, 2013)_

- RPC protocol
    - YAML serialization switched from `Syck` to `Psych` (the current Ruby default).
- Executables:
    - Added `arachni_multi`
        - Spawns and controls an `RPC::Server::Instance` process in order to
            provide access to RPC-only features such as multi-Instance scans
            **without** requiring a Dispatcher.
- CLI
    - Added platform fingerprinting options:
        - `--lsplat` -- Lists all available platforms.
        - `--no-fingerprinting` -- Disables platform fingerprinting.
        - `--platforms` -- Allows for user specified platforms.
    - RPC client
        - Added the `--grid-mode` option to allow the user to choose between:
            - Load-balancing -- Slaves will be provided by the least burdened
                Grid Dispatchers.
            - Load balancing **with** line-aggregation -- In addition to balancing,
                slaves will all be from Dispatchers with unique bandwidth Pipe-IDs
                to result in application-level line-aggregation.
- Added modular `Page` fingeprinting, via `fingerprinter` components, identifying:
    - Operating systems
        - BSD
        - Linux
        - Unix
        - Windows
        - Solaris
    - Web servers
        - Apache
        - IIS
        - Nginx
        - Tomcat
        - Jetty
    - Programming languages
        - PHP
        - ASP
        - ASPX
        - JSP
        - Python
        - Ruby
    - Frameworks
        - Rack
- `HTTP`
    - `Accept-Encoding` set to `gzip, deflate` by default.
- `Parser`
    - Now fingerprints the pages it returns.
- `Framework`
    - Removed the following deprecated aliases:
        - `:resume!` -- Only use `resume` from now on.
        - `:pause!` -- Only use `pause` from now on.
        - `:clean_up!` -- Only use `clean_up` from now on.
    - Added `#list_platforms`.
- `Spider`
    - Optimized path de-duplication.
    - Paths-list synchronized using a `Mutex` to prevent issues when running as
        part of a multi-Instance operation.
- `RPC::Server::Instance`
    - Removed the following deprecated aliases:
        - `:shutdown!` -- Only use `shutdown` from now on.
    - Added preliminary support for UNIX sockets.
    - Added `#list_platforms`.
- `Module::Auditor`
    - Having access to the `Framework` is now required and guaranteed.
- `Element::Capabilities::Auditable`
    - Out of scope elements are now visible in order to allow access to 3rd
        party resources like Single Sign-On services.
    - All audit methods return `false` when the element is out of the scan's scope.
    - `#anonymous_auditor` now instantiates a `Framework`.
    - Added `#skip_like` method to be passed blocks deciding what elements should
        not be audited.
    - `#audit`
        - Updated to support the following payload types:
            - `Array` -- Array of payloads to be injected.
            - `Hash` -- Array of payloads to be injected per platform.
- Grid
    - `RPC::Server::Dispatcher#dispatch`
        - When the Dispatcher is a Grid member, it returns an Instance from the least
            burdened Grid member by default, thus allowing for easy load-balancing.
- Multi-Instance scans
    - Instances now communicate via UNIX domain sockets when all of them are on
        the same host, to avoid TCP/IP overhead for IPC.
    - `RPC::Server::Instance#scan`
        - Added `grid_mode` option:
            - `:balance` -- Slaves will be provided by the least burdened
                Grid Dispatchers.
            - `:aggregate` -- In addition to balancing, slaves will all be from
                Dispatchers with unique bandwidth Pipe-IDs to result in
                application-level line-aggregation.
    - `RPC::Server::Framework`
        - No longer performs a multi-Instance scan when its Dispatcher is a Grid
            member. The `grid` or `grid_mode` options need to be set explicitly,
            along with a `spawns` option value of 1 and higher.
        - General code cleanup.
            - Multi-Instance code moved under the `RPC::Server::Framework::MultiInstance`
                module which concentrates multi-Instance code and pulls in the
                following modules:
                - `RPC::Server::Framework::Slave` -- Holds API and utilities for
                    slave instances.
                - `RPC::Server::Framework::Master` -- Holds API and utilities for
                    master instances.
        - Master seed crawl runs in its own thread to avoid blocking during the
            initial seeding process.
        - Removed the concept of issue summaries -- were used for lightweight
            transmission of issue data for real-time feedback. Instead, full issues
            are being buffered and flushed to the master after each page is audited.
    - `RPC::Server::Framework::Distributor#distribute_elements`
        - Optimized to handle large data sets.
    - `RPC::Server::Spider`
        - Updated buffering strategy to reduce RPC calls.
- Cleaned up and removed `@@` vars from:
    - `Module::Manager`
    - `Module::KeyFiller`
    - `Plugin::Manager`
    - `Parser`
- Moved supporting classes under `Arachni::Support`.
    - `Support::Cache` classes now store `#hash` values of keys to preserve space.
    - Added:
        - `Support::LookUp` namespace to hold look-up optimized data structures with:
            - `Support::LookUp::HashSet` -- Stores hashed items in a `Set`.
            - `Support::LookUp::Moolb` -- Reverse of a Bloom-filter.
        - `Support::Queue::Disk` -- Disk Queue with in-memory buffer.
- Added:
    - `Arachni::Platform` -- Holds resources relevant to platform identification,
        storage, and filtering.
        - `Fingerprinters` -- Namespace under which all fingerprinter
            components reside.
        - `List` - List structure holding applicable platforms for a given WWW resource.
        - `Manager` - Collection of `Lists`s for easy management of platforms of
            different types.
    - `IO#tail` -- Returns a specified amount of lines from the bottom of a file.
    - Process helpers for RPC Instance and Dispatcher servers.
        - `Arachni::Processes::Dispatchers` -- Spawns and kills Dispatchers.
        - `Arachni::Processes::Instances` -- Spawns and kills Instances.
        - `Arachni::Processes::Manager` -- Forks and kills processes.
- RSpec tests
    - Major cleanup, using the aforementioned process helpers to remove duplicate code.
    - Moved supporting components under `spec/support/`.
- Modules
    - Audit
        - `code_injection`
            - Removed `Ruby` payload since it wasn't applicable.
            - Updated to categorize payloads by platform.
        - `code_injection_timing`
            - Code cleanup.
            - Removed `payloads.txt`, payloads are now in the module.
            - Updated to categorize payloads by platform.
        - `os_cmd_injection`
            - Code cleanup.
            - Removed `payloads.txt`, payloads are now in the module.
            - Updated to categorize payloads by platform.
        - `os_cmd_injection_timing`
            - Code cleanup.
            - Removed `payloads.txt`, payloads are now in the module.
            - Updated to categorize payloads by platform.
        - `path_traversal`
            - Code cleanup.
            - Updated to categorize payloads by platform.
        - `sqli_blind_timing`
            - Code cleanup.
            - Split `payloads.txt`, to individual files per platform.
            - Updated to categorize payloads by platform.
    - Recon
        - `html_objects`
            - Updated description.
- Plugins
    - Proxy
        - Out-of-scope pages no longer return a _403 Forbidden_ error but are
            instead loaded, though ignored.
        - Fixed bug causing the `Content-Length` header to sometimes hold an
            incorrect value.
        - Fixed bug causing the control panel to be injected in a loop.
        - Added support for `PUT` and `DELETE` methods.
        - Supports exporting of discovered vectors in YAML format suitable for
            use with the `vector_feed` plugin.
        - Fixed bug with `POST` requests resulting in timed-out connections due
            to forwarding a `Content-Length` request header to the origin server.
    - AutoLogin
        - Updated to allow access to out-of-scope resources like Single Sign-On
            services.

## Version 0.4.2 _(April 26, 2013)_

- Options
  - Added ```--https-only``` to disallow downgrades to HTTP when the seed URL uses HTTPS.
  - Added ```--exclude-page``` to exclude pages whose bodies match the given patterns.
  - Added ```--version``` to show version info.
- Updated exceptions thrown by the framework, removed ```Arachni::Exceptions```
    namespace and replaced it with the ```Arachni::Error``` base exception from
    which all component specific exceptions inherit.
- RPC
  - Handlers
      - ```opts``` -- Now presents the ```RPC::Server::ActiveOptions```
           interface which actively configures certain options across multiple system
           components.
      - ```service``` -- Updated with the following convenience methods in order
            to provide a simpler interface for users who don't wish to bother with
            the more specialised handlers (```opts```,```modules```, ```framework```, etc.):
          - ```#errors``` -- Returns the contents of the error log.
          - ```#scan``` -- Configures and runs the scan.
          - ```#progress``` -- Aggregates progress information.
          - ```#busy?``` -- Checks whether the scan is still in progress.
          - ```#pause``` -- Pauses the scan (delegated to ```RPC::Server::Framework#pause```).
          - ```#resume``` -- Resumes the scan (delegated to ```RPC::Server::Framework#resume```).
          - ```#abort_and_report``` -- Cleans up the framework and returns the report.
          - ```#abort_and_report_as``` -- Cleans up the framework and returns the
            result of the specified report component.
          - ```#status``` -- Returns the status of the Instance.
          - ```#report``` -- Returns the scan report as a ```Hash```.
          - ```#report_as``` --  Returns the scan report in one of the available formats (as a ```String```).
          - ```#shutdown``` -- Shuts down the Instance/stops the scan.
      - ```framework``` -- Clients no longer need to call ```framework.clean_up``` unless cancelling a running scan.
  - Protocol -- Now supports both ```Marshal``` and ```YAML``` automatically.
      - ```Marshal``` by default since it's many times faster than ```YAML```.
      - ```YAML``` as an automatic fallback in order to maintain backwards compatibility and ease of integration with 3rd parties.
          - Updated to use the Ruby-default ```Psych``` engine.
  - ```Framework```
      - Updated gathering of slave status -- once a slave is done it reports back to the master.
      - Clean-up happens automatically, clients no longer need to call ```#clean_up``` (like previously mentioned).
      - Slave instances now buffer their logged issues and report them to the Master in batches.
      - ```#issues``` now returns the first variation of each issue to provide more info/context.
  - ```Dispatcher```
      - Added ```#workload_score``` returning the workload score of a Dispatcher as a ```Float```.
      - Workload score calculation no longer uses CPU/RAM resource usage (since
        that data is not available on all platforms) but instead the amount of running
        instances and node weight.
- Trainer -- Added a hard-limit for trainings per page to avoid time-consuming loops.
- Spider
  - Updated to retry a few times when the server fails to respond.
      - Failed requests returned by ```#failures```.
- Framework
  - Updated to retry a few times when the server fails to respond when trying to
        request a page for an audit.
      - Failed requests returned by ```#failures```.
  - The following methods have been updated to enforce scope criteria:
      - ```#audit_page```
      - ```#push_to_page_queue```
      - ```#push_to_url_queue```
- HTTP
  - Fixed corruption of binary response bodies due to aggressive sanitization.
  - Custom-404 page detection updated to:
      - Fallback to a word-difference ratio of the refined responses if straight comparison fails.
      - Keep a limited cache of signatures to lower memory consumption.
- ```Arachni::Element::Capabilities::Auditable```
  - Added ```#use_anonymous_auditor``` to alleviate the need of assigning
    a custom auditor when scripting.
  - Updated ```#submit``` and ```#audit``` to default to ```#use_anonymous_auditor```
    when no auditor has been provided.
- Plugins
  - AutoLogin -- No longer URI escapes the given arguments. [Issue #314]
  - Profiler -- No longer a member of the default plugins.
  - Meta-analysis
      - Timing-attacks: Updated to add a remark to affected issues about the
            suboptimal state of the server while the issue was identified.
      - Discovery: Updated to add a remark to affected issues about the
            extreme similarities between issues of similar type.
  - Removed
      - Manual-verification meta-analysis -- That plugin is now redundant, functionality
        now handled by other components/layers.
- Analysis techniques
  - Taint -- Updated to add remarks for issues that require verification.
  - Timeout -- Updated to dramatically decrease memory consumption and improve reliability/accuracy.
      - No longer schedules element audits for the end of the scan but looks
        for candidates along with the other audit requests.
      - Candidates are verified at the end of each page audit.
      - Makes sure that candidates are deduplicated upon discovery.
      - Added a 3rd phase: Initial candidates which pass verification are verified again.
- Modules
  - General
      - Updated module names along with some descriptions and issue names.
      - Limited the maximum number of issues to 25 for the following recon modules:
          - Captcha
          - CVS/SVN users
          - E-mails
          - HTML-objects
          - Interesting Responses
      - XSS in script tag
          - Requires manual verification -- Arachni can't inspect the JS runtime.
          - Added remark to inform users about the above.
      - Path traversal
            - Added more payloads for Windows.
      - OS command injection
            - Added more payloads for Windows.
  - Added
      - Auto-complete for password form fields.
  - Removed
      - ```xss_uri``` compatibility module.
- Plugin
    - Proxy
        - Added the ```session_token``` option allowing users to restrict access
            to their proxy session using a configurable token.
        - Updated panel and control URLs.
- Reports
    - If a directory has been passed as an ```outfile``` option the
        report will be written under that directory using the default ```outfile```
        value as a filename.
    - Updated report descriptions.
    - Updated to include Issue remarks.
- Issues
    - Added attribute ```remarks``` holding a ```Hash``` of remarks about
        that issue with the entity which made the remark as _key_ and an ```Array```
        of remarks as _value_.
    - Added method ```#add_remark```, allowing new remarks to be added to the ```Issue```.
- Executables
    - ```arachni_script``` -- Updated to expect a single script and pass ARGV along.
    - ```arachni_rpc```
        - Massive code clean-up.
        - Updated to use the new simplified RPC API.
        - Updated to support the new high-performance distribution options.
        - Removed status messages, shows only the issue list.
- Added
  - Cache
      - ```Arachni::Cache::Preference``` -- Performs soft pruning based on a
        preference determined by a given block.
  - Buffer classes
      - ```Arachni::Buffer::Base``` -- Buffer base class.
      - ```Arachni::Buffer::AutoFlush``` -- A buffer implementation which flushes
        itself when it gets full or a number of fill-up attempts is reached between flushes.
- Removed
      - Web User Interface -- The new interface is a
        [project of its own](https://github.com/Arachni/arachni-ui-web) and not
        part of the framework -- will appear in the packages only, not the Gems.

## Version 0.4.1.2 _(November 3, 2012)_
- HTTP
  - Updated the custom 404 detection algorithm to use less memory by storing only
    the hashes of the signatures instead of the signatures themselves.
  - ```cookie_string``` option is now decoded before being parsed into a ```Cookie``` object.
- ```Cookie#expires_to_time``` bugfixed to return ```nil``` if expiry time is "0".
- ```Arachni::URI.cheap_parse``` -- Updated to sanitize the encoding of each parameter name and value individually. [Issue #303]
- Plugins
  - Proxy
      - Fixed regression caused by the Parser requiring the HTTP Response to include the original Request.
      - Fixed SSL interceptor behavior on redirects -- now delegates everything to the user facing Proxy.
- Modules
  - Audit
      - CSRF -- Updated to mark forms with a detected nonce as safe.

## Version 0.4.1.1 _(October 14, 2012)_
- ```Auditor#log``` and ```Auditor#log_remote_file``` bugfixed to pass a Hash of the response headers instead of a String -- also solving another bug causing response bodies not to be logged in the Issues. [Issue #294]
- ```Issue``` -- Response headers are now **always** Hash.
- Reports
  - HTML -- Removed response headers handling code and added the option to not include HTTP response bodies. [Issue #296]
  - XML -- Removed response headers handling code and added the option to not include HTTP response bodies. [Issue #296]
- HTTP debugging output now includes Response data. [Issue #297]
- Executables
  - ```arachni_rpcd_monitor``` -- Laxed standards enforced on the Dispatcher URL argument. [Issue #293]
- Path extractors
  - Added path extractor for the ```area``` HTML tag (```href``` attribute). [Issue #300]

## Version 0.4.1 _(October 2, 2012)_
- License -- Moved from GPLv2 to Apache License Version 2.
- Major refactoring
    - ```Arachni::Parser::Element::Auditable``` and ```Arachni::Module::Auditor```.
        - Moved analysis techniques from ```Auditor``` to ```Auditable``` to enable per element audits and analysis
          in order to increase audit granularity and ease scripting.
        - ```Auditor``` methods now simply iterate over candidate elements and delegate analysis to them.
    - Updated URL normalization methods and added caching to resource intensive parsing operations,
      leading to overall improvements, especially during the initial crawling process. (**New**)
    - Moved from Ruby's URI lib to ```Arachni::URI```. (**New**)
    - Project-wide code clean-up, documentation and style improvements.
    - Replaced ```Set``` with ```Arachni::BloomFilter```, where possible, to keep memory consumption to a minimum and speed up look-up comparisons.
    - Namespace cleanup
        - Moved ```Parser::Element``` classes directly under ```Arachni```;
        - Moved ```Parser::Page``` class directly under ```Arachni```;
        - Moved ```Auditable``` and ```Mutable``` under ```Element::Capabilities```;
        - Added ```Element::Capabilities::Refreshable``` -- refreshes the input values of a link/form;
        - Moved analysis techniques out of ```Analysis``` and directly under ```Element::Capabilities::Auditable```;
        - Added constants for each element directly under the ```Arachni``` namespace to facilitate easy access ( like ```Arachni::Link```, ```Arachni::Form```, etc.)
- Framework - Can be configured to detect logouts and re-login between page audits. (**New**)
- Options
    - Removed
        - ```--http-harvest-last```
    - Added
        - ```--login-check-url``` --  A URL used to verify that the scanner is still logged in to the web application.
        - ```--login-check-pattern``` -- A pattern used against the body of the 'login-check-url' to verify that the scanner is still logged in to the web application.
        - ```--auto-redundant``` -- Ignores a specified amount of URLs with identical query parameter names.
        - ```--fuzz-methods``` -- Audits links, forms and cookies using both ```GET``` and ```POST``` HTTP methods.
        - ```--audit-cookies-extensively``` -- Submits all links and forms of the page along with the cookie permutations.
        - ```--cookie-string``` -- Allows the specification of cookies as a string in the form of: ```name=value; name2=value2```
        - ```--exclude-vectors``` -- Excludes vectors (parameters), by name, from the audit.
        - ```--exclude-binaries``` -- Excludes pages with non text-based content-types from the audit.
- Dispatcher
    - Added modularity by way of support for handler components whose API can be exposed over RPC (under ```rpcd_handlers/```).
- Modules - Every single one has been cleaned up and have had RSpec tests added.
    - Scheduling - Expensive modules are now scheduled to be run after cheaper ones
        of similar type and only audit elements missed by the cheaper ones.
    - API
        - Updated to provide access to running plugins.
        - Updated remote file detection and logging helpers to improve performance and accuracy in case of custom 404s.
        - Audit operations by default follow redirects.
        - Issue de-duplication has been updated to be a lot more aggressive for
            issues discovered by manipulating inputs, variations have been restricted to just 1.
    - Unencrypted password forms -- Checks for non-nil form fields before iterating. [Issue #136]
    - SSN -- Improved regexp and logging. [Issue #170]
    - Insecure cookies -- Logs cookies without the 'secure' flag. (**New**)
    - HttpOnly cookies -- Logs cookies without the 'HttpOnly' flag. (**New**)
    - SQL injection -- Now ignores irrelevant error messages in order to reduce false-positives.
    - XSS -- Improved detection accuracy.
    - RFI -- Added a seed URL without a protocol.
    - Path traversal -- Added seeds with file:// URLs and for Tomcat webapps.
    - Added (**New**)
        - Session fixation
    - Lots of information updates for things such as remedy guidances and references. (Thanks to Samil Kumar)
- Plugins - Every single one has been cleaned up and have had RSpec tests added.
    - AutoLogin
        - Added a mandatory verifier regexp to make sure that the login was successful. (**New**)
        - Now configures the ```Framework``` to be able to detect logouts and re-login during the audit. (**New**)
    - Proxy
        - Fixed typo in code which prevented headers from being properly forwarded which
            resulted in non-existent content-types which prevented proper parsing. [Issue #135]
        - Updated to use the framework HTTP interface instead of Net::HTTP
        - Now injects a handy little control panel into each responce which allows recording of
            login sequences and inspection of discovered pages/elements.
    - VectorFeed -- Reads in vector data from which it creates elements to be audited.
      Can be used to perform extremely specialized/narrow audits on a per vector/element basis.
      Useful for unit-testing or a gazillion other things. (**New**)
    - Script -- Loads and runs an external Ruby script under the scope of a plugin, used for debugging and general hackery. (**New**)
- Extras
    - All modules under <tt>/extras</tt> had to be removed because they distributed GPLv3 licensed content.
- HTTP
    - Improved detection of custom 404 pages.
    - Now accepts a global timeout (```--http-timeout```) in milliseconds.
    - Updated ```#add_on_queue``` hook (called by ```#queue```) which allows HTTP requests to be intercepted and modified before being fired.
    - Fixed burst average requests/second calculation.
    - Implemented a Cookiejar. (**New**)
    - Removed tagging of requests with the system-wide seed.
    - Added a maximum queue size limit -- once the request limit has been reached the queued requests will be fired in order to unload the queue.
    - Added ```#sandbox``` -- isolates the given block from the rest of the HTTP env and executes it.
- Spider -- Re-written, much cleaner design and code. (**New**)
    - Ignores path parameters to avoid infinite loops (like ```http://stuff.com/deep/path;jsessid=deadbeef```).
- Parser
    - Removed clutter by moving parsing of elements into their respective classes (Form, Link, Cookie).
    - Replaced sanitization hacks with Nokogiri's sanitization -- cleaner code, better performance.
    - Form
      - Nonce tokens are being automatically detected and refreshed before submission.
- WebUI
    - Removed the AutoDeploy add-on -- no sense maintaining it since the WebUI is about to be scrapped (and no-one used it anyways).
- Tests
    - Added full test suite using RSpec. (**New**)
- Added
    - ```Arachni::Session``` - Session manager, handling session maintenance, login sequences, log-out detection etc.
    - ```Arachni::URI``` class to handle URI parsing and normalization -- Uses Random Replacement caches to maintain low-latency.
    - ```Arachni::BloomFilter``` class, a ```Hash```-based, lightweight Bloom-filter implementation requiring minimum storage space and providing fast look-ups.
    - ```Arachni::Cache``` classes
        - ```LeastCostReplacement``` -- Least Cost Replacement cache implementation.
        - ```LeastRecentlyUsed``` -- Least Recently Used cache implementation.
        - ```RandomReplacement``` -- Random Replacement cache implementation.
- Executables
    - ```arachni_web_autostart``` -- removed calls to ```xterm``` and ```xdg-open```.
    - ```arachni_script``` -- Pre-loads Arachni's libraries and loads and runs a series of Ruby scripts. (**New**)
    - ```arachni_console``` -- Pre-loads Arachni's libraries and loads and runs an IRB shell with persistent history and tab-completion. (**New**)

## Version 0.4.0.3 _(March 12, 2012)_
- Gemspec -- Updated ```do_sqlite3``` dependency. ( [kost](https://github.com/kost) ) [#166]

## Version 0.4.0.1 _(January 9, 2012)_
- Reports
   - XML -- added missing Issue attributes
- Added draconian run-time exception handling to all components.

## Version 0.4 _(January 7, 2012)_
- RPC Infrastructure (**New**)
   - Dispatcher
      - Dispatchers can now be connected to form a High Performance Grid and share scan workloads.
      - Users can now specify a range of ports to be used for spawned Instances. [Issue #76]
      - Now checks for signal availability before using <em>trap()</em>. (**New**) [Issue #71]
      - Now uses Windows compliant filenames for the logs. (**New**) [Issue #70]
   - Ruby's XMLRPC libraries have been replaced by <a href="https://github.com/Arachni/arachni-rpc">Arachni-RPC</a>,
    a light-weight and high-performance custom client/server RPC implementation.
- Added <em>extras</em> directory holding components that are considered too specialised, dangerous or in some way unsuitable for
    utilising without explicit user interaction. (**New**)
    - Modules
       - Recon
          - SVN Digger dirs -- Finds directories, based on wordlists created from open source repositories (Herman Stevens)
          - SVN Digger files -- Finds files, based on wordlists created from open source repositories (Herman Stevens)
          - RAFT dirs (Herman Stevens)
          - RAFT files (Herman Stevens)
- Framework
   - <em>stats()</em>
      - Fixed bug that caused the <em>current_page</em> to not be refreshed during timing attacks.
      - Fixed bug that caused a less than 100% progress at the end of scans. [Issue #86]
      - If the crawler is limited by link-count it will be taken under consideration.
   - Significantly reduced memory footprint by re-scheduling the consumption of Trainer generated pages.
- User Interfaces
   - WebUI
      - Sinatra
         - Updated to use the light-weight and high-performance <a href="http://code.macournoyer.com/thin/">Thin</a> server.
         - Added <a href="https://github.com/raggi/async_sinatra">async_sinatra</a> to allow for asynchronous responses. (**New**)
      - Added support for HTTP Basic Auth (**New**)
      - Updated screens to provide access to HPG (High Performance Grid) features:
         - Home
            - Added option to enable HPG mode on a per scan basis (**New**)
         - Dispatchers
            - Added node information (Nickname, Pipe ID, Weight, Cost). (**New**)
            - Added neighbour inspection per dispatcher. (**New**)
            - Added log inspection per dispatcher. (**New**)
            - Improved accuracy of instance statuses.
            - Added percentages for memory and CPU usage per instance. (**New**)
         - Instance (scan management)
            - Provides an average of all stats of scanner instances. (**New**)
            - Added per instance progress bars. (**New**)
            - Added per instance statuses. (**New**)
            - Added est. remaining time. (**New**)
         - Settings
            - Added proxy settings. [Issue #74] (**New**)
            - Added settings for restrict and extend paths options. (**New**)
      - Fixed small typo in "Settings" screen. [Issue #62]
      - Reports -- AFR report is now served straight-up to avoid corruption. [Issue #55]
      - Add-ons -- Updated to use the new async libraries.
      - Added help buttons. (**New**)
   - CLI
      - Improved interrupt handler:
         - It now exits in a cleaner fashion and is more obedient.
         - Added est. remaining time. (**New**)
         - Added progressbar. (**New**)
- HTTP client
   - Added support for including custom headers. [Issue #90] (**New**)
   - Refactored in order for all methods to use <em>request()</em>.
   - Bug-fixed cookie preservation.
- Spider
   - spider-first option removed and set to true by default.
   - Added "--depth" parameter. (**New**)
   - Fixed incorrect implementation of the inclusion filters.
   - Now follows "Location" headers directly and bypasses the trainer.
   - Added support for extending the crawl scope with a file that contains newline separated URLs. (**New**) [Issue #67]
   - Added support for restricting the crawl scope with a file that contains newline separated URLs. (**New**)
   - Made more resilient against malformed/non-standard URLs. [Issue #57]
- Parser
   - Encoded URLs with fragments right after the host caused URI.parse to fail. [Issue #66]
   - Auditable elements
      - If there are 2 or more password fields in a form an extra variation is added with
        the same inputs for all passwords in case it's a 'please repeat your password' thing. (**New**) [Issue #59]
- Plugins
   - API -- Added <code>distributable?()</code> and <code>merge()</code> class methods which declare
        if a plug-in can be distributed to all instances when running in Grid mode and merge an array of its own results respectively.
      - Distributable plug-ins:
         - Content-Types
         - Cookie collector
         - Healthmap
         - Profiler
         - AutoThrottle
   - Profiler -- Removed response time logging and moved it to <em>defaults</em>.
   - Proxy -- Fixed bug which caused some headers not to be forwarded. [Issue #64]
   - Discovery (accompanied by appropriate report formatters). (**New**) [Issue #81]
      - Performs anomaly detection on issues logged by discovery modules and warns of the possibility of false positives where applicable.
   - Added the 'defaults' subdirectory which contains plug-ins that should be loaded by default.
   - Added: (**New**)
      - ReScan -- It uses the AFR report of a previous scan to extract the sitemap in order to avoid a redundant crawl.
      - BeepNotify -- Beeps when the scan finishes.
      - LibNotify -- Uses the libnotify library to send notifications for each discovered issue and a summary at the end of the scan.
      - EmailNotify -- Sends a notification (and optionally a report) over SMTP at the end of the scan.
      - Manual verification -- Flags issues that require manual verification as untrusted in order to reduce the signal-to-noise ratio.
      - Resolver -- Resolves vulnerable hostnames to IP addresses.
- Reports
   - HTML report
      - Fixed replay forms to include URL params in the <em>action</em> attribute. [Issue #73]
      - Refactored and broken into erb partials.
      - Organised subsections into tabs. (**New**)
      - HTML responses of logged Issues are now rendered on-demand. [Issue #88]
      - Added graph showing issue trust totals. (**New**)
      - The main issue graph shows trusted and untrusted issues in 2 different series.
      - ALl JavaScript and CSS code is now included in the report for off-line viewing.
      - Removed manual-verification piechart, obsoleted by the trust chart.
      - Replaced Highcharts with jqPlot due to licensing reasons.
      - Removed false-positive reporting -- was causing segfaults on Mac OSX. [Issue #126]
   - Added (**New**)
      - JSON -- Exports the audit results as a JSON serialized Hash.
      - Marshal -- Exports the audit results as a Marshal serialized Hash.
      - YAML -- Exports the audit results as a YAML serialized Hash.
- Heeded Ruby's warnings (<em>ruby -w</em>).
- Modules
   - API
      - Auditor
         - Added helper methods for checking the existence of remote files and directories. (**New**)
         - Added helper methods for issue logging. (**New**)
   - Refactored modules replacing duplicate code with the new helper methods.
   - Audit
      - XSS -- Updated to actually inject an element, parse the HTML response and
        look for that element before logging in order to eliminate false positives. [Issue #59]
      - Path traversal -- Fixed broken regular expressions
      - SQL Injection -- Fixed broken regular expressions
      - XSS Path -- Updated to verify the injection using HTML parsing
      - XSS URI -- Made obsolete and will be removed from future releases -- loads and runs XSS Path instead.
   - Recon
      - Added MixedResource detection module (<a href="http://googleonlinesecurity.blogspot.com/2011/06/trying-to-end-mixed-scripting.html">Reference</a>) (**New**) [Issue #56]
- Meta-Modules
   - Have all been converted to regular plug-ins in order to make distribution across the Grid easier.
- Dependencies
   - Added
      - Arachni-RPC
      - EventMachine
      - EM Synchrony
      - AsyncSinatra
   - Updated
      - Typhoeus => 0.3.3
      - Sys-proctable => 0.9.1
      - Nokogiri => 1.5.0
      - Sinatra => 1.3.1
      - Datamapper => 1.1.0
      - Json => 1.6.1
      - Datamapper SQLite adapter => 1.1.0
      - Net-SSH => 2.2.1
   - Removed
      - Rack-CSRF
      - JSON (Provided by DataMapper)

## Version 0.3 _(July 26, 2011)_
- HTTP client
   - Fixed race condition in timeout options.
- Spider (**New**)
   - Replaced Anemone with a lightweight custom-written spider.
- WebUI
   - Major refactoring.
   - Improved handling of connection errors during scan progress updates.
   - Added support for add-ons. (**New**)
   - Add-ons (**New**)
      - Scan scheduler
      - Auto-deploy -- Automatically converts any SSH enabled Linux box into an Arachni Dispatcher.
   - Fixed bug when IP addresses are used, instead of hostnames, for the Dispatchers.
- Parser
   - Form action attributes are now sanitized using iterative URI decoding.
   - Link variables are extracted before URL sanitization takes place in order to keep values with URL-encoded characters intact.
   - The link variables of any current page's URL are now pushed to 'page.links'.
- Auditor
   - Abstracted the rDiff audit methods from the "Blind (rDiff) SQL Injection" module and moved them in the Auditor.
   - Timing attack technique has been greatly improved and all timing attacks are now scheduled to run at the end of the scan.
- Modules
   - API
      - Added the "redundant()" method -- Allows a module to prevents itself from auditting elements that have been previously logged by other modules.
      - Modules are now passed an instance of the framework.
   - Audit
      - Blind (rDiff) SQL Injection
         - Updated to support all element types (Links, Forms, Cookies, Headers).
         - Optimized using the new "redundant()" method -- It will no longer audit elements that have been previously logged by the 'sqli' or 'sqli_blind_rdiff' modules.
      - OS command injection (timing)
         - Optimized using the new "redundant()" method -- It will no longer audit elements that have been previously logged by the 'os_cmd_injection' module.
      - Code injection (timing)
         - Optimized using the new "redundant()" method -- It will no longer audit elements that have been previously logged by the 'code_injection' module.

## Version 0.2.4 _(July 1, 2011)_
- HTTP
   - Implemented a 10s time-out [Issue #40]
- Command Line Interface
   - The interrupt handler (Ctrl+C) now presents the option to generate reports mid-scan. [Issue #41]
   - Added a counter of timed-out requests in the stats.
- WebUI
   - The "Replay" form's action attribute now contains the full URL, including params. [Issue #38]
   - Fixed path clash that caused the "shutdown" button in the Dispatchers screen not to work. [Issue #39]
   - Fixed mix-up of output messages from different instances. [Issue #36]
   - Added a counter of timed-out requests in "Instance" screens.
- External
    - Metasploit
       - Updated SQL injection exploit module to work with SQLmap 0.9. [Issue #37]
- Reports
   - HTML
      - Fixed yet another error condition occuring with broken encodings. [Issue #31]
- Auditor
   - Timing attacks now have a "control" to verify that the server is indeed alive i.e. requests won't time-out by default.

## Version 0.2.3 _(May 22, 2011)_
- WebUI
   - Added connection cache for XMLRPC server instances to remove HTTPS handshake overhead and take advantage of keep-alive support.
   - Added initial support for management of multiple Dispatchers.
- XMLRPC Client->Dispatch Server
   - Updated to always use SSL [Issue #28]
   - Added per instance authentication tokens [Issue #28]
- Modules
   - Audit
      - Path traversal: added double encoded traversals [Issue #29]
- Reports
   - HTML
      - Fixed "invalid byte sequence in UTF-8" using iconv [Issue #27]
      - Added false positive reporting. Data are encrypted using 256bit AES (with AES primitives encrypted using RSA) and sent over HTTPS. [Issue #30]
   - Metareport
      - Fixed bug caused by not explicitly closed file handle.

## Version 0.2.2.2 _(March 22, 2011)_
- Added "arachni_web_autostart" under bin -- Automatically starts all systems required by the WebUI and makes shutting down everything easier too (Original by: Brandon Potter <bpotter8705@gmail.com>)
- Overrided Nokogiri to revert to UTF-8 when it comes across an unknown charset instead of throwing exceptions
- Dependency versions are now defined explicitly [Issue #23]
- Updated to Sinatra v1.2.1
- HTTP
   - Disabled peer verification on SSL [Issue #19]
   - Replaced callbacks with the new _Observable_ mixin (also updated components to use the new conventions)
- WebUI
   - Plug-in options are preserved [Issue #19]
   - Check-all now skips disabled checkboxes
   - Report info is stored in a database [Issue #19]
   - Reports are now displayed in descending order based on scan completion datetime [Issue #19]
   - Any existing reports will be migrated into the new database [Issue #19]
- XMLRPC service
   - Fixed segfault on forced shutdown when spider-first was enabled
- Plug-ins
   - AutoLogin now registers its results
- Reports -- Added formatters for the AutoLogin [Issue #19] and Profiler plug-ins
   - HMTL
      - Fixed exception on empty issue list
      - Fixed encoding exceptions (cheers to Chris Weber <chris@casaba.com>)
- Path extractors
   - Generic -- fixed error on invalid encoding sequences
- Modules
   - Recon
       - Directory listing -- Now skips non-200 pages because it used to log false positives on redirections
- Plug-ins
   - Added Profiler -- Performs taint analysis (with benign inputs) and response time analysis

## Version 0.2.2.1 _(February 13, 2011)_
- Web UI v0.1-pre (Utilizing the Client - Dispatch-server XMLRPC architecture) (**New**)
   - Basically a front-end to the XMLRPC client
   - Support for parallel scans
   - Report management
   - Can be used to monitor and control any running Dispatcher
- Changed classification from "Vulnerabilities" to "Issues" (**New**)
- Improved detection of custom 404 pages.
- Reports updated to show plug-in results.
- Updated framework-wide cookie handling.
- Added parameter flipping functionality ( cheers to Nilesh Bhosale <nilesh at gslab.com >)
- Major performance optimizations (4x faster in most tests)
   - All modules now use asynchronous requests and are optimized for highest traffic efficiency
   - All index Arrays have been replaced by Sets to minimize look-up times
   - Mark-up parsing has been reduced dramatically
   - File I/O blocking in modules has been eliminated
- Crawler
   - Improved performance
   - Added '--spider-first" option  (**New**)
- Substituted the XMLRPC server with an XMLRPC dispatch server  (**New**)
   - Multiple clients
   - Parallel scans
   - Extensive logging
   - SSL cert based client authentication
- Added modules  (**New**)
   - Audit
      - XSS in event attributes of HTML elements
      - XSS in HTML tags
      - XSS in HTML 'script' tags
      - Blind SQL injection using timing attacks
      - Blind code injection using timing attacks (PHP, Ruby, Python, JSP, ASP.NET)
      - Blind OS command injection using timing attacks (*nix, Windows)
   - Recon
      - Common backdoors    -- Looks for common shell names
      - .htaccess LIMIT misconfiguration
      - Interesting responses   -- Listens to all traffic and logs interesting server messages
      - HTML object grepper
      - E-mail address disclosure
      - US Social Security Number disclosure
      - Forceful directory listing
- Added plugins  (**New**)
   - Dictionary attacker for HTTP Auth
   - Dictionary attacker for form based authentication
   - Cookie collector    -- Listens to all traffic and logs changes in cookies
   - Healthmap -- Generates sitemap showing the health of each crawled/audited URL
   - Content-types -- Logs content-types of server responses aiding in the identification of interesting (possibly leaked) files
   - WAF (Web Application Firewall) Detector
   - MetaModules -- Loads and runs high-level meta-analysis modules pre/mid/post-scan
      - AutoThrottle -- Dynamically adjusts HTTP throughput during the scan for maximum bandwidth utilization
      - TimeoutNotice -- Provides a notice for issues uncovered by timing attacks when the affected audited pages returned unusually high response times to begin with.</br>
           It also points out the danger of DoS attacks against pages that perform heavy-duty processing.
      - Uniformity -- Reports inputs that are uniformly vulnerable across a number of pages hinting to the lack of a central point of input sanitization.

- New behavior on Ctrl+C
   - The system continues to run in the background instead of pausing
   - The user is presented with an auto-refreshing report and progress stats
- Updated module API
   - Timing/delay attacks have been abstracted and simplified via helper methods
   - The modules are given access to vector skipping decisions
   - Simplified issue logging
   - Added the option of substring matching instead of regexp matching in order to improve performance.
   - Substituted regular expression matching with substring matching wherever possible.
- Reports:
   - Added plug-in formatter components allowing plug-ins to have a say in how their results are presented (**New**)
   - New HTML report (Cheers to [Christos Chiotis](mailto:chris@survivetheinternet.com) for designing the new HTML report template.) (**New**)
   - Updated reports to include Plug-in results:
      - XML report
      - Stdout report
      - Text report

## Version 0.2.1 _(November 25, 2010)_
- Major performance improvements
- Major system refactoring and code clean-up
- Major module API refactoring providing even more flexibility regarding element auditing and manipulation
- Integration with the Metasploit Framework via: (**New**)
   - ArachniMetareport, an Arachni report specifically designed to provide WebApp context to the [Metasploit](http://www.metasploit.com/) framework.
   - Arachni plug-in for the [Metasploit](http://www.metasploit.com/) framework, used to load the ArachniMetareport in order to provide advanced automated and manual exploitation of WebApp vulnerabilities.
   - Advanced generic WebApp exploit modules for the [Metasploit](http://www.metasploit.com/) framework, utilized either manually or automatically by the Arachni MSF plug-in.
- Improved Blind SQL Injection module, significantly less requests per audit.
- XMLRPC server (**New**)
- XMLRPC CLI client (**New**)
- NTLM authentication support (**New**)
- Support for path extractor modules for the Spider (**New**)
- Path extractors: (**New**)
   - Generic -- extracts URLs from arbitrary text
   - Anchors
   - Form actions
   - Frame sources
   - Links
   - META refresh
   - Script 'src' and script code
   - Sitemap
- Plug-in support -- allowing the framework to be extended with virtually any functionality (**New**).
- Added plug-ins: (**New**)
   - Passive proxy
   - Automated login
- Added modules: (**New**)
   - Audit
      - XPath injection
      - LDAP injection
   - Recon
      - CVS/SVN user disclosure
      - Private IP address disclosure
      - Robot file reader (in the Common Files module)
      - XST
      - WebDAV detection
      - Allowed HTTP methods
      - Credit card number disclosure
      - HTTP PUT support
- Extended proxy support (SOCKS4, SOCKS4A, SOCKS5, HTTP/1.1 and HTTP/1.0). (**New**)


## Version 0.2 _(October 14, 2010)_

- Improved output.
  - Increased context awareness.
  - Extensive debugging output capabilities.
  - Added simple stats at the end of scans.
- Rewritten HTTP interface.
  - High-performance asynchronous HTTP requests.
  - Adjustable HTTP request concurrency limit.
  - Adjustable HTTP response harvests.
  - Custom 404 page detection.
- Optimized Trainer subsystem.
  - Invoked when it is most likely to detect new vectors.
  - Can be invoked by individual modules on-demand,
      forcing Arachni to learn from the HTTP responses they will cause -- a great asset to Fuzzers.
- Refactored and improved Auditor.
  - No redundant requests, except when required by modules.
  - Better parameter handling.
  - Speed optimizations.
  - Added differential analysis to determine whether a vulnerability needs manual verification.
- Refactored and improved module API.
  - Major API clean up.
  - With facilities providing more control and power over the audit process.
  - Significantly increased ease of development.
  - Modules have total flexibility and control over input combinations,
      injection values and their formating -- if they need to.
  - Modules can opt for sync or async HTTP requests (Default: async)
- Improved interrupt handling
  - Scans can be paused/resumed at any time.
  - In the event of a system exit or user cancellation reports will still be created
      using whatever data were gathered during runtime.
  - When the scan is paused the user will be presented with the results gathered thus far.
- Improved configuration profile handling
  - Added pre-configured profiles
  - Multiple profiles can be loaded at once
  - Ability to show running profiles as CLI arguments
- Overall module improvements and optimizations.
- New modules for:
  - Blind SQL Injection, using reverse-diff analysis.
  - Trainer, probes all inputs of a given page, in order to uncover new input vectors, and forces Arachni to learn from the responses.
  - Unvalidated redirects.
  - Forms that transmit passwords in clear text.
  - CSRF, implementing 4-pass rDiff analysis to drastically reduce noise.
- Overall report improvements and optimizations.
- New reports
  - Plain text report
  - XML report
