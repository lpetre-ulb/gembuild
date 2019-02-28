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
function(_xdaq_library name)
    cmake_parse_arguments(ARG "THREADS;NO_SONAME" "HEADER" "DEPENDS" "" ${ARGN})

    set(xdaq_${name}_threads ${ARG_THREADS} PARENT_SCOPE)
    set(xdaq_${name}_header ${ARG_HEADER} PARENT_SCOPE)
    set(xdaq_${name}_depends ${ARG_DEPENDS} PARENT_SCOPE)
    set(xdaq_${name}_nosoname ${ARG_NO_SONAME} PARENT_SCOPE)
    list(APPEND xdaq_all_libs ${name})
    set(xdaq_all_libs "${xdaq_all_libs}" PARENT_SCOPE)
endfunction()

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

# If the list of libs isn't specified, assume all of them are needed
if(NOT xDAQ_FIND_COMPONENTS)
    set(xDAQ_FIND_COMPONENTS "${xdaq_all_libs}")
endif()

# Version numbers are not supported
if(xDAQ_FIND_VERSION)
    message(WARNING "xDAQ version ${xDAQ_FIND_VERSION} was requested, but version checking is not supported")
endif()

# Check that all requested libs are known
foreach(lib ${xDAQ_FIND_COMPONENTS})
    list(FIND "${xdaq_all_libs}" ${lib} found)
    if(NOT found EQUAL -1)
        if(xDAQ_FIND_REQUIRED)
            message(SEND_ERROR "Unknown xDAQ library ${lib} was requested. This is probably due to a programming error.")
        endif()
        set(xDAQ_FOUND FALSE)
        set(xDAQ_${ulib}_FOUND FALSE)
        message("a false")
        list(REMOVE_ITEM xDAQ_FIND_COMPONENTS ${lib})
    endif()
endforeach()

# Check for threading libraries only if required
set(xdaq_need_threads FALSE)

# Add dependencies to the list of libs
set(xdaq_required_libs "")
foreach(lib ${xDAQ_FIND_COMPONENTS})
    list(APPEND xdaq_required_libs ${lib})
    list(APPEND xdaq_required_libs ${xdaq_${lib}_depends})

    if(xdaq_${name}_threads)
        set(xdaq_need_threads TRUE)
    endif()
endforeach()
list(REMOVE_DUPLICATES xdaq_required_libs)

# Threads
if(xdaq_need_threads)
    find_package(Threads QUIET)
endif()

# Creates an imported target for the given lib
function(_xdaq_import_lib name)
    string(TOUPPER ${name} uname)
    set(xDAQ_${uname}_FOUND TRUE PARENT_SCOPE)

    # Try to find the library
    find_library(
        xDAQ_${uname}_LIBRARY
        ${name}
        NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH
        HINTS ENV XDAQ_ROOT
        PATHS /opt/xdaq/
        PATH_SUFFIXES lib lib64
        DOC "Root directory of the xDAQ installation")

    mark_as_advanced(xDAQ_${uname}_LIBRARY)

    if(NOT xDAQ_${uname}_LIBRARY)
        set(xDAQ_FOUND FALSE PARENT_SCOPE)
        set(xDAQ_${uname}_FOUND FALSE PARENT_SCOPE)

        if(xDAQ_FIND_REQUIRED)
            message(SEND_ERROR "Could not find shared object file for xDAQ library ${name}")
        endif()
        # Do not create the target
        return()
    endif()

    # Try to find the headers
    find_path(
        xDAQ_${uname}_INCLUDE_DIR
        ${xdaq_${name}_header}
        NO_CMAKE_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH
        HINTS ENV XDAQ_ROOT
        PATHS /opt/xdaq/
        PATH_SUFFIXES include
        DOC "Root directory of the xDAQ installation")

    mark_as_advanced(xDAQ_${uname}_INCLUDE_DIR)

    if(NOT xDAQ_${uname}_INCLUDE_DIR)
        set(xDAQ_FOUND FALSE PARENT_SCOPE)
        set(xDAQ_${uname}_FOUND FALSE PARENT_SCOPE)

        if(xDAQ_FIND_REQUIRED)
            message(SEND_ERROR "Could not find header files for xDAQ library ${name}")
        endif()
        # Do not create the target
        return()
    endif()

    # Create target
    add_library(xDAQ::${name} SHARED IMPORTED)

    # Set location
    set_property(
        TARGET xDAQ::${name}
        PROPERTY IMPORTED_LOCATION
        ${xDAQ_${uname}_LIBRARY})

    # Handle NO_SONAME
    if(xdaq_${name}_nosoname)
        set_property(TARGET xDAQ::${name} PROPERTY IMPORTED_NO_SONAME TRUE)
    endif()

    # Set include path
    set_property(
        TARGET xDAQ::${name}
        APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES
        ${xDAQ_${uname}_INCLUDE_DIR})
    set_property(
        TARGET xDAQ::${name}
        APPEND PROPERTY INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
        ${xDAQ_${uname}_INCLUDE_DIR})
    set_property(
        TARGET xDAQ::${name}
        APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES
        ${xDAQ_${uname}_INCLUDE_DIR}/linux)
    set_property(
        TARGET xDAQ::${name}
        APPEND PROPERTY INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
        ${xDAQ_${uname}_INCLUDE_DIR}/linux)

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
endfunction()

# Import all libs
foreach(lib IN LISTS xdaq_required_libs)
    _xdaq_import_lib(${lib})
endforeach()

# Print some debug info
if(NOT xDAQ_FOUND)
    message(STATUS "The following xDAQ libraries are missing:")
    foreach(lib ${xdaq_required_libs})
        string(TOUPPER ${lib} ulib)
        if(NOT xDAQ_${ulib}_FOUND)
            message(STATUS "  ${lib}")
        endif()
    endforeach()
endif()

message(STATUS "Found the following xDAQ libraries:")
foreach(lib ${xdaq_required_libs})
    string(TOUPPER ${lib} ulib)
    if(xDAQ_${ulib}_FOUND)
        message(STATUS "  ${lib}")
    endif()
endforeach()

# i2o requires an additional definition
list(FIND xdaq_required_libs i2o found)
if(NOT found EQUAL -1)
    set_property(TARGET xDAQ::i2o
                 APPEND PROPERTY INTERFACE_COMPILE_DEFINITIONS
                 LITTLE_ENDIAN__)
endif()
unset(found)

# toolbox requires libuuid from the system
list(FIND xdaq_required_libs toolbox found)
if(NOT found EQUAL -1)
    find_library(xdaq_uuid_library uuid)
    mark_as_advanced(xdaq_uuid_library)

    # Maybe we shouldn't fail if not REQUIRED...
    if(NOT xdaq_uuid_library)
        message(SEND_ERROR "Could not find libuuid, required by xDAQ library toolbox")
        set(xDAQ_FOUND FALSE)
    endif()
    set_property(TARGET xDAQ::toolbox
                 APPEND PROPERTY INTERFACE_LINK_LIBRARIES
                 ${xdaq_uuid_library})
endif()
unset(found)

# Cleanup
foreach(lib ${xdaq_all_libs})
    unset(xdaq_${name}_threads)
    unset(xdaq_${name}_header)
    unset(xdaq_${name}_depends)
    unset(xdaq_${name}_nosoname)
endforeach()

unset(xdaq_need_threads)
unset(xdaq_all_libs)
unset(xdaq_required_libs)
