#! /bin/bash
# Thin wrapper around the vpython --bin ipython command
# Find current directory, even behind symlinks.
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

$DIR/vpython.sh --bin ipython $@
STATUS="$?"
if [ "$STATUS" == 127 ]; then
    echo "" >&2
    echo "It looks like ipython is not installed in that virtualenv" >&2
    echo "You can install it with:" >&2
    echo "" >&2
    echo "    vpip install ipython" >&2
    echo "" >&2
fi
exit $?