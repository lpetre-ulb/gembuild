#.rst:
# FindxDAQ
# --------
#
# Finds xDAQ include directory and libraries

include(CMakeParseArguments)

# Check for threading libraries only if required
set(xdaq_need_threads FALSE)

# List of all supported libs
set(xdaq_all_libs "")

# Declares a library that can be required using the COMPONENTS argument
function(xdaq_library name)
    cmake_parse_arguments(ARG "THREADS" "HEADER" "DEPENDS" "" ${ARGN})

    if(${ARG_THREADS})
        set(xdaq_need_threads TRUE PARENT_SCOPE)
    endif()
    set(xdaq_${name}_threads ${ARG_THREADS} PARENT_SCOPE)
    set(xdaq_${name}_header ${ARG_HEADER} PARENT_SCOPE)
    set(xdaq_${name}_depends ${ARG_DEPENDS} PARENT_SCOPE)
    list(APPEND xdaq_all_libs ${name})
    set(xdaq_all_libs "${xdaq_all_libs}" PARENT_SCOPE)
endfunction()

# List all supported libs and their dependencies
xdaq_library(asyncresolv HEADER "asyncresolv/config.h")
xdaq_library(cgicc HEADER "cgicc/Cgicc.h")
xdaq_library(config HEADER "config/PackageInfo.h" DEPENDS xcept)
xdaq_library(i2o HEADER "i2o/version.h" DEPENDS config toolbox xcept)
xdaq_library(log4cplus HEADER "log4cplus/config.hxx")
xdaq_library(logudpappender HEADER "log4cplus/log4judpappender.h"
                            DEPENDS config log4cplus)
xdaq_library(logxmlappender HEADER "log/xmlappender/version.h"
                            DEPENDS config log4cplus)
xdaq_library(mimetic HEADER "mimetic/version.h")
xdaq_library(peer HEADER "pt/version.h" DEPENDS config toolbox xcept xoap THREADS)
xdaq_library(toolbox HEADER "toolbox/version.h"
                     DEPENDS asyncresolv cgicc log4cplus THREADS)
xdaq_library(tstoreclient HEADER "tstore/client/version.h")
xdaq_library(tstoreutils HEADER "tstore/utils/version.h")
xdaq_library(tstore HEADER "tstore/version.h" DEPENDS tstoreclient tstoreutils xalan-c)
xdaq_library(xalan-c HEADER "xalanc/Include/XalanVersion.hpp")
xdaq_library(xcept HEADER "xcept/version.h" DEPENDS config toolbox)
xdaq_library(xdata HEADER "xdata/version.h"
                   DEPENDS config mimetic toolbox xcept xerces-c xoap THREADS)
xdaq_library(xdaq HEADER "xdaq/version.h"
                  DEPENDS config log4cplus logudpappender logxmlappender peer
                          toolbox xcept xdata xerces-c xgi xoap)
xdaq_library(xdaq2rc HEADER "xdaq2rc/version.h"
                     DEPENDS config log4cplus toolbox xdaq xdata xerces-c xoap THREADS)
xdaq_library(xerces-c HEADER "xercesc/util/XercesVersion.hpp")
xdaq_library(xgi HEADER "xgi/version.h"
                 DEPENDS cgicc config toolbox xcept xerces-c THREADS)
xdaq_library(xoap HEADER "xoap/version.h" DEPENDS config toolbox xcept xerces-c)

# If the list of libs isn't specified, assume all of them are needed
if(NOT xDAQ_FIND_COMPONENTS)
    set(xDAQ_FIND_COMPONENTS "${xdaq_all_libs}")
endif()

# Version numbers are not supported
if(xDAQ_FIND_VERSION)
    message(WARNING "xDAQ version ${xDAQ_FIND_VERSION} was requested, but version checking is not supported")
endif()

# Threads
if(xdaq_need_threads)
    find_package(Threads QUIET)
endif()

# Add dependencies to the list of libs
set(list_of_libs "")
foreach(lib ${xDAQ_FIND_COMPONENTS})
    list(APPEND list_of_libs ${lib})
    list(APPEND list_of_libs ${xdaq_${lib}_depends})
endforeach()
list(REMOVE_DUPLICATES list_of_libs)

# Creates an imported target for the given lib
function(xdaq_import_lib name)
    # Check that the lib exists
    list(FIND "${xdaq_all_libs}" ${name} found)
    if(NOT found EQUAL -1)
        if(xDAQ_FIND_REQUIRED)
            message(SEND_ERROR "xDAQ library ${name} was requested, but it doesn't exist. This is probably due to a programming error.")
        else()
            # Do not create the target
            return()
        endif()
    endif()

    # Try to find the library
    find_library(
        xdaq_${name}_library
        ${name}
        PATHS /opt/xdaq/
        ENV XDAQ_ROOT
        PATH_SUFFIXES lib lib64
        DOC "Root directory of the xDAQ installation")

    if(NOT xdaq_${name}_library)
        if(xDAQ_FIND_REQUIRED)
            message(SEND_ERROR "Could not find shared object file for xDAQ library ${name}")
        else()
            # Do not create the target
            return()
        endif()
    endif()

    # Try to find the headers
    find_file(
        xdaq_${name}_header_location
        ${xdaq_${name}_header}
        PATHS /opt/xdaq/
        ENV XDAQ_ROOT
        PATH_SUFFIXES include
        DOC "Root directory of the xDAQ installation")

    if(NOT xdaq_${name}_header_location)
        if(xDAQ_FIND_REQUIRED)
            message(SEND_ERROR "Could not find header files for xDAQ library ${name}")
        else()
            # Do not create the target
            return()
        endif()
    endif()
    # Remove the trailing part of the path
    string(REPLACE ${xdaq_${name}_header} ""
                   xdaq_${name}_header_location ${xdaq_${name}_header_location})

    # Create target
    add_library(xDAQ::${name} SHARED IMPORTED)

    # Set location
    set_property(
        TARGET xDAQ::${name}
        PROPERTY IMPORTED_LOCATION
        ${xdaq_${name}_library})

    # Set include path
    set_property(
        TARGET xDAQ::${name}
        APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES
        ${xdaq_${name}_header_location})
    set_property(
        TARGET xDAQ::${name}
        APPEND PROPERTY INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
        ${xdaq_${name}_header_location})
    set_property(
        TARGET xDAQ::${name}
        APPEND PROPERTY INTERFACE_INCLUDE_DIRECTORIES
        ${xdaq_${name}_header_location}/linux)
    set_property(
        TARGET xDAQ::${name}
        APPEND PROPERTY INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
        ${xdaq_${name}_header_location}/linux)

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
foreach(lib IN LISTS list_of_libs)
    xdaq_import_lib(${lib})
endforeach()

# Print some debug info
message(STATUS "Found the following xDAQ libraries:")
foreach(lib ${list_of_libs})
    message(STATUS "  ${lib}")
endforeach()

# i2o requires an additional definition
list(FIND list_of_libs i2o found)
if(NOT found EQUAL -1)
    set_property(TARGET xDAQ::i2o
                 APPEND PROPERTY INTERFACE_COMPILE_DEFINITIONS
                 LITTLE_ENDIAN__)
endif()

# toolbox requires libuuid from the system
list(FIND list_of_libs toolbox found)
if(NOT found EQUAL -1)
    find_library(xdaq_uuid_library uuid)
    # Maybe we shouldn't fail if not REQUIRED...
    if(NOT xdaq_uuid_library)
        message(SEND_ERROR "Could not find libuuid, required by xDAQ library toolbox")
    endif()
    set_property(TARGET xDAQ::toolbox
                 APPEND PROPERTY INTERFACE_LINK_LIBRARIES
                 ${xdaq_uuid_library})
endif()
