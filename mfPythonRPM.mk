# Created with insights from
## amc13/config/mfPythonRPMRules.mk

INSTALL_PATH = /opt/cmsgemos
ProjectPath  ?= $(BUILD_HOME)/$(Project)
PackagePath  ?= $(BUILD_HOME)/$(Project)
RPMBUILD_DIR = $(PackagePath)/rpm
# 

ifndef PythonModules
	$(error Python module names missing "PythonModules")
endif

.PHONY: rpm _rpmall _rpmprep _setup_update _rpmbuild _rpmdevbuild _rpmsetup
rpm: _rpmall
_rpmall: _all _rpmprep _setup_update _rpmsetup _rpmbuild

# Copy the package skeleton
# Ensure the existence of the module directory
# Copy the libraries into python module
_rpmsetup: _setup_update _rpmprep
# Change directory into pkg and copy everything into rpm build dir
	cd pkg && \
	find . -name "*" -exec install -D \{\} $(RPMBUILD_DIR)/\{\} \;
# Add a manifest file (may not be necessary
	echo "include */*.so" > $(RPMBUILD_DIR)/MANIFEST.in

_rpmbuild: _rpmsetup
	cd $(RPMBUILD_DIR) && python $(PackageName).py bdist_rpm \
	--release $(CMSGEMOS_OS).python$(PYTHON_VERSION) \
	--binary-only --force-arch=`uname -m`
# Harvest the crop
	find rpm -name "*.rpm"    -exec cp -a \{\} rpm/ \;
	find rpm -name "*.tar.gz" -exec cp -a \{\} rpm/ \;
	find rpm -name "*.tgz"    -exec cp -a \{\} rpm/ \;
	find rpm -name "*.tbz2"   -exec cp -a \{\} rpm/ \;

_setup_update:
	$(MakeDir) $(PackagePath)/rpm/RPMBUILD

	if [ -e $(PackagePath)/setup.py ]; then \
		echo Found $(PackagePath)/setup.py; \
		cp $(PackagePath)/setup.py $(RPMBUILD_DIR)/$(PackageName).py; \
	elif [ -e $(PackagePath)/pkg/setup.py ]; then \
		echo Found $(PackagePath)/pkg/setup.py; \
		cp $(PackagePath)/pkg/setup.py $(RPMBUILD_DIR)/$(PackageName).py; \
	elif [ -e $(PackagePath)/setup/build/setup.py ]; then \
		echo Found $(PackagePath)/setup/build/setup.py; \
		cp $(PackagePath)/setup/build/setup.py $(RPMBUILD_DIR)/$(PackageName).py; \
	elif [ -e $(ProjectPath)/setup/config/setupTemplate.py ]; then \
		echo Found $(ProjectPath)/setup/config/setupTemplate.py; \
		cp $(ProjectPath)/setup/config/setupTemplate.py $(RPMBUILD_DIR)/$(PackageName).py; \
	elif [ -e $(BUILD_HOME)/config/build/setupTemplate.py ]; then \
		echo Found $(BUILD_HOME)/config/build/setupTemplate.pyz; \
		cp $(BUILD_HOME)/config/build/setupTemplate.py $(RPMBUILD_DIR)/$(PackageName).py; \
	else \
		echo Unable to find any setupTemplate.py; \
		exit 1; \
	fi

	sed -i 's#__author__#$(Packager)#'                $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__project__#$(Project)#'                $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__summary__#None#'                      $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__gitrev__#$(GITREV)#'                  $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__builddate__#$(BUILD_DATE)#'           $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__package__#$(Package)#'                $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__packagedir__#$(PackagePath)#'         $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__packagename__#$(PackageName)#'        $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__longpackage__#$(LongPackage)#'        $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__pythonmodules__#$(PythonModules)#'    $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__version__#$(PACKAGE_FULL_VERSION)#'   $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__release__#$(CMSGEMOS_OS)#'            $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__prefix__#$(GEMPYTHON_ROOT)#'          $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__os__#$(CMSGEMOS_OS)#'                 $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__platform__#$(CMSGEMOS_PLATFORM)#'     $(RPMBUILD_DIR)/$(PackageName).py
	sed -i 's#__description__#None#'                  $(RPMBUILD_DIR)/$(PackageName).py

	if [ -e $(PackagePath)/setup.cfg ]; then \
		echo Found $(PackagePath)/setup.cfg; \
		cp $(PackagePath)/setup.cfg $(RPMBUILD_DIR)/setup.cfg; \
	elif [ -e $(PackagePath)/pkg/setup.cfg ]; then \
		echo Found $(PackagePath)/pkg/setup.cfg; \
		cp $(PackagePath)/pkg/setup.cfg $(RPMBUILD_DIR)/setup.cfg; \
	elif [ -e $(PackagePath)/setup/build/setup.cfg ]; then \
		echo Found $(PackagePath)/setup/build/setup.cfg; \
		cp $(PackagePath)/setup/build/setup.cfg $(RPMBUILD_DIR)/setup.cfg; \
	elif [ -e $(ProjectPath)/setup/config/setupTemplate.cfg ]; then \
		echo Found $(ProjectPath)/setup/config/setupTemplate.cfg; \
		cp $(ProjectPath)/setup/config/setupTemplate.cfg $(RPMBUILD_DIR)/setup.cfg; \
	elif [ -e $(BUILD_HOME)/config/build/setupTemplate.cfg ]; then \
		echo Found $(BUILD_HOME)/config/setupTemplate.cfg; \
		cp $(BUILD_HOME)/config/build/setupTemplate.cfg $(RPMBUILD_DIR)/setup.cfg; \
	else \
		echo Unable to find any setupTemplate.cfg; \
		exit 1; \
	fi

	sed -i 's#__author__#$(Packager)#'                $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__project__#$(Project)#'                $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__summary__#None#'                      $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__gitrev__#$(GITREV)#'                  $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__builddate__#$(BUILD_DATE)#'           $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__package__#$(Package)#'                $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__packagedir__#$(PackagePath)#'         $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__packagename__#$(PackageName)#'        $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__longpackage__#$(LongPackage)#'        $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__pythonmodules__#$(PythonModules)#'    $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__version__#$(PACKAGE_FULL_VERSION)#'   $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__release__#$(CMSGEMOS_OS)#'            $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__prefix__#$(GEMPYTHON_ROOT)#'          $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__os__#$(CMSGEMOS_OS)#'                 $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__platform__#$(CMSGEMOS_PLATFORM)#'     $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__description__#None#'                  $(RPMBUILD_DIR)/setup.cfg


.PHONY: cleanrpm _cleanrpm
cleanrpm: _cleanrpm
_cleanrpm:
	-rm -rf rpm
