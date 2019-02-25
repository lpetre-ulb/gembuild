#.rst:
# FindCACTUS
# ----------
#
# Finds CACTUS include directory and libraries

include(CMakeParseArguments)

# List of all supported libs
set(cactus_all_libs "")

# Declares a library that can be required using the COMPONENTS argument
function(cactus_library name)
    cmake_parse_arguments(ARG "THREADS" "HEADER" "DEPENDS" "" ${ARGN})

    set(cactus_${name}_header ${ARG_HEADER} PARENT_SCOPE)
    set(cactus_${name}_depends ${ARG_DEPENDS} PARENT_SCOPE)
    list(APPEND cactus_all_libs ${name})
    set(cactus_all_libs "${cactus_all_libs}" PARENT_SCOPE)
endfunction()

# List all supported libs and their dependencies
cactus_library(uhal_uhal HEADER "uhal/uhal.hpp")
cactus_library(amc13_amc13 HEADER "amc13/AMC13Simple.hh")
cactus_library(amc13_tools HEADER "amc13/AMC13.hh" DEPENDS amc13_amc13)

# If the list of libs isn't specified, assume all of them are needed
if(NOT CACTUS_FIND_COMPONENTS)
    set(CACTUS_FIND_COMPONENTS "${cactus_all_libs}")
endif()

# Version numbers are not supported
if(CACTUS_FIND_VERSION)
    message(WARNING "CACTUS version ${CACTUS_FIND_VERSION} was requested, but version checking is not supported")
endif()

# Add dependencies to the list of libs
set(list_of_libs "")
foreach(lib ${CACTUS_FIND_COMPONENTS})
    list(APPEND list_of_libs ${lib})
    list(APPEND list_of_libs ${cactus_${lib}_depends})
endforeach()
list(REMOVE_DUPLICATES list_of_libs)

# Creates an imported target for the given lib
function(cactus_import_lib name)
    # Check that the lib exists
    list(FIND "${cactus_all_libs}" ${name} found)
    if(NOT found EQUAL -1)
        if(CACTUS_FIND_REQUIRED)
            message(SEND_ERROR "CACTUS library ${name} was requested, but it doesn't exist. This is probably due to a programming error.")
        else()
            # Do not create the target
            return()
        endif()
    endif()

    # Try to find the library
    find_library(
        cactus_${name}_library
        cactus_${name}
        NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH
        HINTS ENV CACTUS_ROOT
        PATHS /opt/cactus/
        PATH_SUFFIXES lib lib64
        DOC "Root directory of the CACTUS installation")

    if(NOT cactus_${name}_library)
        if(CACTUS_FIND_REQUIRED)
            message(SEND_ERROR "Could not find shared object file for CACTUS library ${name}")
        else()
            # Do not create the target
            return()
        endif()
    endif()

    # Try to find the headers
    find_file(
        cactus_${name}_header_location
        ${cactus_${name}_header}
        NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH
        HINTS ENV CACTUS_ROOT
        PATHS /opt/cactus/
        PATH_SUFFIXES include
        DOC "Root directory of the CACTUS installation")

    if(NOT cactus_${name}_header_location)
        if(CACTUS_FIND_REQUIRED)
            message(SEND_ERROR "Could not find header files for CACTUS library ${name}")
        else()
            # Do not create the target
            return()
        endif()
    endif()
    # Remove the trailing part of the path
    string(REPLACE ${cactus_${name}_header} ""
                   cactus_${name}_header_location ${cactus_${name}_header_location})

    # Create target
    add_library(CACTUS::${name} SHARED IMPORTED)

    # Set location
    set_property(
        TARGET CACTUS::${name}
        PROPERTY IMPORTED_LOCATION
        ${cactus_${name}_library})

    # Set include path
    set_property(
        TARGET CACTUS::${name}
        APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES
        ${cactus_${name}_header_location})
    set_property(
        TARGET CACTUS::${name}
        APPEND PROPERTY INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
        ${cactus_${name}_header_location})

    # Dependencies aren't written into .so as they should be, so we need to
    # link explicitely
    foreach(dep ${cactus_${name}_depends})
        set_property(
            TARGET CACTUS::${name}
            APPEND PROPERTY INTERFACE_LINK_LIBRARIES
            CACTUS::${dep})
    endforeach()

    # Some libs need threading support
    if(${cactus_${name}_threads})
        set_property(
            TARGET CACTUS::${name}
            APPEND PROPERTY INTERFACE_LINK_LIBRARIES
            ${CMAKE_THREAD_LIBS_INIT})
    endif()
endfunction()

# Import all libs
foreach(lib IN LISTS list_of_libs)
    cactus_import_lib(${lib})
endforeach()

# Print some debug info
message(STATUS "Found the following CACTUS libraries:")
foreach(lib ${list_of_libs})
    message(STATUS "  ${lib}")
endforeach()
