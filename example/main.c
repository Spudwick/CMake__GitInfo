#include <stdio.h>

#include "cmake/git.h"

char commit_hash[] = GIT_COMMIT_HASH;

int main( int argc, char *argv[] )
{
    printf("Commit Hash: %s\n", commit_hash);

    return 0;
}