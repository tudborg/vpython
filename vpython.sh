#! /bin/bash
# Run python stuff inside your virtualenv without activating it
# vpython is like calling python inside a virtualenv, except you
# don't have to worry about calling activate.
# Very useful for cli applications that you just link to somewhere in your path
# but still want to install deps inside a virtualenv.
#
# Currently maintained by https://github.com/tbug
# at https://github.com/tbug/vpython
#
 
 
ENV_NAME=${ENV_NAME:-'virtualenv'}

# Check deps
[ ! $(which virtualenv) ] && echo "virtualenv not found" && exit;

# This is the best way that i have found to get an absolute path from a relative one
function abspath {
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

function linkresolve {
    # Resolve link if needed
    local path=$1
    while [ -h "$path" ]; do
        path="$(readlink "$path")"
        # if resolved does not exist, stop.
        # TODO: issue with relative links here
        [ ! -e "$path" ] && return 127
    done
    echo $path
}

function envpath {
    # get the virtualenv path if any
    local SOURCE="$(abspath "$1")"
    [ 127 -eq $? ] && return 127

    SOURCE="$(linkresolve $SOURCE)"
     
    # Look for the python executable inside the virtualenv folder
    # We could do this even more agressively by looking inside all folders
    # of $DIRNAME to see if we can find a directory structure that matches virtualenv
    if [ -d $SOURCE ]; then
        local DIRNAME=$SOURCE
    else
        local DIRNAME="$(dirname "$SOURCE")"
    fi

    #we only need to look 3 dirs down, since that is the nest-ness (yes, that is now a word)
    #of virtualenv structure, we are looking for an executable, (the env/bin/python)
    local pythons
    local env
    while [ ! "$env" ]; do
        pythons=$(find $DIRNAME -maxdepth 3 -path "$DIRNAME/*/bin/python" 2>/dev/null | head -n 1)
        env="$(echo ${pythons:${#DIRNAME}} | cut -d"/" -f2)"
        #break if we reached root
        ([ "$DIRNAME" == "/" ] || [ "$env" ]) && break
        #else up one dir
        DIRNAME="$(dirname "$DIRNAME")"
    done

    # Ensure that we did not hit root directory
    [ "$DIRNAME" == "/" ] && return 120

    # We found a virtualenv dir
    echo "${DIRNAME}/${env}"
    return 0
}

function printcode {
    case $1 in
        0) ;; #0 is ok, no message
        120) echo "could not find virtualenv";;
        127) echo "not a valid path";;
        *) echo "unknown error";;
    esac
    return $1
}

# Our usage help text
function run_show_usage {
    echo "Usage:"
    echo "    vpython --help                                this help"
    echo "    vpython --pip </path/to/env> [<pip_ags>...]   call the virtualenv pip"
    echo "    vpython --install </path/to/new/env>          install a new virtualenv"
    echo "    vpython --find </path/to/search/for/env>      return virtualenv path if found, else exits with non-0"
    echo "    vpython <python_file>                         call a python file inside a virtualenv"
    echo "    vpython <directory>                           start a python shell inside a virtualenv"
}

 # Install a new virtualenv
function run_install {
    local base="$(abspath "$1")"
    local envdir
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

#output found virtualenv path
function run_find {
    [ 1 -gt $# ] && echo "Usage: vpython --find </path/to/search>" >&2 && exit 2
    local venv
    venv="$(envpath "$1")"
    code=$?
    printcode $code >&2
    #if 0, show venv and exit 0
    [ 0 -eq $code ] && echo $venv && exit 0
    #else just exit with code
    exit $code
}

#find a virtualenv on path given, run python inside
function run_in_env {
    #pass executable relative to env folder (like /bin/python) as first arg
    #and path to script or folder as second arg
    local program=$1
    local path=$2
    shift && shift

    [ ! "$path" ] && path="$(pwd)"

    export VIRTUAL_ENV
    VIRTUAL_ENV="$(envpath "$path")"
    retcode=$?
    #if non-0 return, show a message on stderr and exit with code
    if [ ! 0 -eq $retcode ]; then
        [ ! $VPYTHON_QUIET ] && printcode $retcode >&2
        exit $retcode
    fi

    # Instead of sourcing the "activate" script, just do the same-ish
    # cus' "people" bitch about using the activate anyway, and
    # this is essentially what it does:
    # We need to set the path, obviously
    export PATH="$VIRTUAL_ENV/bin:$PATH"
    # And unset the PYTHONHOME
    unset PYTHONHOME

    #check if we should pass the path as the first arg to python
    #(we should if it is a python file, so, not a directory, essentially)
    local args=()
    if [ -d $path ]; then
        args="$@"
    else
        args="$path $@"
    fi

    [ ! $VPYTHON_QUIET ] && echo "Using virtualenv at \"$VIRTUAL_ENV\"" >&2

    # Now call the $PROGRAM inside our env
    $VIRTUAL_ENV$program $args

    exit $?
}

# Parse options, run accordingly
# inspiration from http://stackoverflow.com/questions/17016007/bash-getopts-optional-arguments
function run_main {
    local opt
    opt=$1
    shift
    case ${opt} in
        -i|--install)
            run_install $@ && exit;;
        -f|--find)
            run_find $@ && exit;;
        -p|--pip)
            run_in_env /bin/pip $@ && exit $?;;
        -h|--help)
            run_show_usage && exit;;
        -q|--quiet)
            VPYTHON_QUIET=1
            run_in_env /bin/python $@ && exit $?;;
        *) #anything else than the above should be run with python, including $opt
            run_in_env /bin/python $opt $@ && exit $?;;
    esac
}

run_main $@
exit $?
