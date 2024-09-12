#include <stdio.h>
#include <time.h>

#include "cmake/git.h"

int main( int argc, char *argv[] )
{
    time_t commit_tmstmp = GIT_COMMIT_TIMESTAMP;

    char buff[20];
    strftime(buff, 20, "%Y-%m-%d %H:%M:%S", localtime(&commit_tmstmp));

    printf("%s\n", buff);

    return 0;
}