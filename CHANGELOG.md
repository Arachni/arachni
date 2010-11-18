
# ChangeLog

## Version 0.2.1
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
- Plug-in support -- allowing the framework to be extended with virtually any functionality (**New**).
- Added plug-ins: (**New**)
   - Passive proxy
- Added modules: (**New**)
   - Recon
      - CVS/SVN user disclosure
      - Private IP address disclosure


## Version 0.2

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
