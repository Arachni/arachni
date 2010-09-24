This file contains some brief instructions on contributing to Arachni.    

Code Style
----
In order to maintain consistency and keep the code pretty you should
adhere to the following guidelines:

 - 4 spaces, no tabs.
 - Maximum line length 75-80 columns, try not to exceed that limit.
 - {} instead of "do" for blocks and keep the iterator var in it's own line.<br/>
    Like so:
        arr.each {
            |item|
        }

In general, take a look at the existing code and try to follow that style.


Code No-Nos
----
**1. Don't print to standard output.**<br/>
The interface in use won't be able to see your output and route it
accordingly.

Arachni provides you with wrappers that you can use, take a look in {Arachni::UI::Output}.<br/>
All UIs will provide these methods to handle your output, use them.


**2. Don't use "sleep".**<br/>
It is unlikely that you will need it, but if you do, use
"select(nil, nil, nil, &lt;time&gt;)" instead to avoid multi-threading issues.


**3. Avoid creating your own instance of Net::HTTP or other lib.**<br/>
You are provided with pre-configured wrapper ({Arachni::Module::Base#http}) of Typhoeus.

Take a look in the tutorial module to see what you get: {Arachni::Modules::Audit::SimpleRFI}
    
The base module will also give you some insights: {Arachni::Module::Base}

If you absolutely have to bypass Arachni's facilities you must obey the
run-time settings in {Arachni::Options}.


Creating New Modules
----
Arachni provides you with examples for the usual types of modules.

This is your main guide: {Arachni::Modules::Audit::SimpleRFI}
    
This covers most of the usual tasks when writing a module.
It lets Arachni do all the work.

For something more elaborate look in:<br/>
- {Arachni::Modules::Audit::ResponseSplitting}<br/>
- {Arachni::Modules::Audit::SQLInjection}
    
These modules do their own vulnerability checking and logging.

If you want to create coupled modules take a look in:<br/>
- {Arachni::Modules::Recon::ExtractObjects}<br/>
- {Arachni::Modules::Audit::AuditObjects}

In this case {Arachni::Modules::Recon::ExtractObjects} extracts information from the
web pages and saves it in the module datastore.

The datastore is persistent and shared between all modules.

{Arachni::Modules::Audit::AuditObjects} then gets the data harvested by {Arachni::Modules::Recon::ExtractObjects}
and handles it accordingly.

One last note.
You're probably going to be working with large arrays of strings,
either regular expressions or strings to inject to the webapp,
so it's better to keep them in an external file under:
    modules/<modname>/

Use "{Arachni::Module::Base#get_data_file}( filename ){ |line| }" to get the file line by line.<br/>
You just pass the filename (no path), get_data_file() will take care of the rest. 

This will make the strings easier to update and keep your modules smaller.

In general, before writing a module copy an existing one that's close
to your needs and modify it.


Creating New Reports<br/>
----
The only thing that you should keep in mind when creating a new report
is to adhere to the structure shown in: {Arachni::Reports::AP}.<br/>
Also look in: {Arachni::Report::Base}.

If you want your users to be able to customize the report you can
provide them with a set of options, as in {Arachni::Reports::HTML}'s self.info() return hash.

Keep in minds though that Arachni does not do any checking for these options,
you will have to take care of that yourself.

However, do provide an appropriate default "outfile" value in "initialize".

Other than that you can do whatever you want, you have all of Ruby's
power to work with. 


Licensing
----
All code must be contributed with a GPL v2 compatible license.<br/>
Do place licensing information in your code files.

