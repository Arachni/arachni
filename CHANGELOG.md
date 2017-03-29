# ChangeLog

## 1.5.1 _(March 29, 2017)_

- `config/write_paths.yml` -- Added configurable temporary directory.
- `Parser`
    - `#document` -- Updated to lazy parse the document.
- `Browser`
    - `Javascript`
        - `DOMMonitor` -- Don't track `setInterval()`s since we're not using them.
        - `TaintTracer`
            - `add_trace_to_function()` -- Catch and return on error.
- Path extractors
    - `scripts` -- Fixed `nil` error.
- Plugins
    - `metrics` -- Fixed type error due to race condition.

## 1.5 _(January 31, 2017)_

- Executables
    - `arachni_rpcd_monitor` -- Brought up to date with Dispatcher refactoring.
    - New
        - `arachni_reproduce` -- Reproduces the issues in the given report.
- Options
    - `url` -- Raise error on addresses starting with `127.` because
        PhantomJS 2.1.1 doesn't proxy any loopback connections.
    - `--http-cookie-string` -- Updated to only accept `Set-Cookie` formatted
        cookies instead of `Cookie` ones.
    - `--browser-cluster-job-timeout`
        - Repurposed to apply to communication requests for Selenium rather than
            the entire job.
        - Lowered to `10` seconds.
    - New
        - `--http-authentication-type`
            - `auto` -- Default
            - `basic`
            - `digest`
            - `digest_ie`
            - `negotiate`
            - `ntlm`
        - `--scope-dom-event-limit` -- Limits the amount of DOM events to be
            triggered for each DOM depth.
        - `--daemon-friendly` -- Disables status screen.
- `UI`
    - `CLI`
        - `Framework` -- Trap `USR1` signal and go into a `pry` session for debugging.
- `URI`
    - `.fast_parse` --- Ignore `data:` URIs.
- `HTTP`
    - `ProxyServer`
        - Fixed state of abruptly closed SSL interceptor connections leading to
            frozen browser operations.
        - Added support for configurable concurrency of origin requests to keep
            the amount of `Thread`s low.
        - Added support for `Connection: Upgrade` requests by tunneling WebSocket
            connections.
    - `Client`
        - Added `X-Arachni-Scan-Seed` header that includes the random scan seed.
        - `Dynamic404Handler`
            - Added more training scenarios for when:
                - Dashes are used as routing separators.
                - Directory name prepending and appending is ignored.
            - Updated to not dismiss redirects but follow the location.
- `Browser`
    - Updated engine to PhantomJS 2.1.1.
    - Remove `Content-Security-Policy` to allow the Arachni JS env to run.
    - `#snapshot_id` -- Moved to browser-side `DOMMonitor` for better performance.
    - `#capture` -- Extract query parameters from `POST` requests.
    - `#capture_snapshot` -- Deduplicate based on DOM URL and transitions as well.
    - `ElementLocator` -- Fixed bug causing broken CSS selectors with UTF8 characters.
    - `Javascript`
        - `#dom_elements_with_events`
            - Moved code to browser-side `DOMMonitor`.
            - Updated it to return results in batches, in order to keep RAM
                usage under control when processing large pages with thousands
                of elements with events.
- `BrowserCluster`
    - `Worker`
        - `#run_job` -- Retry 5 times on job time-outs.
- `Element`
    - `Capabilities`
        - `Auditable`
            - New
                - `Buffered` -- Reads audit responses in chunks.
                - `LineBuffered` -- Reads audit responses in chunks of lines.
    - `DOM`
        - `Capabilities`
            - `Submittable`, `Auditable` -- Switched from `Proc` to class methods
                for callbacks, in order to avoid keeping contexts in memory.
- Session -- Allow for a submit input to be specified when the login needs to be
    triggered by clicking it, rather than just triggering the submit event on
    the form.
- REST API
    - Added `GET /scans/:id/summary` to return scan progress data without
        `issues`, `errors` and `sitemap`.
- Report
    - Added `#seed` attribute that includes the random scan seed.
- Plugins
    - New
        - `webhook_notify` -- Sends a webhook payload over HTTP at the end of the scan.
        - `rate_limiter` -- Rate limits HTTP requests.
        - `page_dump` -- Dumps page data to disk as YAML.
    - `proxy` -- `bind_address` default switched to `127.0.0.1`, `0.0.0.0` breaks
        SSL interception on MS Windows.
    - `metrics`
        - Fixed division by 0 error when no requests have been performed.
        - Added:
            - HTTP
                - Request time-outs
                - Responses per second
            - Browser cluster
                - Timed-out jobs
                - Seconds per job
                - Total job time
                - Job count
    - `email_notify`
        - Retry on error.
        - Default to `afr` as a report format.
- Checks
    - Active
        - `xss` -- Only check HTML responses to avoid FPs.
        - `xss_event`
            - Replaced full parsing of responses with SAX.
            - Only check HTML responses to avoid FPs.
        - `xss_script_context`
            - Replaced full parsing of responses with SAX.
            - Only check HTML responses to avoid FPs.
        - `xss_tag`
            - Replaced full parsing of responses with SAX.
            - Only check HTML responses to avoid FPs.
        - `unvalidated_redirect`, `unvalidated_redirect_dom`, `xss`, `xss_dom`,
            `xss_dom_script_context`, `xss_script_context` -- Replaced `Proc`s
                with class methods for `BrowserCluster` job callbacks.
        - `unvalidated_redirect` -- Added prepended payload to the default value.
        - `sql_injection` -- Added more error signatures for HSQLDB, Java and SQLite.
        - `csrf` -- Removed heuristics that try to match tokens based on format;
            now only uses a nonce check.
        - `path_traversal` -- Increased maximum traversals to 8.
    - Passive
        - `backup_files`
            - Ignore media files to avoid FPs when dealing with galleries and the like.
            - Added issue remark explaining how the original resource name was manipulated.
        - `backup_directories` -- Added issue remark explaining how the original
            resource name was manipulated.
        - `xst` -- Run once for each protocol, not just for the first page.
- Path extractors
    - `data_url` -- Extract from all elements, not just links.
- Reporters
    - `xml`
        - Replaced unsupported null-bytes with a placeholder.
        - Made `issues/issue/page/dom/data_flow_sinks/data_flow_sink/frame/line` nil-able.

## 1.4 _(February 7, 2016)_

- Native MS Windows compatibility.
- Options
    - `--http-proxy-type` -- Added `socks5h`, enabling hostname resolution via the proxy.
    - Added
        - Scope
            - `--scope-exclude-file-extensions` -- CSV of file extensions to exclude.
        - Audit
            - `--audit-with-raw-payloads` -- Injects both raw and HTTP encoded payloads.
- `URI` -- Optimized and re-written to completely bypass Ruby's `URI` lib.
- `Plugin::Manager`
    - Run `#prepare` methods of plugins in the Framework thread, ordered by plugin priority.
- `HTTP`
    - `ProxyServer` -- Replaced the previous `WEBrick`-based one with a custom
        written server with support for `keep-alive` and low-overhead SSL interception.
    - `Client`
        - Added default value for `Accept-Language` header.
        - Updated to treat cookie-jar cookies as dumb storage and not encode/decode
            names and values.
        - `Dynamic404Handler` -- Check for excessive amounts of noise during
            custom-404 signature generation and abort if an accurate reading is
            impossible.
- `Page`
    - `DOM`
        - `#restore` -- Don't preload the stored page to avoid stale nonces,
            instead rely solely on browser for caching.
- `Browser`
    - Replaced internal use of `Watir` with direct access to `Selenium`, resulting
        in much better performance and lower CPU utilization.
    - Sped up process spawning,
    - Switched to `Selenium`'s default HTTP client for `WebDriver` communications
        in order to resolve JRuby and MS Windows issues.
    - Added support for tracking event delegation.
    - `#spawn_phantomjs` -- Use a Ruby lifeline process to kill the browser
            if the parent dies for whatever reason.
    - `#fire_event` -- Track changes in timers caused by event triggers to identify
        and wait for effects and transitions.
- `Support`
    - `Signature` -- Optimized signature tokenization, deduplication and compression
        to be less resource intensive when processing large data sets.
    - `Cache` -- Minimized calls to `Base#make_key`.
    - Added
        - `Glob` -- Glob matcher.
- `Session`
    - Added `#check_options`, allowing login scripts to set advanced HTTP request
        options for login checks.
- `REST::Server` -- Added REST API.
- `RPC`
    - `Server`
        - `ActiveOptions#set` -- Allow options to be set during runtime and adjust
            the scan scope accordingly.
- `Element`
    - `UIInput::DOM` -- Updated coverage identifier calculation.
    - `UIForm::DOM` -- Updated coverage identifier calculation.
    - `Capabilities`
        - `Analyzable`
            - `Signature`
                - Replaced `regexp` and `substring` options with `signature` --
                    type of matching depends on `signature` type.
                - Allow `signature` to be generated dynamically based on the
                    `HTTP::Response` about to be checked, from a `#call`able object.
            - `Differential`
                - Abort on partial responses to avoid FPs caused by server stress
                    or Firewall/IDS/IPS.
            - `Timeout`
                - Added one more verification phase to further reduce the possibility
                    of random FPs.
- Checks
    - Active -- Updated all checks that make use of `Element::Capabilities::Analyzable::Signature`
        to provide simple substring signatures whenever possible.
        Alternatively, when a `Regexp` is necessary, they take advantage of dynamic
        signature generation based on the current response and perform a lightweight
        preliminary check for hints of vulnerability, only then is the more
        resource intensive `Regexp` matched.
        - `xss`, `xss_dom`, `xss_tag`, `xss_event`, `xss_script_context` --
            Optimized identification of tainted responses to avoid parsing as
                much as possible.
        - `xss_dom` -- Updated payloads to improve coverage.
        - `sql_injection_differential`
            - Replaced `-1` control `false` value with `-1839`
            - When using quotes, quote all parts of the conditional in the SQL query.
        - `no_sql_injection_differential`
            - Replaced `-1` control `false` value with `-1839`
    - Passive
        - `directory_listing` - Bail out on failed requests to avoid FPs.
        - `backdoors`, `backup_directories`, `backup_files`, `common_admin_interfaces`,
            `common_directories`, `common_files` -- Bail out if the seed resource
            is already a 404.
        - Grep
            - `emails` -- Verify e-mail addresses by resolving the identified domains.
            - `credit_card`, `ssn` -- Mark issues as untrusted by default since
                there's no way to verify SSNs.
            - `http_only_cookies`, `insecure_cookies` -- Only check current page
                cookies, don't let the CookieJar ones sneak in.
            - `insecure_cookies` -- Check JS cookies too.
- Plugins
    - `proxy`
        - Removed injection of control toolbar to each response.
        - Cleaned up control panel design.
        - Updated description to list management URLs and SSL interception info.
    - `email_notify` -- Made username and password optional.
    - `defaults/meta/remedy/`
        - `discovery` -- Updated similarity check to prevent analysis of singular issues.
- Reporters
    - `xml` -- Updated validation messages to point to relevant markup.
- Path extractors
    - `meta_refresh` -- Strip whitespaces from URLs when not in quotes.

## 1.3.2 _(October 19, 2015)_

- `UI`
    - `CLI`
        - Help output
            - Simplified `PATTERN` examples.
            - Replaced `test.com` with `example.com`.
- Browser
    - Configure PhantomJS to accept any SSL version to allow for easier interception.
- `HTTP`
    - `Request`
        - `#body_parameters` -- Added support for `multipart/form-data`.
- `Element`
    - `Form`
        - `.parse_data` -- Parse `multipart/form-data`.
    - `UIForm`
        - `.from_browser` -- Include `<input type="submit">` buttons.


## 1.3.1 _(October 13, 2015)_

- `UI`
    - `CLI`
        - Options
            - `--http-ssl-key` -- Fixed typo causing option to raise error.

## 1.3 _(October 01, 2015)_

- `UI`
    - `CLI`
        - Options
            - `--browser-cluster-local-storage` -- Sets `localStorage` data from JSON file.
- `Issue`
    - `#variations` -- Removed, all issues now include full data.
    - `#unique_id`, `#digest` -- In cases of passive issues, the associated
        `#proof` is now taken into consideration.
- `Data`
    - `Framework`
        - `#update_sitemap` -- Don't push URLs that include the
            `Utilities.random_seed` to the sitemap to keep noise down.
- `Element`
    - `Cookie`
        - `.encode` -- Updated list of reversed characters.
        - `.decode` -- Handle broken encodings.
    - `Form`
        - `.decode` -- Handle broken encodings.
    - `UIForm` -- Audits `<input>` and `<button>` groups which don't belong to
        a `<form>` parent. Also covers cases of `<form>` submissions that occur
        via elements other than a submit button.
    - `UIInput` -- Audits individual `<input>` elements which have associated DOM events.
    - `Capabilities` -- Refactored to allow for easier expansion of DOM capabilities.
        - `Analyzable`
            - `Differential` -- Updated to remove the injected seed from the response
                bodies, echoed payloads can compromise the analysis.
            - `Taint` => `Signature` -- Signature analysis better describes that
                process and the "taint" terminology was overloaded by the browser's
                taint tracing subsystems.
- `Browser`
    - Use the faster, native `#click` event on `Watir` elements, instead of `fire_event`.
    - Sets `localStorage` data from `Arachni::OptionGroups::BrowserCluster#local_storage`.
    - `Javascript`
        - `TaintTracer`
            - Updated sanitization of traced `Event` arguments to extract only
                certain properties instead of iterating through the whole object.
            - Limited the depth of the recursive taint search in argument objects.
- `Components`
    - Path extractors
        - `comments`
            - Small cleanup in acceptable paths.
        - `script`
            - Updated to not get fooled by comment strings (`/*Comment`, `//Comment`).
            - Updated to require absolute paths to avoid processing junk.
    - Reporters -- All reporters have been updated to remove `Issue#variations`.
        - `xml` -- Updated schema to include the new `Element::UIForm::DOM` and
            `Element::Input::DOM` elements.
    - Plugins
        - `proxy` -- Fixed bug causing the plugin to hang after proxy server shutdown.
        - `login_script`
            - Wait for the page to settle when using a JS login script.
            - Catch script syntax errors.
    - Checks
        - Active
            - Removed
                `xss_dom_inputs` -- No longer necessary, covered by new DOM
                    element abstractions and `xss_dom`.
            - `unvalidated_redirect` -- Updated to use `Utilities.random_seed`
                in the injected URL.
            - `unvalidated_redirect_dom` -- Updated to use `Utilities.random_seed`
                in the injected URL.
        - Passive -- Reworked proofs to remove dynamic content which can interfere
            with issue uniqueness or removed proofs altogether when not necessary.

## 1.2.1 _(July 25, 2015)_

- HTTP
    - `ProxyServer`
        - Updated SSL interception to use different interceptors for each host.
        - Shutdown on framework abort, instead of waiting for the user to shutdown
            the proxy manually.
- Checks
    - Passive
        - `backdoors` -- Updated exempt platforms to all Framework platforms.
- Fingerprinters
    - Added
        - Frameworks
            - Nette
            - Symphony

## 1.2 _(July 16, 2015)_

- Switched to Arachni Public Source License v1.0.
- `UI`
    - `CLI::Framework`
        - Fixed timeout enforcement.
        - `OptionParser`
            - Added `--browser-cluster-wait-for-element`.
    - `Output`
        - `#error_log_fd` -- Catch `Errno` system errors (like `Too many open files`)
            to avoid crashing.
- `OptionGroups`
    - `HTTP`
        - `#request_queue_size` -- Lowered from `500` to `100`.
    - `BrowserCluster`
        - `#wait_for_elements` -- Wait for element matching `CSS` to appear when
            visiting a page whose URL matches the `PATTERN`.
        - `#job_timeout` -- Increased from 15 to 25 seconds.
- `Framework`
    - `#pause` -- Pause is now near instant.
    - `#audit` -- Substantially simplified and optimized the consumption of URL
        and page queues.
    - `#audit_page` -- Application of DOM metadata now happens asynchronously
        and uses the `BrowserCluster` instead of an independent `Browser`.
- `HTTP`
    - `Client`
        - Updated cookie setting from `OptionGroups::HTTP#cookies` `Hash`.
        - Trigger garbage collections before and after performing the queued
            requests to prevent large RAM spikes.
        - `Dynamic404Handler`
            - Account for cases where the server returns intermittent errors
                that can lead to signature corruption and possibly false positives.
            - Updated training scenarios for cases where `~` are ignored.
            - Disable platform fingerprinting during the gathering of signatures.
    - `Request`
        - Ignore proxy-related traffic (`CONNECT`) when capturing raw traffic data.
        - Added `#fingerprint` option to enable/disable platform fingerprinting
            on a per request basis.
        - `#response_max_size` -- In addition to setting the `maxfilesize` for
            the `Typhoeus::Request`, stream bodies and manually abort if the
            buffer exceeds the limit -- covers cases where no `Content-Type`
            is set.
    - `Headers`
        - Merge values of headers with identical normalized names (i.e.
            `set-cookie` and `Set-Cookie` in the same response).
        - Cache header name canonicalization.
    - `ProxyServer`
        - Cache header name canonicalization.
        - SSL interceptor now automatically generates certificate/key pairs
            based on Arachni CA.
- `Page`
    - `#has_script?` -- Detect using the body instead of the parsed document.
- `Parser`
    - Optimized to avoid HTML parsing if it contains no indication of elements.
    - `#headers` -- Updated to include headers from the HTTP request in addition
        to common ones.
    - `Extractors` -- Optimized to avoid HTML parsing if it contains no
        indication of elements.
- `Element`
    - Cleaned up per-element input value encoding.
    - Enforce a `MAX_SIZE` on acceptable values during parsing.
    - Optimized to avoid HTML parsing if it contains no indication of elements.
    - `Server`
        - `#log_remote_file_if_exists?` -- Flag issues as untrusted at that point
        if possible, instead of at the end of the scan.
        - `#remote_file_exist?` -- Disable platform fingerprinting when dealing
            with a dynamic handler.
    - `Capabilities`
        - `Inputtable` -- Added cache for `#inputtable_id` calculation.
        - `Analyzable`
            - `Taint` -- Added match cache based on signatures and haystacks.
            - `Timeout` -- Override user audit options that don't play nice with this technique.
- `Check::Auditor`
    - `#log_remote_file` -- Assign `HTTP::Response#status_line` as proof.
- `Issue`
    - `#signature` -- Store `Regexp` source instead of converting it to String.
- `Browser`
    - Updated to extract and whitelist CDNs from response bodies.
    - `#cookies` -- Normalize cookies with quoted values since Watir doesn't take
        care of that bit.
    - `Javascript`
        - `#inject` -- Inject `TaintTracer` and `DOMMonitor` update calls in
            requested JS assets.
        - `TaintTracer`
            - Limited data and execution flow sinks to a max size of 50 entries.
            - Don't trace functions known to cause issues:
                - Anonymous functions.
                - `lodash()`
        - `DOMMonitor`
            - Keep track of `jQuery` delegated events.
- `Support`
    - `Cache`
        - `RandomReplacement` -- Removed extra key `Array`.
    - `Signature` -- Cache token generation.
- Checks -- Added `Issue#proof` to as many issues as possible.
    - Active
        - `xss`
            - When the case involves payloads landing in `textarea`s, break out of
                them to prevent possible FPs.
            - Added double-encoded payloads.
        - `xss_dom_inputs`
            - Don't perform redundant audits.
            - Don't process custom events.
            - Updated to handle cases where a button needs to be clicked after
                filling in the inputs.
            - Added progress messages.
        - `unvalidated_redirect`
            - Escalated severity to 'High'.
            - Only perform straight payload injections.
        - `unvalidated_redirect_dom`
            - Escalated severity to 'High'.
        - `path_traversal`, `file_inclusion`, `os_cmd_injection`, `xxe`
            - Updated `/etc/passwd` content matching pattern.
    - Passive
        - Added
            - `common_admin_intefaces` -- By Brendan Coles.
        - `backdoors`, `backup_directories`, `backup_files`, `common_files`,
            `directory_listing`
            - Added MVC frameworks as exempt platforms since they do their own routing.
- Plugins
    - Added
        - `restrict_to_dom_state` -- Restricts the audit to a single page's DOM
            state, based on a URL fragment.
        - `metrics` -- Captures metrics about multiple aspects of the scan and
            the web application.
    - `autologin` -- Updated to fail gracefully in cases of an invisible form DOM elements.
    - `login_script` -- Added support for Javascript login scripts.
    - `proxy`
        - Updated to show JSON and XML inputs in the inspection page.
        - Added output message with instructions for server that use SSL.
    - `vector_feed` -- Updated to support XML and JSON elements.
- Reporters
    - `xml`
        - Fixed bug causing vector `affected_input_name` to be blank.
- Fingerprinters -- Optimized across the board to prefer less resource intensive checks.
    - Frameworks
        - Rack -- Expanded signatures.
    - Languages
        - JSP renamed to Java and expanded signatures.
        - PHP -- Expanded signatures.
        - Python -- Expanded signatures.
    - Servers
        - Tomcat -- Expanded signatures.
    - Added
        - Frameworks
            - Django
            - Rails
            - ASP.NET MVC
            - CakePHP
            - JSF
            - CherryPy
        - Servers
            - Gunicorn
- Path extractors
    - Added
        - `data_url` -- Extracts paths from `data-url` attributes of `a` tags.

## 1.1 _(May 1, 2015)_

- `gemspec` -- Require Ruby >= 2.0.0.
- Options
    - `--authorized-by` -- Fixed expected type (`Integer` => `String`).
    - HTTP
        - `request_timeout` -- Lowered from 50 to 10 seconds.
        - `response_max_size` -- Set to 500KB.
    - BrowserCluster
        - `job_timeout` -- Lowered from 120 to 15 seconds.
    - Scope
        - `dom_depth_limit` -- Lowered from 10 to 5.
    - Added:
        - Audit
            - `--audit-parameter-names` -- Injects payloads into parameter names.
            - `--audit-with-extra-parameter` -- Injects payloads into an extra parameter.
        - HTTP
            - `--http-ssl-verify-peer` -- Verify SSL peer.
            - `--http-ssl-verify-host` -- Verify SSL host.
            - `--http-ssl-certificate` -- SSL certificate to use.
            - `--http-ssl-certificate-type` -- SSL certificate type.
            - `--http-ssl-key` -- SSL private key to use.
            - `--http-ssl-key-type` -- SSL key type.
            - `--http-ssl-key-password` -- Password for the SSL private key.
            - `--http-ssl-ca` -- File holding one or more certificates with which to verify the peer.
            - `--http-ssl-ca-directory` -- Directory holding multiple certificate files with which to verify the peer.
            - `--http-ssl-version` -- SSL version to use.
- `URI`
    - Added `#resource_name`.
    - Added `.full_and_absolute?`.
    - `Scope`
        - `#redundant?` -- No longer updates counter by default.
        - `#auto_redundant?`
            - No longer updates counter by default.
            - Only consider URLs with query parameters.
- `HTTP`
    - `Client`
        - Overhauled custom-404 identification and moved to `Dynamic404Handler`.
- `Framework`
    - `Parts`
        - `Data`
            - `#push_to_page_queue` -- Update redundancy scope counters.
            - `#push_to_url_queue` -- Update redundancy scope counters.
        - `Audit`
            - `#audit_page`
                - Apply DOM metadata to pages not originated from `Browser#to_page`.
        - `Browser`
            - Added utility `#browser`.
            - Added `#use_browsers?`, determining whether system options and
                capabilities allow for browsers to be used.
            - `#wait_for_browsers?` => `#wait_for_browser_cluster?`
- `Element`
    - All
        - Renamed `#html` to `#source`.
        - Moved element-specific capabilities to their own files.
    - `Cookie`
            - `.encode` -- Encode `=` even when in value.
    - `JSON` -- Represents JSON input vectors.
    - `XML` -- Represents XML input vectors.
    - `Form`
        - Support forms with multiple values for `submit` inputs with sa
        me names.
    - `Server`
        - `#log_remote_file_if_exists` -- Perform some rudimentary meta-analysis
            on possible issues and only feed the identified resources back to the
            system if they are above a certain threshold of similarity.
            This fixes infinite loop scenarios when dealing with unreliable
            custom-404 fingerprints.
    - `Capabilities`
        - `Mutable`
            - `:param_flip` => `:parameter_names`
            - Added `:parameter_values` option.
            - Added `:with_extra_parameter` option.
        - `Analyzable`
            - `Timeout`
                - Updated algorithm to be resilient to WAF/IDS/IPS filtering.
                - Added remarks to each issue containing extra information
                    regarding the state of the web application during analysis.
            - `Differential` -- Added remarks to each issue containing extra information
                regarding the used payloads.
            - `Taint`
                - Don't log issues when unable to get a verification response.
                - Provide all matched data as proof, not only the regexp captured ones.
        - `WithDOM`
            - Added `#skip_dom` (set via `Browser#to_page`), to prevent `DOM`s
                from being loaded and audited when there are no associated events.
- `Page`
    - Added `#update_metadata`, updating `#metadata` from `#cache` elements.
    - Added `#reload_metadata`, updating `#cache` elements from `#metadata`.
    - Added `#import_metadata`, importing `#metadata` from other page.
    - `DOM`
        - `#restore` -- Added debugging messages.
- `Utilities`
    - Added `.full_and_absolute_url?`.
- `Browser`
    - Updated to extract JSON and XML input vectors from HTTP requests.
    - `#cookies` -- Normalize cookies with quoted values since Watir doesn't take
        care of that bit.
    - `#shutdown` -- Fixed Selenium exceptions on dead browser process.
    - `#to_page` -- Apply DOM metadata to page elements.
    - `#spawn_phantomjs` -- Enabled `--disk-cache` option for `phantomjs`.
    - `#fire_event` -- Recode input values to fix encoding errors.
    - `#to_page` -- Return empty page on unavailable response data instead of `nil`.
    - `#snapshot_id` -- Updated to only consider important element attributes
        (depending on type) instead of all of them.
    - `ElementLocator`
        - `#css` -- Returns a CSS locator.
        - `#locate` -- Updated to use `#css`.
    - `Javascript`
        - Added `.select_event_attributes`.
        - `DOMMonitor`
            - `#digest` -- Removed `data-arachni-id` from digest.
        - `TaintTracer`
            - Added support for tracing multiple taints in groups.
            - Added tracing for:
                - `escape()`
                - `unescape()`
                - `String`
                    - `indexOf()`
                    - `lastIndexOf()`
                - `jQuery`
                    - `cookie()` plugin.
- `BrowserCluster`
    - `Worker`
        - `#browser_respawn` -- Catch Watir/Selenium errors.
- `Session`
    - Ensure the browser is shut-down after each login operation.
- `Check`
    - `Auditor`
        - `#each_candidate_dom_element` -- Yield element DOMs instead of parent elements.
- `Plugin`
    - `Manager`
        - `#run` -- Optimized plugin initialization by using a queue to signal
            a ready-state, instead of blocking for 1 second.
-  Checks
    - Active
        - Added
            - `unvalidated_redirect_dom` -- Logs DOM-based unvalidated redirects.
            - `xxe` -- Logs XML External Entity vulnerabilities.
        - `trainer` -- Disabled parameter flip for the payload to avoid parameter
            pollution.
        - `os_cmd_injection` -- Only use straight payload injection instead
            of straight and append.
        - `code_injection` -- Only use straight payload injection instead
            of straight and append.
        - `xss` -- When auditing links don't require a tainted response for
            browser analysis.
        - `xss_script_context`
            - Updated payloads.
            - Only use straight payload injection instead of straight and append.
        - `xss_dom_script_context` -- Only use straight payload injection instead
            of straight and append.
        - `xss_tag` -- Updated payloads to handle cases when more data are appended
            to the landed value.
        - `xss_event` -- Added proof to the issue.
    - Passive
        - Added
            - `insecure_cross_domain_policy_access` -- Checks `crossdomain.xml`
                files for `allow-access-from` wildcard policies.
            - `insecure_cross_domain_policy_headers` -- Checks `crossdomain.xml`
                files for wildcard `allow-http-request-headers-from` policies.
            - `insecure_client_access_policy` -- Checks `clientaccesspolicy.xml`
                files for wildcard domain policies.
            - `insecure_cors_policy` -- Logs wildcard `Access-Control-Allow-Origin`
                headers per host.
            - `x_frame_options` -- Logs missing `X-Frame-Options` headers per host.
            - `common_directories` -- Added:
                - `rails/info/routes`
                - `rails/info/properties`
        - `http_put` -- Try to `DELETE` the `PUT` file.
        - `html_objects` -- Updated regexp to use non-capturing groups.
- Plugins
    - All
        - Updated `#prepare` methods to not block, in accordance with the new
            `Plugin::Manager#run` behavior.
    - `email_notify`
        - Added `domain` option.
        - Fixed extension for `html` reporter.
        - Added support for `afr` report type.
    - `proxy` -- Added XML and JSON input vector extraction.
    - Added:
        - `vector_collector` -- Collects information about all seen input vectors
            which are within the scan scope.
        - `headers_collector` -- Collects response headers based on specified criteria.
        - `exec` -- Calls external executables at different scan stages.
- Report -- Renamed `#html` to `#source` for all elements.
    - `html`
        - Updated chart rendering to only take place when visiting the chart page.
        - Fixed broken links.
        - Cleaned up chart severity handling.
        - Summary
            - Added OWASP Top 10 tab.
    - `xml`
        - Schema update for issue remarks.

## 1.0.6 _(December 07, 2014)_

- `arachni_rpcd` -- Fixed bug causing the `--nickname` option to not be understood.
- `UI::Output` -- Flush output stream after each message.
- `Platform::Manager`
    - Removed 'coldfusion`.
    - Added `sql` and `nosql` parents for DBs.
- `Check::Auditor#skip?` -- Ignore mutations when checking for redundancies.
- `Browser` -- Fixed issue causing `select` inputs in forms to not be set.
- `Element::Cookie.encode` -- Added '&' to the list of reserved characters.
- `Issue`
    - `#recheck` -- Rechecks the existence of the issue.
- `Element::Capabilities`
    - `WithNode`
        - `#html=` -- Recode string before storing.
    - `WithDOM`
        - `#dom` -- Return `nil` on `Inputtable::Error`.
    - `Auditable` -- Updated response analysis messages to include vector type,
        name and action URL.
- `Framework` -- Split into `Parts`:
    - `Audit`
        - If `Options.platforms` are given, checks which don't support them are
            completely skipped.
    - `Browser`
    - `Check`
    - `Data`
        - `#pop_page_from_url_queue` -- Fixed issue causing multiple-choice
            redirections to cause an error.
    - `Platform`
    - `Plugin`
    - `Report`
    - `Scope`
    - `State`
- `State::Framework`
    - Added `#done?`
    - `#abort` -- Fixed exception message.
- Checks
    - Active
        - `sql_injection` -- Slight payload update to catch double-quote cases.
        - `code_injection` -- Slight PHP payload update, to ensure it works in more cases.
        - `code_injection_timing` -- Updated payloads to mirror `code_injection`.
        - `os_command_injection` -- Updated payloads to handle chained commands.
        - `os_command_injection_timing` -- Updated payloads to handle chained commands.
        - `path_traversal` -- Fixed MS Windows output pattern.
        - `sql_injection_differential` -- Set platform to generic `sql`.
        - `no_sql_injection_differential` -- Set platform to generic  `nosql`.
        - `unvalidated_redirect` -- Disable `follow_location`.
    - Passive
        - `common_files` -- Added `.svn/all-wcprops`.

## 1.0.5 _(November 14, 2014)_

- Executables
    - `arachni_console` -- Require the UI::Output interface after Arachni.
- Error log
    - Redacted HTTP authentication credentials.
- `Session`
    - Added `#record_login_sequence`, allowing for arbitrary login sequences to
        be stored and replayed.
- `URI`
   - `#domain` -- Fixed `nil` error on missing host.
   - `.query_parameters` -- Recode query string before parsing to fix encoding errors.
- `UI::Output`
    - `#log_error` -- Store errors in memory, as well as in logfile.
- `RPC::Server::Framework::MultiInstance`
    - `#errors` -- Return errors from memory buffer instead of logfile, to
        prevent "Too many open file" exceptions.
- ` Framework`
    - `#audit_page` -- Keep track of checked elements at the `Framework` level
        too and remove them from pages.
- `Browser`
    - Fixed `nil` error on failed process spawn.
    - `Javascript` -- Updated to preload and cache script sources to avoid
        hitting the disk in order to prevent "Too many open file" exceptions.
        - `#run_without_elements` -- Runs a script but unwraps `Watir` elements.
        - `Proxy` -- Updated to use `#run_without_elements`.
- `BrowserCluster::Worker`
    - Print error message on failure to respawn.
- `Check::Auditor` -- Updated audit helpers to mark elements as audited at the
    check component level, to avoid sending redundant workload to the analysis
    classes only to be ignored there.
    - `#skip?` -- Optimized redundant issue checks.
- Checks
    - Active
        - `no_sql_injection` -- Updated payloads to be per platform.
    - Passive
        - `common_files` -- Added more filenames. [PR #504]
- Plugins
    - Added
        - `login_script` -- Exposes a Watir WebDriver interface to an external
            script in order to allow for arbitrary login sequences.

## 1.0.4 _(October 25, 2014)_

- CLI options
    - Fixed typo causing `--http-authentication-password` to be ignored.
- Executables
    - `arachni_restore` -- Updated to accept timeout options.
- `Browser`
    - Fail with `Browser::Error::Spawn` on unsuccessful process spawn.
- Checks
    - Active
        - `csrf` -- Check for `csrf` substring in input names and values.
    - Passive
        - `backdoors` -- Added more filenames. [PR #492]
        - `common_directories` -- Added ISO 3166-1 Alpha-2 countries. [PR #491]

## 1.0.3 _(October 3, 2014)_

- Added overrides for system write directories in `config/write_paths.yml`.
- `OptionGroups`
    - `Paths`
        - Added `.config` -- Parsing `config/write_paths.yml`.
        - `#logs` -- Can now be set via `.config`.
        - `#snapshots` -- Can now be set via `.config`.
    - `Snapshot`
        - `#save_path` -- Can now be set via `Paths.config`.
- `UI::Output`
    - Moved default error log under `OptionGroups::Paths.logs`.
    - Optimized file descriptor handling.
- `UI::CLI`
    - `OptionParser`
        - Set default report location save-dir from `OptionGroups::Paths.config`.
    - `Framework`
        - Print the error-log location at the end of the scan if there were errors.
- `Framework`
    - Use `OptionGroups::Scope#extend_paths` to seed the crawl.
- `Browser`
    - `ElementLocator.supported_element_attributes_for`
        - Fixed `nil`-error when dealing with unknown attributes.
    - Added `:ignore_scope` option, allowing the browser to roam completely
        unrestricted.
    - Capped `setTimeout` waiting period to `OptionGroups::HTTP#request_timeout`.
    - Fixed issue resulting in multiple cookies with the same name being sent
        to the web application.
    - Assigned unique custom IDs to DOM elements without ID attributes.
- `BrowserCluster`
    - Spawn browsers in series instead of in parallel to make it easier on
        low resource systems.
- `Session`
    - Fallback to `Framework` DOM Level 1 handlers when no `Browser` is available.
    - When `OptionGroups::Scope#dom_depth_limit` is 0 don't use the `Browser`.
    - Configured its `Browser` with `:ignore_scope` to allow for SSO support.
    - `#logged_in?` -- Follow redirections for login check HTTP request.
- `Element`
    - `Cookie`
        - Added `#data` -- Providing access to raw cookie data.
    - `Capabilities`
        - `Analyzable`
            - `Differential` -- Forcibly disable `OptionGroups::Audit#cookies_extensively`.
            - `Timeout` -- Forcibly disable `OptionGroups::Audit#cookies_extensively`.
        - `Mutable`
            - `#each_mutation` -- Removed obsolete method-switch with default inputs.
- Plugins
    - `uncommon_headers`
        - Added `keep-alive` and `content-disposition` in the common list.
        - Ignore out-of-scope responses.
    - `content_types`
        - Ignore out-of-scope responses.
    - `cookie_collector`
        - `Set-Cookie` header is now always an `Array`.
    - `autologin`
        - Don't modify `OptionGroups::Session` (login-check) options if already set.

## 1.0.2 _(September 13, 2014)_

- `UI::Output` -- Updated null output interface with placeholder debugging methods.
- `Browser`
    - Updated to catch exception when trying to manipulate read-only inputs.
- `BrowserCluster`
    - Added debugging messages for job processing.
    - `Worker`
        - `#run_job` -- Clear the `@window_responses` cache after each job in
            addition to after each browser re-spawn.
- `Form`
    - `#audit` -- `:each_mutation` callback now ignores `#mutation_with_original_values`
        and `#mutation_with_sample_values`.
- Checks
    - Active
        - `xss_dom_inputs` -- Ignore out-of-scope browser pages.
        - `code_injection_php_input_wrapper` -- Cleaned up `:each_mutation` callback.
        - `file_inclusion` -- Cleaned up `:each_mutation` callback.
        - `path_traversal` -- Cleaned up `:each_mutation` callback.
        - `source_code_disclosure` -- Cleaned up `:each_mutation` callback.

## 1.0.1 _(September 7, 2014)_

- `RPC::Server::Dispatcher`
    - Check for Instance status via the bind address, not the external one.
    - Added more status and debugging messages
    - Fixed RPC connection leak when in Grid configuration.
    - `Node`
        - Don't raise error if the initial neighbour is unreachable, just add
            it to the dead list as usual.
- `Browser`
    - Fixed issue causing the removal of cookie HttpOnly flags.
- `Parser`
    - `#link_vars` -- Return empty `Hash` when dealing with unparsable URL.
- `HTTP::Client`
    - Debugging messages now include the `HTTP::Request#performer`.
- `HTTP::Request`
    - `#to_typhoeus` -- Converted proxy type to `Symbol` to prevent the option
        from being ignored.
- `UI::CLI::Utilities`
    - `#print_issues` -- Updated to include all inputs of the given vector in
        the message, if the issue is passive.
- `Check::Auditor`
    - `#log` -- Updated to include all inputs of the given vector in the success
        message, if the issue is passive.
- `Element::Cookie`
    - `.encode` -- Encode `'` and `"`.
- `Hash` -- Renamed added methods to avoid clashes with `ActiveSupport`.
    - `stringify_keys` => `my_stringify_keys`
    - `symbolize_keys` => `my_symbolize_keys`
    - `stringify` => `my_stringify`
- Plugins
    - `proxy` -- Show control panel URL in output.
- Reporters
    - `stdout`
        - Updated to print out information about all available vector inputs.
    - `html`
        - Updated to include information about all available vector inputs in
            issue title for passive issues.
- Checks
    - Active
        - `code_injection_php_input_wrapper` -- Fixed `nil` error when
            manipulating mutations.
        - `file_inclusion` -- Fixed `nil` error when manipulating mutations.
        - `path_traversal` -- Fixed `nil` error when manipulating mutations.
    - Passive
        - `cookie_set_for_parent_domain` -- Only check `HTTP::Response` cookies.

## 1.0 _(August 29, 2014)_

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
    - `#stats` renamed to `#statistics` with the return hash cleaned-up.
    - `#opts` renamed to `#options`.
- `Session`
    - Updated to support login forms which depend on DOM/Javascript.
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
    - `Session` -- Stores login configuration.
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
    - Added `LinkTemplate`
        - Basing its vector identification and manipulation to a user-provided
            template to satisfy cases like ModRewrite and similar.
        - Including `#dom` pointing to a `Auditable::DOM` object handling browser-based
            link submissions/audits.
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
                    - Lowered the amount of performed requests.
                    - No longer downloads response bodies.
                - `RDiff` => `Differential`
                - `Taint`
            - `Submittable`
            - `Inputtable`
- `RPC`
    - `Serializer` -- Replaced `Marshal` and `YAML` as RPC serialization providers.
        - Delegates to `MessagePack`.
        - Supports message compression -- applied based on message size to minimize overhead.
    - `opts` handler renamed to `options`.
    - `Server`
        - `Dispatcher`
            - `#dispatch` -- Returns `false` when the pool is empty as a signal
                to check back later.
            - Removed `#proc_info` method.
            - Removed `proc` from job info data.
            - `Handler` renamed to `Service`.
        - `Instance`
            - Removed `#output`.
        - `Framework`
            - Removed `#output`.
            - `#progress`
                - `:messages` now returns `Framework#status_messages` instead of
                    output messages.
                - Cleaned up return data.
                - Removed `#progress_data` alias.
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
- `Report` (Renamed from `AuditStore`)
    - `#save` -- Updated to store a compressed `Marshal` dump of the instance.
    - `.load` -- Updated to load the new `#save` format.
- `Component::Options` -- Refactored initializers and API.
    - `Enum` renamed to `MultipleChoice`.
- `Reporters` (Renamed from `Reports`)
    - Removed `metareport`.
    - All updated to the new format.
- Plugins
    - Descriptions have been converted to GitHub-flavored Markdown.
    - `resolver` -- Removed as the report now contains that information in the
        responses associated with each issue.
    - `proxy`
        - Updated to use `HTTP::ProxyServer`.
        - Added `ignore_responses` option.
            - Forces the proxy to only extract vector information from observed
                HTTP requests and not analyze responses.
    - `autologin`
        - `params` option renames to `parameters`.
        - Changed results to include `status` (`String`) and `message` (`String`)
            instead of `code` (`Integer`) and `msg` (`String`).
        - Updated to abort the scan upon login failure.
    - `content_types`
        - Renamed `params` in logged results to `parameters`.
    - `cookie_collector`
        - Renamed `res` in logged results to `response`.
    - `waf_detector`
        - Changed results to include `status` (`Symbol`) and `message` (`String`)
            instead of `code` (`Integer`) and `msg` (`String`).
    - `healthmap`
        - Changed results to use `with_issues` and `without_issues` instead of
            `unsafe` and `safe`.
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
    - Descriptions and `remedy_guidance` have been converted to GitHub-flavored Markdown.
    - Renamed
        - `xpath` => `xpath_injection`
        - `ldapi` => `ldap_injection`
        - `sqli` => `sql_injection`
        - `sqli_blind_rdiff` => `sql_injection_differential`
        - `sqli_blind_timing` => `sql_injection_timing`
        - `htaccess` => `htaccess_limit`
    - Active
        - New
            - `xss_dom` -- Injects HTML code via DOM-based links, forms and cookies.
            - `xss_dom_inputs` -- Injects HTML code via orphan text inputs with
                associated DOM events.
            - `xss_dom_script_context` -- Injects JavaScript code via DOM-based
                links, forms and cookies.
            - `no_sql_injection` -- NoSQL Injection (error-based) .
            - `no_sql_injection_differential` -- Blind NoSQL Injection (differential analysis).
        - `xss` -- Added support for Browser-based taint-analysis.
        - `xss_script_context` -- Added support for Browser-based taint-analysis.
            - Renamed from `xss_script_tag`.
        - `unvalidated_redirect` -- Updated to also use full browser evaluation
            in order to detect JS redirects.
        - `os_cmd_injection` -- Added payloads for *BSD and AIX.
    - Passive
        - New
            - `backup_directories` -- Backup directories.
            - `cookie_set_for_parent_domain` -- Cookie set for parent domain.
            - Grep
                - `hsts` - Checks HTTPS pages for missing `Strict-Transport-Security` headers.
        - `backup_files` -- Updated filename formats.
        - `x_forwarded_for_access_restriction_bypass` renamed to `origin_spoof_access_restriction_bypass`.
            - Also updated to use more origin headers.
        - Grep
            - `emails` - Updated to handle simple (`[at]` and `[dot]`) obfuscation.
            - `insecure_cookies` - Only check HTTPS pages.

## 0.4.7 _(April 12, 2014)_

- `Spider`
    - Fixed mixed up status messages upon out-of-scope redirections.
- `HTTP`
    - `disable_ssl_host_verification` set to `true`.
- `Element`
    - `Capabilities::Auditable::Taint`
        - Fixed bug when checking for trust level of issue when there's no match.
    - `Form`
        - Updated to handle empty base-href values.
- Plugins
    - `autologin`
        - Updated to handle stacked post-login redirects.
        - Added debugging information for failed logins.
    - `proxy`
        - Fixed forwarding of request bodies.
- Modules
    - All
        - Updated descriptions and remedies.

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
    - Removed
        - `libnotify`
        - `profiler`
        - `rescan`
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
