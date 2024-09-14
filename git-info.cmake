#=========================================================
# Copyright (C) 2024 Thomas Oliver - All Rights Reserved
# You may use, distribute and modify this code under the
# terms of the GPL license distributed with this code.
#=========================================================

include_guard(GLOBAL)

include(CMakeParseArguments)

#=========================================================
# PRIVATE MEMBERS
#=========================================================

set(_T_GIT_ROOT_DIR ${CMAKE_CURRENT_LIST_DIR})

set(_T_GIT_STAGE1_SCRIPT_TEMPLATE_PATH "${_T_GIT_ROOT_DIR}/stage1.cmake.in")
set(_T_GIT_STAGE2_SCRIPT_TEMPLATE_PATH "${_T_GIT_ROOT_DIR}/stage2.cmake.in")
set(_T_GIT_HDR_TEMPLATE_PATH "${_T_GIT_ROOT_DIR}/git-info.h.in")

add_custom_command(
    OUTPUT _t_git_always_rebuild
    COMMAND cmake -E echo
    COMMENT ""
)

function(_t_git_gen_dir OUTPUT_VAR TARGET)
    set(${OUTPUT_VAR} "${CMAKE_CURRENT_BINARY_DIR}/git/${TARGET}" PARENT_SCOPE)
endfunction()

function(_t_git_create_stage1_script SCRIPT_PATH)
    get_filename_component(BASE_DIR ${SCRIPT_PATH} DIRECTORY)

    set(OUTPUT_PATH "${BASE_DIR}/git-info.stage1")
    set(WORKSPACE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
    
    configure_file(${_T_GIT_STAGE1_SCRIPT_TEMPLATE_PATH} ${SCRIPT_PATH}
        @ONLY
    )
endfunction()

function(_t_git_create_stage2_script SCRIPT_PATH INC_DIR HDR_INC_PATH)
    get_filename_component(BASE_DIR ${SCRIPT_PATH} DIRECTORY)

    set(INPUT_FILE "${BASE_DIR}/git-info.stage2")
    set(GIT_HDR_TEMPLATE_PATH ${_T_GIT_HDR_TEMPLATE_PATH})
    set(OUTPUT_PATH "${INC_DIR}/${HDR_INC_PATH}")

    set(INCLUDE_GAURD_DEF ${HDR_INC_PATH})
    string(REPLACE "/" "_" INCLUDE_GAURD_DEF ${INCLUDE_GAURD_DEF})
    string(REPLACE "\\" "_" INCLUDE_GAURD_DEF ${INCLUDE_GAURD_DEF})
    string(REPLACE "." "_" INCLUDE_GAURD_DEF ${INCLUDE_GAURD_DEF})
    string(TOUPPER ${INCLUDE_GAURD_DEF} INCLUDE_GAURD_DEF)
    string(PREPEND INCLUDE_GAURD_DEF "GIT_")
    string(APPEND INCLUDE_GAURD_DEF "_INCLUDED")

    configure_file(${_T_GIT_STAGE2_SCRIPT_TEMPLATE_PATH} ${SCRIPT_PATH}
        @ONLY
    )
endfunction()


#=========================================================
# PUBLIC MEMBERS
#=========================================================

function(t_git_target_add_header TARGET HDR_INC_PATH)
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
        COMMENT "Generating ${HDR_INC_PATH}"
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