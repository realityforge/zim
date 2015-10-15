# Zim

Zim is a really simple tool used to perform mechanical transformation of multiple code bases.

## Configuration

Zim will be doing lots of resetting, committing and pushing of changes, so it is imperative to use a separate base
directory, not your development working directories. It is recommended to create a `_zim.rb` file in your Zim project
directory and add a line specifying your base directory:

    $ Zim::Config.base_directory = File.expand_path('~/Code/zim_base_directory')

## Running

Get some help:

    $ ./zim --help

Get a list of commands:

    $ ./zim

## Source Tree Sets

Zim has a number of Source Tree Sets, which specify groups of Git repositories. To add new repositories, edit the
zim file in the Zim project directory.

You can specify which Source Tree Set to operator over using the `-s` or `--source-tree-set` command line parameter. If
unspecified, the changes will be applied to the default source tree set.

## Base commands

Zim can do many of the git commands such as clone, fetch, reset, pull and push, but it operators over
all the repositories in your Source Tree Set.

So a good way to start is to clone into your new base directory:

    $ ./zim --verbose --source-tree-set ARENA clone

There are also some useful composite commands such as clean, which does a [clone, fetch, reset, goto_master, pull]
basically getting ready to apply some patches.

Also `standard_update` is useful for updating DomGen and DBT plus doing some general cleaning of whitespace issues.

## Custom commands

You can also write your own commands to apply changes over multiple repositories. Add your commands to the zim file
in the Zim project directory.

You can then chain together base and custom commands:

    $ ./zim --verbose --source-tree-set ARENA clean patch_build_yaml_repositories push

We might write some more help in the future, but for now, just look at all the other commands in there and you'll get
idea.
