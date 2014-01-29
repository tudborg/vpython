#! /bin/bash
# Run python stuff inside your virtualenv without activating it
# vpython is like calling python inside a virtualenv, except you
# don't have to worry about calling activate.
# Very useful for cli applications that you just link to somewhere in your path
# but still want to install deps inside a virtualenv.
#
# Maintained by https://github.com/tbug @ https://gist.github.com/tbug/8640347

# Usage:
#   Place this script somewhere in your path, like /usr/bin/vpython
#   In your python files, instead of using #!/usr/bin/python 
#   as your first line, use #!/usr/bin/vpython
#   Make that python file executable and call it from anywhere,
#   if it is inside a virtualenv, it will find that virtualenv and call
#   it with the virtualenv python link instead of your system one.
#
#   Oh, and you can ofc. also just call your python files without making them executable,
#   just use `vpython my_file.py` instead of the regular `python my_file.py`
#
 
# TODO:
#   - Look in more than one folder for the virtualenv
#   - Create autoupdate option
 
 
# You can change this if you like, this is the name if the virtualenv folder
# we are going to search for
DEFAULT_ENV_NAME='.virtualenv'
 
 
# Okay, hands off from here on;
ENV_NAME=${ENV_NAME:-$DEFAULT_ENV_NAME}
 
 
# Check deps
[ ! $(which virtualenv) ] && echo "virtualenv not found" && exit;


# This is the best way that i have found to get an absolute path from a relative one
function abspath () {
    if [[ -d "$1" ]]
    then
        pushd "$1" >/dev/null
        pwd
        popd >/dev/null
    elif [[ -e $1 ]]
    then
        pushd "$(dirname "$1")" >/dev/null
        echo "$(pwd)/$(basename "$1")"
        popd >/dev/null
    else
        return 127
    fi
}

function envpath () {
    # get the virtualenv path if any
    local SOURCE="$(abspath "$1")"

    if [ 127 -eq $? ]; then
        echo "directory or file \"$1\" does not exist" 1>&2
        return 127
    fi

    # Resolve link if needed
    while [ -h "$SOURCE" ]; do
        SOURCE="$(readlink "$SOURCE")"
        # if resolved does not exist, stop.
        # TODO: issue with relative links here
        if [ ! -e "$SOURCE" ]; then
            return 127
        fi
    done
     
    # Look for the python executable inside the virtualenv folder
    # We could do this even more agressively by looking inside all folders
    # of $DIRNAME to see if we can find a directory structure that matches virtualenv
    if [ -d $SOURCE ]; then
        local DIRNAME=$SOURCE
    else
        local DIRNAME="$(dirname "$SOURCE")"
    fi

    while [ ! -d "${DIRNAME}/${ENV_NAME}/bin" ]; do
        DIRNAME="$(dirname "$DIRNAME")"
        if [ "$DIRNAME" == "/" ]; then
            break
        fi
    done
     
    # Ensure that we did not hit root directory
    if [ "$DIRNAME" == "/" ] || [ ! -d "${DIRNAME}/${ENV_NAME}/bin" ]; then
        echo "could not find virtualenv" 1>&2
        #maybe just default to system python here? hmm..
        return 1
    fi
    # We found a virtualenv dir
    echo "${DIRNAME}/${ENV_NAME}"
    return 0
}

# Our usage help text
function show_usage () {
    echo "Usage:"
    echo "    vpython --help                                this help"
    echo "    vpython --pip </path/to/env> [<pip_ags>...]   call the virtualenv pip"
    echo "    vpython --install </path/to/new/env>          install a new virtualenv"
    echo "    vpython --find </path/to/search/for/env>      return virtualenv path if found, else exits with code 1"
    echo "    vpython <python_file>                         call a python file inside a virtualenv"
    echo "    vpython <directory>                           start a python shell inside a virtualenv"
}

# Install via pip
function pip_install () {
    if [ 1 -gt $# ]; then
        echo "Usage: vpython --pip </path/to/env> [<pip_ags>...]" 1>&2
        exit 1
    fi

    local VIRTUAL_ENV="$(envpath "$1")"

    envpath_code=$?
    case $envpath_code in
        0) ;; #0 is ok
        1) echo "could not find virtualenv" 1>&2 && exit 1;;
        127) echo "$1 is not a valid path" 1>&2 && exit 127;;
        *) echo "unknown error" 1>&2 && exit $envpath_code;;
    esac
    shift #shift off the virtualenv path

    # Instead of sourcing the "activate" script, just do the same-ish
    # We need to set the path, obviously
    export PATH="$VIRTUAL_ENV/bin:$PATH"
    # And unset the PYTHONHOME
    unset PYTHONHOME
    #invoke pip with the rest of the arguments
    $VIRTUAL_ENV/bin/pip $@
    exit $? # exit with pip exit code
}

 # Install a new virtualenv
function virtualenv_install () {
    local base="$(abspath "$1")"
    local envdir=""
    #check for dir not exist
    if [ 127 -eq $? ]; then
        echo "directory or file \"$1\" does not exist" 1>&2
        exit 127
    fi

    shift #shift off the first arg (the dir)

    if [ -d "$base" ]; then
        #if dir given, install under env_name
        envdir="$base/$ENV_NAME"
    else #else, install as the given directory name
        envdir="$base"
    fi
    virtualenv $@ $envdir
    exit $?
}

function virtualenv_find () {
    if [ 1 -gt $# ]; then
        echo "Usage: vpython --find </path/to/search>" 1>&2
        exit 2
    fi
    local VIRTUAL_ENV
    VIRTUAL_ENV="$(envpath "$1")"
    envpath_code=$?
    case $envpath_code in
        0) ;; #0 is ok
        1) echo "could not find virtualenv" 1>&2 && exit 1;;
        127) echo "$1 is not a valid path" 1>&2 && exit 127;;
        *) echo "unknown error" 1>&2 && exit $envpath_code;;
    esac
    echo $VIRTUAL_ENV
    exit 0
}


function vpython_run () {
    local path=()
    if [ ! "$1" ]; then
        # if no arg given, default to current working directory
        path="$(pwd)"
    else
        path=$1
    fi

    VIRTUAL_ENV="$(envpath "$path")"
    envpath_code=$?
    case $envpath_code in
        0) ;; #0 is ok
        1) echo "could not find virtualenv" 1>&2 && exit 1;;
        127) echo "$path is not a valid path" 1>&2 && exit 127;;
        *) echo "unknown error" 1>&2 && exit $envpath_code;;
    esac

    # Instead of sourcing the "activate" script, just do the same-ish
    # We need to set the path, obviously
    export PATH="$VIRTUAL_ENV/bin:$PATH"
    # And unset the PYTHONHOME
    unset PYTHONHOME

    #check if we should pass any args to python
    local args=()
    if [ -d $1 ]; then
        echo "Using virtualenv at \"$VIRTUAL_ENV\"" 1>&2
        args=()
    else
        echo "Using virtualenv at \"$VIRTUAL_ENV\"" 1>&2
        args=$@
    fi

    # Now call the $PROGRAM inside our env
    $VIRTUAL_ENV/bin/python $args

    exit $?
}

# Parse options, run accordingly
# inspiration from http://stackoverflow.com/questions/17016007/bash-getopts-optional-arguments
function parseopts() {
    local argv=()
    local opt=()
    while [ $# -gt 0 ]; do
        opt=$1
        shift
        case ${opt} in
            -i|--install)
                virtualenv_install $@ && exit;;
            -f|--find)
                virtualenv_find $@ && exit;;
            -p|--pip)
                pip_install $@ && exit;;
            -h|--help)
                show_usage && exit;;
            *) #anything else than the above should be passed to vpython_run
                break
        esac
    done
    vpython_run $opt $@
    exit $?
}

parseopts $@
exit $?
