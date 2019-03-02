#.rst:
# FindxDAQ
# --------
#
# Finds xDAQ include directory and libraries

include(CMakeParseArguments)

# Exported variables
set(xDAQ_FOUND TRUE)

# List of all supported libs
set(xdaq_all_libs "")

# Declares a library that can be required using the COMPONENTS argument
macro(_xdaq_library name)
    cmake_parse_arguments(ARG "THREADS;NO_SONAME" "HEADER" "DEPENDS" "" ${ARGN})

    set(xdaq_${name}_threads ${ARG_THREADS})
    set(xdaq_${name}_header ${ARG_HEADER})
    set(xdaq_${name}_depends ${ARG_DEPENDS})
    set(xdaq_${name}_nosoname ${ARG_NO_SONAME})
    list(APPEND xdaq_all_libs ${name})
endmacro()

# List all supported libs and their dependencies
_xdaq_library(asyncresolv HEADER "asyncresolv/config.h")
_xdaq_library(cgicc HEADER "cgicc/Cgicc.h")
_xdaq_library(config HEADER "config/PackageInfo.h" DEPENDS xcept NO_SONAME)
_xdaq_library(i2o HEADER "i2o/version.h" DEPENDS config toolbox xcept NO_SONAME)
_xdaq_library(log4cplus HEADER "log4cplus/config.hxx")
_xdaq_library(logudpappender HEADER "log4cplus/log4judpappender.h"
                             DEPENDS config log4cplus NO_SONAME)
_xdaq_library(logxmlappender HEADER "log/xmlappender/version.h"
                             DEPENDS config log4cplus NO_SONAME)
_xdaq_library(mimetic HEADER "mimetic/version.h")
_xdaq_library(occi HEADER "oci.h")
_xdaq_library(peer HEADER "pt/version.h" DEPENDS config toolbox xcept xoap
                   THREADS NO_SONAME)
_xdaq_library(toolbox HEADER "toolbox/version.h"
                      DEPENDS asyncresolv cgicc log4cplus THREADS NO_SONAME)
_xdaq_library(tstoreclient HEADER "tstore/client/version.h" NO_SONAME)
_xdaq_library(tstoreutils HEADER "tstore/utils/version.h" DEPENDS occi NO_SONAME)
_xdaq_library(tstore HEADER "tstore/version.h"
                     DEPENDS tstoreclient tstoreutils xalan-c
                     NO_SONAME)
_xdaq_library(xalan-c HEADER "xalanc/Include/XalanVersion.hpp")
_xdaq_library(xcept HEADER "xcept/version.h" DEPENDS config toolbox NO_SONAME)
_xdaq_library(xdata HEADER "xdata/version.h"
                    DEPENDS config mimetic toolbox xcept xerces-c xoap THREADS
                    NO_SONAME)
_xdaq_library(xdaq HEADER "xdaq/version.h"
                   DEPENDS config log4cplus logudpappender logxmlappender peer
                           toolbox xcept xdata xerces-c xgi xoap
                   NO_SONAME)
_xdaq_library(xdaq2rc HEADER "xdaq2rc/version.h"
                      DEPENDS config log4cplus toolbox xdaq xdata xerces-c xoap
                      THREADS NO_SONAME)
_xdaq_library(xerces-c HEADER "xercesc/util/XercesVersion.hpp")
_xdaq_library(xgi HEADER "xgi/version.h"
                  DEPENDS cgicc config toolbox xcept xerces-c THREADS NO_SONAME)
_xdaq_library(xoap HEADER "xoap/version.h"
                   DEPENDS config toolbox xcept xerces-c
                   NO_SONAME)

# Build recursive dep lists
macro(_xdaq_build_recursive_depends lib)
    if(NOT DEFINED xdaq_${lib}_recursive_depends) # Prevent infinite recursion
        set(xdaq_${lib}_recursive_depends "${xdaq_${lib}_depends}")
        foreach(dep ${xdaq_${lib}_depends})
            _xdaq_build_recursive_depends(${dep})
            foreach(recdep ${xdaq_${dep}_recursive_depends})
                list(APPEND xdaq_${lib}_recursive_depends ${recdep})
            endforeach()
        endforeach()
        list(REMOVE_DUPLICATES xdaq_${lib}_recursive_depends)
    endif()
endmacro()

foreach(lib ${xdaq_all_libs})
    _xdaq_build_recursive_depends(${lib})
endforeach()

# If the list of libs isn't specified, assume all of them are needed
if(NOT DEFINED xDAQ_FIND_COMPONENTS)
    set(xDAQ_FIND_COMPONENTS "${xdaq_all_libs}")
endif()

# Version numbers are not supported
if(xDAQ_FIND_VERSION)
    message(WARNING "xDAQ version ${xDAQ_FIND_VERSION} was requested, but version checking is not supported")
endif()

# Check that all requested libs are known
foreach(lib ${xDAQ_FIND_COMPONENTS})
    list(FIND xdaq_all_libs ${lib} found)
    if(found EQUAL -1)
        set(xDAQ_FOUND FALSE)
        list(REMOVE_ITEM xDAQ_FIND_COMPONENTS ${lib})

        # Notify user
        set(msg_type STATUS)
        if(xDAQ_FIND_REQUIRED)
            set(msg_type SEND_ERROR)
        endif()
        if(NOT xDAQ_FIND_QUIETLY)
            message(${msg_type} "Unknown xDAQ library ${lib} was requested. This is probably due to a programming error.")
        endif()
        unset(msg_type)
    endif()
    unset(found)
endforeach()

# Turn the recursive list of dependencies into a list of required variables
foreach(lib ${xDAQ_FIND_COMPONENTS})
    set(xdaq_${lib}_required_variables xDAQ_${lib}_LIBRARY xDAQ_${lib}_INCLUDE_DIR)
    foreach(dep ${xdaq_${lib}_recursive_depends})
        list(APPEND xdaq_${lib}_required_variables
             xDAQ_${dep}_LIBRARY xDAQ_${dep}_INCLUDE_DIR)
    endforeach()
endforeach()

# Build the list of all required libraries with dependencies included
set(xdaq_requested_libs ${xDAQ_FIND_COMPONENTS})
foreach(lib ${xDAQ_FIND_COMPONENTS})
    list(APPEND xdaq_requested_libs ${xdaq_${lib}_recursive_depends})
endforeach()
list(REMOVE_DUPLICATES xdaq_requested_libs)

# Are threads required?
foreach(lib ${xdaq_requested_libs})
    if(xdaq_${lib}_threads)
        set(xdaq_need_threads TRUE)
    endif()
endforeach()

# Find threads
if(xdaq_need_threads)
    find_package(Threads QUIET)
endif()

# Sets xDAQ_FOUND to FALSE if the given library isn't optional
function(_xdaq_lib_not_found lib)
    if(NOT xDAQ_FIND_REQUIRED_${lib})
        set(xDAQ_FOUND FALSE)
    endif()
endfunction()

# Creates an imported target for the given lib
macro(_xdaq_import_lib name)

    # Do nothing if already found or being looked after
    if(NOT TARGET xDAQ::${name})

        # We haven't found anything yet
        set(xDAQ_${name}_FOUND FALSE)
        set(xdaq_${name}_deps_found TRUE)
        set(xdaq_${name}_searching TRUE)

        # Try to find dependencies
        foreach(dep ${xdaq_${name}_depends})
            if(NOT xdaq_${dep}_searching) # Prevent infinite recursion
                _xdaq_import_lib(${dep})

                if(NOT xDAQ_${dep}_FOUND)
                    set(xdaq_${name}_deps_found FALSE)
                    _xdaq_lib_not_found(${dep})
                endif()
            endif()
        endforeach()

        # Threads dependency
        if(xdaq_${name}_threads AND NOT Threads_FOUND)
            set(xdaq_${name}_deps_found FALSE)
            _xdaq_lib_not_found(${name})
        endif()

        # toolbox requires libuuid from the system
        if(${name} STREQUAL "toolbox")
            find_library(xDAQ_uuid_LIBRARY uuid)
            mark_as_advanced(xDAQ_uuid_LIBRARY)

            if(NOT xDAQ_uuid_LIBRARY)
                _xdaq_lib_not_found(uuid)
                set(xdaq_toolbox_deps_found FALSE)
            endif()
        endif()

        # Try to find the library
        find_library(
            xDAQ_${name}_LIBRARY
            ${name}
            NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH
            HINTS ENV XDAQ_ROOT
            PATHS /opt/xdaq/
            PATH_SUFFIXES lib lib64
            DOC "Root directory of the xDAQ installation")

        mark_as_advanced(xDAQ_${name}_LIBRARY)

        # Try to find the headers
        find_path(
            xDAQ_${name}_INCLUDE_DIR
            ${xdaq_${name}_header}
            NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH
            HINTS ENV XDAQ_ROOT
            PATHS /opt/xdaq/
            PATH_SUFFIXES include
            DOC "Root directory of the xDAQ installation")

        mark_as_advanced(xDAQ_${name}_INCLUDE_DIR)

        if(xdaq_${name}_deps_found AND xDAQ_${name}_LIBRARY
                                   AND xDAQ_${name}_INCLUDE_DIR)
            # Found!
            set(xDAQ_${name}_FOUND TRUE)

            # Create the target
            add_library(xDAQ::${name} SHARED IMPORTED)

            # Set location
            set_property(
                TARGET xDAQ::${name}
                PROPERTY IMPORTED_LOCATION
                ${xDAQ_${name}_LIBRARY})

            # Handle NO_SONAME
            if(xdaq_${name}_nosoname)
                set_property(TARGET xDAQ::${name} PROPERTY IMPORTED_NO_SONAME TRUE)
            endif()

            # Set include path
            set_target_properties(
                xDAQ::${name}
                PROPERTIES
                INTERFACE_INCLUDE_DIRECTORIES
                "${xDAQ_${name}_INCLUDE_DIR};${xDAQ_${name}_INCLUDE_DIR}/linux"
                INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
                "${xDAQ_${name}_INCLUDE_DIR};${xDAQ_${name}_INCLUDE_DIR}/linux")

            # Dependencies aren't written into .so as they should be, so we need to
            # link explicitely
            foreach(dep ${xdaq_${name}_depends})
                set_property(
                    TARGET xDAQ::${name}
                    APPEND PROPERTY INTERFACE_LINK_LIBRARIES
                    xDAQ::${dep})
            endforeach()

            # Some libs need threading support
            if(${xdaq_${name}_threads})
                set_property(
                    TARGET xDAQ::${name}
                    APPEND PROPERTY INTERFACE_LINK_LIBRARIES
                    ${CMAKE_THREAD_LIBS_INIT})
            endif()
        endif()

        # Cleanup
        unset(xdaq_${name}_deps_found)
        unset(xdaq_${name}_searching)

    endif()
endmacro()

# Import all libs
foreach(lib IN LISTS xDAQ_FIND_COMPONENTS)
    _xdaq_import_lib(${lib})
endforeach()

# Wrap things up
set(xDAQ_LIBRARIES "")
set(xDAQ_INCLUDE_DIRS "")

foreach(lib ${xDAQ_FIND_COMPONENTS})
    find_package_handle_standard_args(
        xDAQ_${lib}
        FOUND_VAR xDAQ_${lib}_FOUND
        REQUIRED_VARS ${xdaq_${lib}_required_variables})

    list(APPEND xDAQ_LIBRARIES ${xDAQ_${lib}_LIBRARY})
    list(APPEND xDAQ_INCLUDE_DIRS ${xDAQ_${lib}_INCLUDE_DIR})
endforeach()

list(REMOVE_DUPLICATES xDAQ_LIBRARIES)
list(REMOVE_DUPLICATES xDAQ_INCLUDE_DIRS)

find_package_handle_standard_args(
    xDAQ
    FOUND_VAR xDAQ_FOUND
    REQUIRED_VARS xDAQ_LIBRARIES xDAQ_INCLUDE_DIRS
    VERSION_VAR xDAQ_VERSION
    HANDLE_COMPONENTS)

# i2o requires an additional definition
if(TARGET xDAQ::i2o)
    set_property(TARGET xDAQ::i2o
                 APPEND PROPERTY INTERFACE_COMPILE_DEFINITIONS
                 LITTLE_ENDIAN__)
endif()

# toolbox requires libuuid from the system
# It is guaranteed that xDAQ_toolbox_FOUND is FALSE when libuuid is not found
if(xDAQ_toolbox_FOUND)
    set_property(TARGET xDAQ::toolbox
                 APPEND PROPERTY INTERFACE_LINK_LIBRARIES
                 ${xDAQ_uuid_LIBRARY})
endif()

# Cleanup
foreach(name ${xdaq_all_libs})
    unset(xdaq_${name}_threads)
    unset(xdaq_${name}_header)
    unset(xdaq_${name}_depends)
    unset(xdaq_${name}_nosoname)
    unset(xdaq_${name}_recursive_depends)
    unset(xdaq_${name}_required_variables)
endforeach()

unset(xdaq_need_threads)
unset(xdaq_all_libs)
unset(xdaq_requested_libs)
