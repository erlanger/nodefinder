# Automatic node discovery #

## Introduction ##
   This application uses UDP multicast to notify all other nodes about a node's entrance to the
   cluster.  When the application starts, a multicast UDP message is sent to all other nodes.

   Nodes with the same cookie (that are also running nodefinder) will connect to the notifying node,
   updating the cluster dynamically.

   To summarize, you need the following for automatic node discovery:

   1. Use the same cookie to identify nodes of the same cluster
   2. Start nodefinder when the node starts
   3. Make sure the node name is set properly. It needs to be reachable
      from other nodes. (e.g. mynode@127.0.0.1 does not work).

Easy!

## Origin ##
The base code is originally from  https://code.google.com/p/nodefinder; I have
added several features, and error handling.

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

