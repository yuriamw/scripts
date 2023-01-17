#! /bin/bash -e

# --run ^ModelAccessorTestSuite$ -testify.m ^TestModelAccessorAdd$

usage()
{
  echo "Usage: $(basename $0) [OPTIONS]"
  echo "    Run go test in current directory and generate coverage report."
  echo ""
  echo "    To pass through parameters to go test put them after -- ."
  echo "    for example"
  echo "        $(basename $0) -o ../modulename-cover.out -- -v"
  echo "    is equivalent to"
  echo "        go test --cover -coverprofile ../modulename-cover.out -v"
  echo ""
  echo "    To run specific test use the --run command with regexp pattern for test suite and test case names"
  echo "    for example"
  echo "        $(basename $0) -o ../modulename-cover.out -- --run ^MyTestSuite$"
  echo "    is will run all tests in MyTestSuite"
  echo "        $(basename $0) -o ../modulename-cover.out -- --run TestSuite"
  echo "    is will run all tests in all suites which contains 'MyTestSuite'"
  echo "    e.g MyTestSuite, FooMyTestSuite, MyTestSuiteBazz, FooMyTestSuiteBar"
  echo "        $(basename $0) -o ../modulename-cover.out -- --run ^MyTestSuite$ -testify.m ^TestItemsAdd$"
  echo "    is will run single TestItemsAdd test in MyTestSuite"
  echo "        $(basename $0) -o ../modulename-cover.out -- --run ^MyTestSuite$ -testify.m ^TestItems"
  echo "    is will run all tests which names started with TestItems test in MyTestSuite"
  echo ""
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit."
  echo "        -o OUTPUT,--output=OUTPUT"
  echo "            Write coverage report to OUTPUT file."
}

coverout="coverage/cover.out"

SHORT_OPTS="ho:"
LONG_OPTS="help,output:"

OPTIONS_LIST=$(getopt -n $(basename $0) -o "$SHORT_OPTS" -l "$LONG_OPTS" -- "$@")
[ $? -eq 0 ] || exit 1

eval set -- "$OPTIONS_LIST"

while [ -n "$1" ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
    ;;
    -o|output)
      shift
      coverout="${1}"
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

coverouthtml="${coverout}.html"

[ "$1" = "--" ] && shift

set -x

go test --cover -coverprofile ${coverout} $@
go tool cover -html=${coverout} -o ${coverouthtml}
