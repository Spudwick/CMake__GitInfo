# CMake Git Info Header Generator

**Author**: Thomas Oliver ([Spudwick](https://github.com/Spudwick))

## Overview

This repository contains a CMake module that can be used to automatically generate a Git information header, at build time, for use in C and C++ projects.

## Requirements

| Software | Version Used | Minimum Required |
|---|---|---|
| `cmake` | 3.25.1 | *Not tested* |

## Usage

A single function call is used to add a Git information header to a pre-defined target.

```
t_git_target_add_header(<target> <header include path>)
```

`<target>` is the CMake target to add the Git information header to.

`<header include path>` is the path that will be used to include the Git information header within the project source.

The generated header is added to the targets *PRIVATE* source list, and an additional *PRIVATE* include directory is added such that the header can be included using the specified `<header include path>`.

### Example

CMakeLists.txt:
```cmake
include(git-info)

add_executable(example "main.c")
t_git_target_add_header(example "cmake/git.h")
```

main.c:
```C
#include "cmake/git.h"

int main(int argc, char* argc[]) {}
```

See the [example](example) directory for a buildable example.

## Header Format

The Git information is provided in the header through several `#defines`.

| Define | Description |
|---|---|
| GIT_BRANCH | String name of checked out Git branch |
| GIT_COMMIT_HASH | String hash of Git commit, appended with "-dirty" if workspace contains local changes |
| GIT_COMMIT_TIMESTAMP | Timestamp of Git commit, in seconds since the Unix Epoch (UTC) |
| GIT_DIRTY | Defined if workspace has local changes, otherwise undefined |

## License

This code is made available under the  [LICENSE](LICENSE) distributed with the repository.
