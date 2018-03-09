include(vcpkg_common_functions)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO wxFormBuilder/ticpp
    # REF 8812a5832aab6beba06c978e1ade059b9a32855f 
    REF master
    SHA512 aac9a51bd4a344e36f11ed47d0cdf6b633817d23a9bb51a470943468ed47540a1b2463a148d99ed52bbf76ce8ec103a30335fd846b106804eadb58ccf99d7215
    HEAD_REF master
)

# =========================================
# ticpp and tinyxml both have an include file name tinyxml.h (at a minimum...)
# This blob of crap here will attempt to patch all the source code
# and rename tinyxml.h to ticpp_tinyxml.h
# as well as fix up any include guards
if(EXISTS ${SOURCE_PATH}/ticpp_tinyxml.h)
    message("== Skipping patching the source, it looks like it's already been done")
else()
    message("== Patching the source to avoid duplicate include files")
    find_program(GIT NAMES git git.cmd)

    # sed and awk are installed with git but in a different directory
    file(GLOB SED_INCLUDE_FILES "${SOURCE_PATH}/*.h")
    file(GLOB SED_SOURCE_FILES "${SOURCE_PATH}/*.cpp")
    list(APPEND SED_SOURCE_FILES ${SED_INCLUDE_FILES})
    get_filename_component(GIT_EXE_PATH ${GIT} DIRECTORY)
    set(SED_EXE_PATH ${GIT_EXE_PATH}/../usr/bin)
    set(SED_EXE ${SED_EXE_PATH}/sed)
    foreach(_file ${SED_SOURCE_FILES})
        execute_process(COMMAND cmd /c ${SED_EXE} -i.OLD -e "s/tinyxml\.h/ticpp_tinyxml.h/" "${_file}"
    #        RESULT_VARIABLE SED_ERR
        )
    #    message("SED_ERR: ${SED_ERR}")
    endforeach()    
    file(RENAME ${SOURCE_PATH}/tinyxml.h ${SOURCE_PATH}/ticpp_tinyxml.h)
endif()
# =========================================

if(MSVC)
    set(CMAKE_DEBUG_POSTFIX "d")
    add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
    add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR})
endif()

message("\n== Removing build tree detritus...")
file(REMOVE_RECURSE ${SOURCE_PATH}/tests)
file(GLOB BUILD_DETRITUS ${SOURCE_PATH}/*.lua)
list(APPEND BUILD_DETRITUS "${SOURCE_PATH}/dox")
list(APPEND BUILD_DETRITUS "${SOURCE_PATH}/appveyor.yml")
list(APPEND BUILD_DETRITUS "${SOURCE_PATH}/tutorial_ticpp.txt")
list(APPEND BUILD_DETRITUS "${SOURCE_PATH}/tutorial_gettingStarted.txt")
list(APPEND BUILD_DETRITUS "${SOURCE_PATH}/build_instructions.txt")
foreach(_file ${BUILD_DETRITUS})
    file(REMOVE "${_file}")
endforeach()

vcpkg_apply_patches(
    SOURCE_PATH ${SOURCE_PATH}
    PATCHES
        "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt.patch"
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    # DISABLE_PARALLEL_CONFIGURE
    # GENERATOR is ignored (ninja is used) if DISABLE_PARALLEL_CONFIGURE is not passed in
    # GENERATOR "NMake Makefiles"
    OPTIONS
        #-DSKIP_INSTALL_FILES=ON
        #-DSKIP_BUILD_EXAMPLES=ON
        #-LAH
        #--trace
        #--trace-expand
        #--warn-uninitialized
        #--warn-unused-vars
        #--debug-output
        #--debug-trycompile
        # OPTIONS_RELEASE -DOPTIMIZE=1
        # OPTIONS_DEBUG -DDEBUGGABLE=1
    OPTIONS_DEBUG
        #-DSKIP_INSTALL_HEADERS=ON
)

vcpkg_install_cmake()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

# Handle copyright
file(COPY ${SOURCE_PATH}/README.md DESTINATION ${CURRENT_PACKAGES_DIR}/share/ticpp)
file(COPY ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/ticpp)
file(RENAME ${CURRENT_PACKAGES_DIR}/share/ticpp/LICENSE ${CURRENT_PACKAGES_DIR}/share/ticpp/copyright)
