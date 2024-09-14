include_guard(GLOBAL)

include(CMakeParseArguments)

#=========================================================
# PRIVATE MEMBERS
#=========================================================

set(_T_GIT_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})

add_custom_command(
    OUTPUT _t_git_always_rebuild
    COMMAND cmake -E echo
    COMMENT ""
)

function(_t_git_gen_dir OUTPUT_VAR TARGET)
    set(${OUTPUT_VAR} "${CMAKE_CURRENT_BINARY_DIR}/git/${TARGET}" PARENT_SCOPE)
endfunction()

function(_t_git_write_script_banner FILE_PATH)
    file(WRITE ${FILE_PATH}
        "# Auto-generated cmake script\n"
        "\n"
        "# Git Header Generator\n"
        "# Author: https://github.com/Spudwick\n"
        "\n"
    )
endfunction()

function(_t_git_create_stage1_script SCRIPT_PATH)
    get_filename_component(BASE_DIR ${SCRIPT_PATH} DIRECTORY)

    _t_git_write_script_banner(${SCRIPT_PATH})
    file(APPEND ${SCRIPT_PATH}
        "# Stage 1\n"
        "\n"
    )

    # Get current Git branch
    file(APPEND ${SCRIPT_PATH}
        "execute_process(\n"
        "   COMMAND git branch --show-current\n"
        "   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}\n"
        "   OUTPUT_VARIABLE GIT_BRANCH\n"
        "   OUTPUT_STRIP_TRAILING_WHITESPACE\n"
        ")\n"
    )
    # Get full Git commit hash with dirty tag
    file(APPEND ${SCRIPT_PATH}
        "execute_process(\n"
        "   COMMAND git describe --always --dirty --abbrev=0\n"
        "   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}\n"
        "   OUTPUT_VARIABLE GIT_COMMIT_HASH\n"
        "   OUTPUT_STRIP_TRAILING_WHITESPACE\n"
        ")\n"
    )
    # Get commit timestamp (Unix epoch in UTC)
    file(APPEND ${SCRIPT_PATH}
        "execute_process(\n"
        "   COMMAND git show -s --format=%ct\n"
        "   WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}\n"
        "   OUTPUT_VARIABLE GIT_COMMIT_TIMESTAMP\n"
        "   OUTPUT_STRIP_TRAILING_WHITESPACE\n"
        ")\n"
    )

    # Add info to cache file
    file(APPEND ${SCRIPT_PATH}
        "file(WRITE ${BASE_DIR}/git-info.stage1\n"
        "   \"\${GIT_BRANCH}\\n\"\n"
        ")\n"
        "file(APPEND ${BASE_DIR}/git-info.stage1\n"
        "   \"\${GIT_COMMIT_HASH}\\n\"\n"
        ")\n"
        "file(APPEND ${BASE_DIR}/git-info.stage1\n"
        "   \"\${GIT_COMMIT_TIMESTAMP}\\n\"\n"
        ")\n"
    )

endfunction()

function(_t_git_create_stage2_script SCRIPT_PATH INC_DIR HDR_INC_PATH)
    get_filename_component(BASE_DIR ${SCRIPT_PATH} DIRECTORY)

    set(HDR_PATH "${INC_DIR}/${HDR_INC_PATH}")

    _t_git_write_script_banner(${SCRIPT_PATH})
    file(APPEND ${SCRIPT_PATH}
        "# Stage 2\n"
        "\n"
    )

    file(APPEND ${SCRIPT_PATH}
        "file(STRINGS ${BASE_DIR}/git-info.stage2\n"
        "   GIT_INFO\n"
        ")\n"
    )
    file(APPEND ${SCRIPT_PATH}
        "list(GET GIT_INFO 0 GIT_BRANCH)\n"
    )
    file(APPEND ${SCRIPT_PATH}
        "list(GET GIT_INFO 1 GIT_COMMIT_HASH)\n"
    )
    file(APPEND ${SCRIPT_PATH}
        "list(GET GIT_INFO 2 GIT_COMMIT_TIMESTAMP)\n"
    )

    file(APPEND ${SCRIPT_PATH}
        "string(FIND \${GIT_COMMIT_HASH} \"-dirty\" GIT_DIRTY)\n"
        "if(GIT_DIRTY EQUAL -1)\n"
        "   unset(GIT_DIRTY)\n"
        "else()\n"
        "   set(GIT_DIRTY 1)\n"
        "endif()\n"
    )

    set(INCLUDE_GAURD_DEF ${HDR_INC_PATH})
    string(REPLACE "/" "_" INCLUDE_GAURD_DEF ${INCLUDE_GAURD_DEF})
    string(REPLACE "\\" "_" INCLUDE_GAURD_DEF ${INCLUDE_GAURD_DEF})
    string(REPLACE "." "_" INCLUDE_GAURD_DEF ${INCLUDE_GAURD_DEF})
    string(TOUPPER ${INCLUDE_GAURD_DEF} INCLUDE_GAURD_DEF)
    string(PREPEND INCLUDE_GAURD_DEF "GIT_")
    string(APPEND INCLUDE_GAURD_DEF "_INCLUDED")

    file(APPEND ${SCRIPT_PATH}
        "set(INCLUDE_GAURD_DEF \"${INCLUDE_GAURD_DEF}\")\n"
        "configure_file(\"${_T_GIT_ROOT_DIR}/git.h.in\" \"${HDR_PATH}\")\n"
    )
endfunction()


#=========================================================
# PUBLIC MEMBERS
#=========================================================

function(t_git_add_header TARGET HDR_INC_PATH)
    set(OPTIONS)
    set(ONE_VAL_ARGS WORKDIR)
    set(MULIT_VAL_ARGS)
    cmake_parse_arguments(PARSE_ARGV 1
                          GH
                          OPTIONS ONE_VAL_ARGS MULIT_VAL_ARGS)

    message(CHECK_START "Adding \"${HDR_INC_PATH}\"")
    list(APPEND CMAKE_MESSAGE_INDENT "  ")

    _t_git_gen_dir(BASE_DIR ${TARGET})
    set(SCRIPT_DIR "${BASE_DIR}/scripts")
    set(INC_DIR "${BASE_DIR}/inc")
    set(HDR_PATH "${INC_DIR}/${HDR_INC_PATH}")
    
    message(DEBUG "Base Dir : ${BASE_DIR}")
    message(DEBUG "Inc Dir  : ${INC_DIR}")
    message(DEBUG "Hdr Path : ${HDR_PATH}")

    _t_git_create_stage1_script("${SCRIPT_DIR}/stage1.cmake")

    _t_git_create_stage2_script("${SCRIPT_DIR}/stage2.cmake" "${INC_DIR}" "${HDR_INC_PATH}")

    add_custom_command(
        OUTPUT "${SCRIPT_DIR}/git-info.stage1"
        COMMAND ${CMAKE_COMMAND} "-P" "${SCRIPT_DIR}/stage1.cmake"
        COMMENT "Getting Git info"
        DEPENDS
            _t_git_always_rebuild
    )

    add_custom_command(
        OUTPUT "${SCRIPT_DIR}/git-info.stage2"
        DEPENDS "${SCRIPT_DIR}/git-info.stage1"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SCRIPT_DIR}/git-info.stage1" "${SCRIPT_DIR}/git-info.stage2"
        COMMENT ""
    )

    add_custom_command(
        OUTPUT ${HDR_PATH}
        DEPENDS "${SCRIPT_DIR}/git-info.stage2"
        COMMAND ${CMAKE_COMMAND} "-P" "${SCRIPT_DIR}/stage2.cmake"
    )

    target_include_directories(${TARGET}
        PRIVATE ${INC_DIR}
    )

    target_sources(${TARGET}
        PRIVATE ${HDR_PATH}
    )

    list(POP_BACK CMAKE_MESSAGE_INDENT)
    message(CHECK_PASS "success")
endfunction()