# Automatic node discovery #

This code is originally from  https://code.google.com/p/nodefinder, I have only fixed
a few warnings from used old crypto functions.

## How to use ##

1. Add nodefinder as a dependency in your project. Put a line like this in rebar.config deps list:
   ```
   {nodefinder,    ".*",   {git, "git://github.com/erlanger/nodefinder",   {branch, master}}}
   ```
2. Add nodefinder to the list of application dependencies in your .app file
3. If you are using releases in rebar add nodefinder to the lists of applications in reltool.config

That's it. 

## Important ##
Make sure you use the same cookie for all the nodes you want to attach to the nodefinder cluster.
nodefinder uses the cookie in order to determine which nodes belong to the cluster. 

You could use this feature to setup parallel clusters that don't talk to each other.

