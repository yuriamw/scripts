#if (__mips__ == 1)
// g++ bug with C++11: https://bugs.llvm.org/show_bug.cgi?id=13364#c2
namespace std { struct type_info; }
#endif

/*
 * https://bugs.llvm.org/show_bug.cgi?id=13373
 *
 * /opt/toolchains/stbgcc-4.5.4-2.9/mipsel-linux-uclibc/include/c++/4.5.4/nested_exception.h:122:61: error: redefinition of default argument
 * __throw_with_nested(_Ex&& __ex, const nested_exception* = 0)
 *
 * Richard Smith 2012-07-16 13:43:21 PDT                                                                                                                                                                                                                                                *
 *
 * This is a bug in libstdc++-4.5. Delete the ' = 0' from line 122 and the problem should disappear.
 * I'm not sure how much value we'd gain from working around this in Clang: if you want to use libstdc++ and Clang together in C++11 mode,
 * you'd be better off using a more recent libstdc++ like 4.6 or 4.7, which provides more C++11 support, and which Clang has been tested against.
 */
#include <iostream>
#include <string>
#include <list>

int main(int argc, char *argv[])
{
    std::list<std::string> l;

    for (int i = 0; i < argc; i++)
    {
#ifndef NO_GNU_17
        l.emplace_back(std::string(argv[i]));
#else
        // No C++17 support by the compiler
        l.push_back(std::string(argv[i]));
#endif
    }

    int i = 0;
    for (auto it = l.begin(); it != l.end(); it++, i++)
    {
        std::cout << i << ": " << *it << std::endl;
    }

    return 0;
}
