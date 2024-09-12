#include <stdio.h>
#include <time.h>

#include "cmake/git.h"

int main( int argc, char *argv[] )
{
    const time_t commit_tmstmp = GIT_COMMIT_TIMESTAMP;
    const char   commit_hash[] = GIT_COMMIT_HASH;
    const char   branch[]      = GIT_BRANCH;
    const char   dirty         = GIT_DIRTY;

    printf("Branch : %s\n", branch);
    printf("Commit : %s\n", commit_hash);

    char buff[20];
    strftime(buff, 20, "%d-%m-%Y %H:%M:%S", localtime(&commit_tmstmp));
    printf("Commit Time : %s\n", buff);

    if( GIT_DIRTY )
    {
        printf("Workspace DIRTY!\n");
    }
    else
    {
        printf("Workspace clean.\n");
    }

    return 0;
}