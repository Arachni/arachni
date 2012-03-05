# Build scripts

This directory holds scripts used to build packages for Arachni.

An explanation of each file follows.

## install.sh

* Creates a directory environment to host a fresh Arachni installation
* Donwloads all system library dependencies and installs them in the environment
* Donwloads Ruby and installs it in the environment
* Configures Ruby and installs a few vital gems
* Tests and installs Arachni

The created environment is self-sufficient in providing the required runtimes
for Arachni and can be moved between systems of identical architecture without issue.

## installer.tpl.sh

Provides a template for a self-extracting installer.

## package.sh

Creates an installer using an installation directory (as created by ```install.sh```) and
the template in ```installer.sh.tpl```.

The resulting installer is able to self-extract the installation directory under
a specified directory (default: ```/opt/```) and create symlinks under ```/usr/local/bin/```.

## build.sh

Drives ```install.sh``` and ```package.sh``` to create an installer.
