cmake_minimum_required(VERSION 3.20)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/..")

project(example
        VERSION 1.2.3
        LANGUAGES C
)

include(git-info)

add_executable(example
    "./main.c"
)

t_git_target_add_header(example "cmake/git.h")
