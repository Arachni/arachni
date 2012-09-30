# Hacking the Framework

This file contains some brief instructions on contributing to Arachni.

## Code Style
In order to maintain consistency and keep the code pretty you should
adhere to the following guidelines:

 - 4 spaces, no tabs.
 - Maximum line length 75-80 columns, try not to exceed that limit.
 - For single-line blocks, use:

```ruby
    arr.each { |item| stuff( item ) }
```

- For multi-line blocks which expect parameters use:

```ruby
    arr.each do |item|
        stuff( item )
    end
```

 - Use space before, between, and after method parameters:

```ruby
    my_method( param1, param2 )
```

 - Use the new syntax when defining hashes, i.e. ':' instead of '=>'.
 - Use '?' at the end of methods which are expected to return a boolean result.
 - Use '!' at the end of methods only for ones which perform a similar operation
   but requiring extra attention from the ones without.
   Do not use it to just signify destructive action.

In general, take a look at the existing code and try to follow that style **but**
keep in mind that these guidelines should be given higher priority.


## Code No-Nos
**1. Don't print to standard output.**<br/>
The interface in use won't be able to see your output and route it
accordingly.

Arachni provides you with wrappers that you can use, take a look in {Arachni::UI::Output}.<br/>
All UIs will provide these methods to handle your output, use them.


**2. Don't use "sleep".**<br/>
It is unlikely that you will need it, but if you do, use
`select(nil, nil, nil, <time>)` instead to avoid multi-threading issues.


**3. Avoid creating your own instance of Net::HTTP or other lib.**<br/>
You are provided with a pre-configured wrapper ({Arachni::Module::Auditor#http}) of [Typhoeus](http://github.com/pauldix/typhoeus).

Take a look in the tutorial module to see what you get: {Arachni::Modules::RFI}

The base module will also give you some insights: {Arachni::Module::Base}

If you absolutely have to bypass Arachni's facilities you must obey the
run-time settings in {Arachni::Options}.


## Creating New Modules
Arachni provides you with examples for the usual types of modules.

This is your main guide: {Arachni::Modules::RFI}

This covers most of the usual tasks when writing a module.
It lets Arachni do all the work.

For something more elaborate look in:<br/>
- {Arachni::Modules::ResponseSplitting}<br/>
- {Arachni::Modules::SQLInjection}

These modules do their own vulnerability checking and logging.

One last note.
You're probably going to be working with large arrays of strings,
either regular expressions or strings to inject to the webapp,
so it's better to keep them in an external file under:
    modules/<modtype>/<modname>/

Use "{Arachni::Module::Utilities#read_file}`( filename ){ |line| }`" to get the file line by line.<br/>
You just pass the filename (no path), `read_file()` will take care of the rest.

This will make the strings easier to update and keep your modules smaller.

In general, before writing a module copy an existing one that's close
to your needs and modify it.


## Creating New Reports
The only thing that you should keep in mind when creating a new report
is to adhere to the structure shown in: {Arachni::Reports::AP}.<br/>
Also look in: {Arachni::Report::Base}.

If you want your users to be able to customize the report you can
provide them with a set of options, as in {Arachni::Reports::HTML}'s `self.info()` return hash.

Keep in minds though that Arachni does not do any checking for these options,
you will have to take care of that yourself.

However, do provide an appropriate default `outfile` value in `initialize()`.

Other than that you can do whatever you want, you have all of Ruby's
power to work with.


## Creating New Plug-ins

Unlike the two previous types of components plug-ins are demi-gods.<br/>
Each plug-in is passed the instance of the running framework to do with it what it pleases.<br/>
Via the framework they have access to all Arachni subsystems and can alter or extend Arachni's behavior on the fly.<br/>
Plug-ins run in parallel to the framework and are executed right before the scan process starts.

## Licensing
All code must be contributed with an Apache License Version 2.0 compatible license.
