#.rst:
#
# FindCACTUS
# ----------
#
# This module can be used to find libraries provided by CACTUS. It can be used
# using the standard
# `find_package <https://cmake.org/cmake/help/latest/command/find_package.html>`_
# function. It is possible to specify the list of required libraries using the
# `COMPONENTS` and `OPTIONAL_COMPONENTS` arguments of `find_package` (all
# components are required if nothing is specified). The following libraries are
# supported:
#
# * `uhal_uhal`
# * `amc13_amc13`
# * `amc13_tools`
#
# A target of the form `CACTUS::<lib>` is created for every library.
# Dependencies are handled automatically.
#
# The following variables are set by this module:
#
# ::
#
#     CACTUS_FOUND          -- If CACTUS was found
#
#     CACTUS_INCLUDE_DIRS   -- CACTUS include directories
#     CACTUS_<lib>_LIBARRY  -- Location of the 'lib' library
#
# ..note::
#
#     Version checking is not supported because no version information is
#     present in the CACTUS headers.
#

include(CMakeParseArguments)
include(FindPackageHandleStandardArgs)

# Exported variables
set(CACTUS_FOUND TRUE)

# List of all supported libs
set(CACTUS_all_libs "")

# Declares a library that can be required using the COMPONENTS argument
macro(_cactus_library name)
    cmake_parse_arguments(ARG "NO_SONAME" "HEADER" "DEPENDS" ${ARGN})

    set(cactus_${name}_header ${ARG_HEADER})
    set(cactus_${name}_depends ${ARG_DEPENDS})
    set(cactus_${name}_nosoname ${ARG_NO_SONAME})
    list(APPEND cactus_all_libs ${name})
endmacro()

# List all supported libs and their dependencies
_cactus_library(uhal_uhal HEADER "uhal/uhal.hpp")
_cactus_library(amc13_amc13 HEADER "amc13/AMC13.hh" NO_SONAME)

# Build recursive dep lists
macro(_cactus_build_recursive_depends lib)
    if(NOT DEFINED cactus_${lib}_recursive_depends) # Prevent infinite recursion
        set(cactus_${lib}_recursive_depends "${cactus_${lib}_depends}")
        foreach(dep ${cactus_${lib}_depends})
            _cactus_build_recursive_depends(${dep})
            foreach(recdep ${cactus_${dep}_recursive_depends})
                list(APPEND cactus_${lib}_recursive_depends ${recdep})
            endforeach()
        endforeach()
        list(REMOVE_DUPLICATES cactus_${lib}_recursive_depends)
    endif()
endmacro()

foreach(lib ${cactus_all_libs})
    _cactus_build_recursive_depends(${lib})
endforeach()

# If the list of libs isn't specified, assume all of them are needed
if(NOT CACTUS_FIND_COMPONENTS)
    set(CACTUS_FIND_COMPONENTS "${cactus_all_libs}")
endif()

# Check that all requested libs are known
foreach(lib ${CACTUS_FIND_COMPONENTS})
    list(FIND cactus_all_libs ${lib} found)
    if(found EQUAL -1)
        set(CACTUS_FOUND FALSE)
        list(REMOVE_ITEM CACTUS_FIND_COMPONENTS ${lib})

        # Notify user
        set(msg_type STATUS)
        if(CACTUS_FIND_REQUIRED)
            set(msg_type SEND_ERROR)
        endif()
        if(NOT CACTUS_FIND_QUIETLY)
            message(${msg_type} "Unknown CACTUS library ${lib} was requested. This is probably due to a programming error.")
        endif()
        unset(msg_type)
    endif()
    unset(found)
endforeach()

# Build a list of all requested libraries with dependencies included
set(cactus_requested_libs ${CACTUS_FIND_COMPONENTS})
foreach(lib ${CACTUS_FIND_COMPONENTS})
    list(APPEND cactus_requested_libs ${cactus_${lib}_recursive_depends})
endforeach()
list(REMOVE_DUPLICATES cactus_requested_libs)

# Turn the recursive list of dependencies into a list of required variables
foreach(lib ${CACTUS_FIND_COMPONENTS})
    set(cactus_${lib}_required_variables CACTUS_${lib}_LIBRARY CACTUS_INCLUDE_DIRS)
    foreach(dep ${cactus_${lib}_recursive_depends})
        list(APPEND cactus_${lib}_required_variables CACTUS_${dep}_LIBRARY)
    endforeach()

    list(REMOVE_DUPLICATES cactus_${lib}_required_variables)
endforeach()

# Creates an imported target for the given lib
macro(_cactus_import_lib name)

    # Do nothing if already found
    if(NOT TARGET CACTUS::${name})

        # Try to find the library
        find_library(
            CACTUS_${name}_LIBRARY
            cactus_${name}
            NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH
            HINTS ENV CACTUS_ROOT
            PATHS /opt/cactus/
            PATH_SUFFIXES lib lib64
            DOC "Path of CACTUS library ${name}")

        mark_as_advanced(CACTUS_${name}_LIBRARY)

        # Try to find the headers
        find_path(
            CACTUS_INCLUDE_DIRS
            ${cactus_${name}_header}
            NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH
            HINTS ENV CACTUS_ROOT
            PATHS /opt/cactus/
            PATH_SUFFIXES include
            DOC "CACTUS include directory")

        mark_as_advanced(CACTUS_INCLUDE_DIRS)

        if(CACTUS_${name}_LIBRARY AND CACTUS_INCLUDE_DIRS)
            # Found!
            set(CACTUS_${name}_FOUND TRUE)

            # Create the target
            add_library(CACTUS::${name} SHARED IMPORTED)

            # Set location
            set_property(
                TARGET CACTUS::${name}
                PROPERTY IMPORTED_LOCATION
                ${CACTUS_${name}_LIBRARY})

            # Handle NO_SONAME
            if(cactus_${name}_nosoname)
                set_property(TARGET CACTUS::${name} PROPERTY IMPORTED_NO_SONAME TRUE)
            endif()

            # Set include path
            set_target_properties(
                CACTUS::${name}
                PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES "${CACTUS_INCLUDE_DIRS}"
                INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${CACTUS_INCLUDE_DIRS}")

            # Dependencies aren't written into .so as they should be, so we need to
            # link explicitely
            foreach(dep ${cactus_${name}_depends})
                set_property(
                    TARGET CACTUS::${name}
                    APPEND PROPERTY INTERFACE_LINK_LIBRARIES
                    CACTUS::${dep})
            endforeach()
        endif()
    endif()
endmacro()

# Import all libs
foreach(lib ${cactus_requested_libs})
    _cactus_import_lib(${lib})
endforeach()

# It looks like no version information is included in the headers
set(CACTUS_VERSION "unknown")

# Wrap things up
set(CACTUS_LIBRARIES "")

foreach(lib ${CACTUS_FIND_COMPONENTS})
    find_package_handle_standard_args(
        CACTUS_${lib}
        FOUND_VAR CACTUS_${lib}_FOUND
        REQUIRED_VARS ${cactus_${lib}_required_variables})

    list(APPEND CACTUS_LIBRARIES ${CACTUS_${lib}_LIBRARY})
endforeach()

list(REMOVE_DUPLICATES CACTUS_LIBRARIES)

find_package_handle_standard_args(
    CACTUS
    FOUND_VAR CACTUS_FOUND
    REQUIRED_VARS CACTUS_INCLUDE_DIRS CACTUS_LIBRARIES
    VERSION_VAR CACTUS_VERSION
    HANDLE_COMPONENTS)

# Cleanup
foreach(name ${cactus_all_libs})
    unset(cactus_${name}_header)
    unset(cactus_${name}_depends)
    unset(cactus_${name}_nosoname)
    unset(cactus_${name}_recursive_depends)
    unset(cactus_${name}_required_variables)
endforeach()

unset(cactus_all_libs)
unset(cactus_requested_libs)
