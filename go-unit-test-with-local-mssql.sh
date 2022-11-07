#! /bin/bash -e

UNIT_TESTS_MSSQL_DB=${UNIT_TESTS_MSSQL_DB:-"TestSuiteDB"}
UNIT_TESTS_MSSQL_PASSWD=${UNIT_TESTS_MSSQL_PASSWD:-"ThisIs!Password"}

connection_string=""
connection_string="${connection_string}azuresqlcreatedb=${UNIT_TESTS_MSSQL_DB};"
connection_string="${connection_string}Server=tcp:localhost,1433;"
connection_string="${connection_string}Initial Catalog=master;"
connection_string="${connection_string}Persist Security Info=False;"
connection_string="${connection_string}User ID=sa;"
connection_string="${connection_string}Password=${UNIT_TESTS_MSSQL_PASSWD};"
connection_string="${connection_string}MultipleActiveResultSets=False;"
connection_string="${connection_string}TrustServerCertificate=False;"
connection_string="${connection_string}Connection Timeout=30;"

export UNIT_TESTS_MSSQL_CONNECTION_STRING="${connection_string}"

covoutput="$(realpath $PWD/../../../coverage)"
dir="packages"
declare -a packages
packages=()

# --run ^ModelAccessorTestSuite$ -testify.m ^TestModelAccessorAdd$

usage()
{
  echo "Usage: $(basename $0) [OPTIONS]"
  echo "    Run go test for specified package."
  echo "    The script must be run from root directory of tested application."
  echo "    it looks for package at 'packages/package' subdir (see -p)."
  echo "    If no packages specified all packages will be tested at packages/* subdir."
  echo ""
  echo "    To pass through parameters to go test put them after -- ."
  echo "    for example"
  echo "        $(basename $0) -p pkg -- -v"
  echo "    is equivalent to"
  echo "        (cd packages/pkg && go test -v)"
  echo ""
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit"
  echo "        -p PACKAGE,--package=PACKAGE"
  echo "            Test package PACKAGE"
  echo "            Could be used multiple times."
}

SHORT_OPTS="hs:p:"
LONG_OPTS="help,package:"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    -p|--package)
      shift
      num=${#packages[*]}
      packages[$num]="$1"
    ;;
    --)
      break
    ;;
    *)
      usage
      exit 1
    ;;
  esac
  shift
done

if [ ${#packages[@]} -eq 0 ]; then
    for i in $(find "${dir}" -name go.mod -type f)
    do
        idx=${#packages[*]}
        packages[$idx]=$(basename $(dirname $i))
    done
fi

[ "$1" = "--" ] && shift

for package in ${packages[*]}; do
    echo "=== $package"
    pushd "packages/${package}" > /dev/null
        f="$(basename $(pwd))"
        go test --cover -coverprofile ${covoutput}/${f}-cover.out $@
        go tool cover -html=${covoutput}/${f}-cover.out -o ${covoutput}/${f}-coverage.html
    popd > /dev/null
done
