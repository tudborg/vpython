vpython
================
*Run python inside a virtualenv without the fuzz.*

vpython is a tiny helper script for running your python files inside virtualenv.

You don't have to worry about sourcing the `activate` script,  
you don't have to point to your virtualenv path,  
just use `vpython` instead of `python`.

- - -

I did a post on this tool on my blog: http://tudb.org/articles/2014/03/31/vpython/


What?
----------------
Vpython looks at the path of the script you are trying to run, and searches
for a suiable virtualenv folder. If it finds one, it will tell you on stderr,
set the environment variables as needed (just like the `activate` script),
and use the `python` binary inside that environment to run your script.

It even resolves symlinks before it starts looking, so you can symlink your
executable python script to anywhere. Vpython will still look for the virtualenv
in the _actual_ scripts folder and parent folders.

Really useful if you write a lot of command line utilities in python, with
a bunch of dependencies that you don't want to install globally.


Install
---------------

### With install script

1. Clone this repository to your prefered folder (mine is `~/src/<project>`)
1. go to your new directory and run `install.sh`
2. You're done!

or

1. Copy (or symlink) the `vpython.sh` to somewhere on your path,
like `/usr/bin/vpython`.
2. Do the same with `vpip.sh`
3. You're done!


Usage
---------------

Run it like you would with `python`:
```
$ vpython my_script.py
```

Or use it in a script's shebang:
```python
#!/usr/bin/vpython

print "hello world"
```
