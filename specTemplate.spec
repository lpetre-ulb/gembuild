%define _package __package__
%define _packagename __packagename__
%define _version __version__
%define _release __release__
%define _prefix  __prefix__
%define _sources_dir __sources_dir__
%define _tmppath /tmp
%define _packagedir __packagedir__
%define _os __os__
%define _platform __platform__
%define _project __project__
%define _author __author__
%define _summary __summary__
%define _url __url__
%define _buildarch __buildarch__
#%define _includedirs __includedirs__

%define _unpackaged_files_terminate_build 0

#
# Binary RPM specified attributed (lib and bin)
#
Name: %{_project}-%{_packagename}
Summary: %{_summary}
Version: %{_version}
Release: %{_release}
Packager: %{_author}
#BuildArch: %{_buildarch}
License: __license_
# Group: Applications/extern
URL: %{_url}
BuildRoot: %{_tmppath}/%{_packagename}-%{_version}-%{_release}-buildroot
Prefix: %{_prefix}
#Requires: __requireslist__

%description
__description__

%pre

#%setup 

%build

#
# Prepare the list of files that are the input to the binary and devel RPMs
#
%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_prefix}/{bin,lib,include,scripts}

if [ -d %{_packagedir}/bin ]; then
  cd %{_packagedir}/bin; \
  find . -name "*"  -exec install -D -m 755 {} $RPM_BUILD_ROOT/%{_prefix}/bin/{} \;
fi

if [ -d %{_packagedir}/include ]; then
  cd %{_packagedir}/include; \
  find . \( -name "*.hpp"  -o -name "*.hxx" \)  -exec install -D -m 644 {} $RPM_BUILD_ROOT/%{_prefix}/include/{} \;
fi

if [ -d %{_packagedir}/lib ]; then
  cd %{_packagedir}/lib; \
  find . -name "*" -exec install -D -m 644 {} $RPM_BUILD_ROOT/%{_prefix}/lib/{} \;
fi

if [ -d %{_packagedir}/etc ]; then 
  cd %{_packagedir}/etc; \
  find ./ -name ".svn" -prune -o -name "*" -type f -exec install -D -m 655 {} $RPM_BUILD_ROOT/%{_prefix}/etc/{} \;
fi

if [ -d %{_packagedir}/scripts ]; then
  cd %{_packagedir}/scripts; \
  find ./ -name ".svn" -prune -o -name "*" -type f -exec install -D -m 655 {} $RPM_BUILD_ROOT/%{_prefix}/scripts/{} \;
fi

%clean
rm -rf $RPM_BUILD_ROOT

#
# Files that go in the binary RPM
#
%files
%defattr(-,root,root,-)

%dir
%{_prefix}/bin
%{_prefix}/lib
%{_prefix}/include
%{_prefix}/scripts

%post

%preun

%postun

%changelog

#%doc MAINTAINER ChangeLog README
