# Created with insights from
## amc13/config/mfPythonRPMRules.mk

ifndef INSTALL_PATH
INSTALL_PATH = /opt/cmsgemos
endif

ProjectPath  ?= $(BUILD_HOME)/$(Project)
PackagePath  ?= $(BUILD_HOME)/$(Project)
RPMBUILD_DIR = $(PackagePath)/rpm
# 

ifndef PythonModules
	$(error Python module names missing "PythonModules")
endif

.PHONY: pip rpm _rpmall _rpmprep _setup_update _rpmbuild _rpmdevbuild _rpmsetup _bdistbuild _sdistbuild _harvest
pip: _bdistbuild _sdistbuild
	@echo "Running pip target"
# Harvest the crop
	find rpm -name "*.tar.gz" -print0 -exec mv \{\} rpm/ \;
	find rpm -name "*.tgz"    -print0 -exec mv \{\} rpm/ \;
	find rpm -name "*.tbz2"   -print0 -exec mv \{\} rpm/ \;

rpm: _rpmall
	@echo "Running rpm target"
# Harvest the crop
	find rpm -name "*.rpm"    -print0 -exec mv \{\} rpm/ \;
	find rpm -name "*.tar.gz" -print0 -exec mv \{\} rpm/ \;
	find rpm -name "*.tgz"    -print0 -exec mv \{\} rpm/ \;
	find rpm -name "*.tbz2"   -print0 -exec mv \{\} rpm/ \;

#_rpmall: _all _rpmprep _setup_update _rpmsetup _rpmbuild
_rpmall: _all _rpmbuild 
	@echo "Running _rpmall target"
# Copy the package skeleton
# Ensure the existence of the module directory
# Copy the libraries into python module
_rpmsetup: _rpmprep _setup_update
# Change directory into pkg and copy everything into rpm build dir
	@echo "Running _rpmsetup target"
	cd pkg && \
	find . -iname 'setup.*' -prune -o -name "*" -exec install -D \{\} $(RPMBUILD_DIR)/\{\} \;
# Add a manifest file (may not be necessary
#	echo "include */*.so" > $(RPMBUILD_DIR)/MANIFEST.in

_rpmbuild: _rpmsetup
	@echo "Running _rpmbuild target"
	cd $(RPMBUILD_DIR) && python setup.py bdist_rpm \
	--release $(CMSGEMOS_OS).python$(PYTHON_VERSION) \
	--binary-only --force-arch=noarch 

_rpmarm: pip
	@echo "Running _rpmarm target"
	mkdir -p $(RPMBUILD_DIR)/arm/SOURCES
	cp $(RPMBUILD_DIR)/$(Package)*.tar.gz $(RPMBUILD_DIR)/arm/SOURCES/
	cd $(RPMBUILD_DIR) && python setup.py bdist_rpm \
	--release peta_linux.python$(PYTHON_VERSION) \
	--force-arch=noarch --spec-only
	rpmbuild -bb --define "_topdir $(RPMBUILD_DIR)/arm" --define "_binary_payload 1" $(RPMBUILD_DIR)/dist/${PackageName}.spec --clean

_bdistbuild: _rpmsetup
	@echo "Running _tarbuild target"
	cd $(RPMBUILD_DIR) && python setup.py bdist

_sdistbuild: _rpmsetup
	@echo "Running _tarbuild target"
	cd $(RPMBUILD_DIR) && python setup.py sdist

_harvest: _rpmbuild
# Harvest the crop
	find rpm -name "*.rpm"    -print0 -exec mv \{\} rpm/ \;
	find rpm -name "*.tar.gz" -print0 -exec mv \{\} rpm/ \;
	find rpm -name "*.tgz"    -print0 -exec mv \{\} rpm/ \;
	find rpm -name "*.tbz2"   -print0 -exec mv \{\} rpm/ \;

_setup_update:
	@echo "Running _setup_update target"
	@echo "PackagePath $PackagePath"
	$(MakeDir) $(PackagePath)/rpm/RPMBUILD

	if [ -e $(PackagePath)/setup.py ]; then \
		echo Found $(PackagePath)/setup.py; \
		cp $(PackagePath)/setup.py $(RPMBUILD_DIR)/setup.py; \
	elif [ -e $(PackagePath)/pkg/setup.py ]; then \
		echo Found $(PackagePath)/pkg/setup.py; \
		cp $(PackagePath)/pkg/setup.py $(RPMBUILD_DIR)/setup.py; \
	elif [ -e $(PackagePath)/setup/setup.py ]; then \
		echo Found $(PackagePath)/setup/setup.py; \
		cp $(PackagePath)/setup/setup.py $(RPMBUILD_DIR)/setup.py; \
	elif [ -e $(PackagePath)/setup/build/setup.py ]; then \
		echo Found $(PackagePath)/setup/build/setup.py; \
		cp $(PackagePath)/setup/build/setup.py $(RPMBUILD_DIR)/setup.py; \
	elif [ -e $(ProjectPath)/setup/config/setupTemplate.py ]; then \
		echo Found $(ProjectPath)/setup/config/setupTemplate.py; \
		cp $(ProjectPath)/setup/config/setupTemplate.py $(RPMBUILD_DIR)/setup.py; \
	elif [ -e $(BUILD_HOME)/config/build/setupTemplate.py ]; then \
		echo Found $(BUILD_HOME)/config/build/setupTemplate.py; \
		cp $(BUILD_HOME)/config/build/setupTemplate.py $(RPMBUILD_DIR)/setup.py; \
	else \
		echo Unable to find any setupTemplate.py; \
		exit 1; \
	fi

	sed -i 's#__author__#$(Packager)#'                $(RPMBUILD_DIR)/setup.py
	sed -i 's#__project__#$(Project)#'                $(RPMBUILD_DIR)/setup.py
	sed -i 's#__summary__#None#'                      $(RPMBUILD_DIR)/setup.py
	sed -i 's#__package__#$(Package)#'                $(RPMBUILD_DIR)/setup.py
	sed -i 's#__packagedir__#$(PackagePath)#'         $(RPMBUILD_DIR)/setup.py
	sed -i 's#__packagename__#$(PackageName)#'        $(RPMBUILD_DIR)/setup.py
	sed -i 's#__longpackage__#$(LongPackage)#'        $(RPMBUILD_DIR)/setup.py
	sed -i 's#__pythonmodules__#$(PythonModules)#'    $(RPMBUILD_DIR)/setup.py
	sed -i 's#__prefix__#$(GEMPYTHON_ROOT)#'          $(RPMBUILD_DIR)/setup.py
	sed -i 's#__os__#$(CMSGEMOS_OS)#'                 $(RPMBUILD_DIR)/setup.py
	sed -i 's#__platform__#$(CMSGEMOS_PLATFORM)#'     $(RPMBUILD_DIR)/setup.py
	sed -i 's#__description__#None#'                  $(RPMBUILD_DIR)/setup.py
	sed -i 's#___gitrev___#$(GITREV)#'                $(RPMBUILD_DIR)/setup.py
	sed -i 's#___gitver___#$(GIT_VERSION)#'           $(RPMBUILD_DIR)/setup.py
	sed -i 's#___version___#$(PACKAGE_FULL_VERSION)#' $(RPMBUILD_DIR)/setup.py
	sed -i 's#___release___#$(BUILD_VERSION)#'        $(RPMBUILD_DIR)/setup.py
	sed -i 's#___builddate___#$(BUILD_DATE)#'         $(RPMBUILD_DIR)/setup.py

	if [ -e $(PackagePath)/setup.cfg ]; then \
		echo Found $(PackagePath)/setup.cfg; \
		cp $(PackagePath)/setup.cfg $(RPMBUILD_DIR)/setup.cfg; \
	elif [ -e $(PackagePath)/pkg/setup.cfg ]; then \
		echo Found $(PackagePath)/pkg/setup.cfg; \
		cp $(PackagePath)/pkg/setup.cfg $(RPMBUILD_DIR)/setup.cfg; \
	elif [ -e $(PackagePath)/setup/setup.cfg ]; then \
		echo Found $(PackagePath)/setup/setup.cfg; \
		cp $(PackagePath)/setup/setup.cfg $(RPMBUILD_DIR)/setup.cfg; \
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
	sed -i 's#__package__#$(Package)#'                $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__packagedir__#$(PackagePath)#'         $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__packagename__#$(PackageName)#'        $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__longpackage__#$(LongPackage)#'        $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__pythonmodules__#$(PythonModules)#'    $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__prefix__#$(GEMPYTHON_ROOT)#'          $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__os__#$(CMSGEMOS_OS)#'                 $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__platform__#$(CMSGEMOS_PLATFORM)#'     $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#__description__#None#'                  $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#___gitrev___#$(GITREV)#'                $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#___gitver___#$(GIT_VERSION)#'           $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#___version___#$(PACKAGE_FULL_VERSION)#' $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#___release___#$(BUILD_VERSION)#'        $(RPMBUILD_DIR)/setup.cfg
	sed -i 's#___builddate___#$(BUILD_DATE)#'         $(RPMBUILD_DIR)/setup.cfg


.PHONY: cleanrpm _cleanrpm
cleanrpm: _cleanrpm
	@echo "Running cleanrpm target"

_cleanrpm:
	@echo "Running _cleanrpm target"
	@rm -rf rpm
