#! /bin/bash -e

# -p pkg -- --run ^MyTestSuite$ -testify.m ^TestItems

covoutput="$(realpath $PWD/../../../coverage)"
shortdir="pkg"
longdir="packages"
declare -a packages
packages=()

pkgdir=${shortdir}
if [ ! -d "${pkgdir}" ]; then
    pkgdir=${longdir}
    if [ ! -d "${pkgdir}" ]; then
        echo "FATAL: neither ${shortdir} not ${longdir} directory found - abort"
        exit 1
    fi
fi

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
  echo "    To run specific test use the --run command with regexp pattern for test suite and test case names"
  echo "    for example"
  echo "        $(basename $0) -p pkg -- --run ^MyTestSuite$"
  echo "    is will run all tests in MyTestSuite"
  echo "        $(basename $0) -p pkg -- --run TestSuite"
  echo "    is will run all tests in all suites which contains 'MyTestSuite'"
  echo "    e.g MyTestSuite, FooMyTestSuite, MyTestSuiteBazz, FooMyTestSuiteBar"
  echo "        $(basename $0) -p pkg -- --run ^MyTestSuite$ -testify.m ^TestItemsAdd$"
  echo "    is will run single TestItemsAdd test in MyTestSuite"
  echo "        $(basename $0) -p pkg -- --run ^MyTestSuite$ -testify.m ^TestItems"
  echo "    is will run all tests which names started with TestItems test in MyTestSuite"
  echo ""
  echo "    Options:"
  echo "        -h,--help"
  echo "            Print help and exit"
  echo "        -p PACKAGE,--package=PACKAGE"
  echo "            Test package PACKAGE"
  echo "            Could be used multiple times."
  echo "        -c DIRECTORY,--coverage=DIRECTORY"
  echo "            Put coverage results into DIRECTORY"
}

SHORT_OPTS="hs:c:p:"
LONG_OPTS="help,coverage:,package:"

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
      p="$1"
      case "$p" in
        ./*)
          p="${p#./}"
        ;;
      esac
      case "$p" in
        ${pkgdir}/*)
          p=${p#"$pkgdir/"}
        ;;
      esac
      num=${#packages[*]}
      packages[$num]="$p"
    ;;
    -c|--coverage)
      shift
      covoutput="$(realpath "$1")"
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
    pushd "${pkgdir}" > /dev/null
      for i in $(find . -name *_test.go -type f -exec dirname {} \; | sort | uniq)
      do
          idx=${#packages[*]}
          p="${i##./}"
          packages[$idx]="${p}"
      done
    popd > /dev/null
fi

# [ "$1" = "--" ] && shift

for package in ${packages[*]}; do
    echo "=== $package"
    pushd "${pkgdir}/${package}" > /dev/null
        f="${package////-}"
        go-unit-test-with-coverage.sh -o ${covoutput}/${f}-cover.out $@
    popd > /dev/null
done
