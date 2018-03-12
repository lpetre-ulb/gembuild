#!/usr/bin/env python

# Thanks to https://github.com/softwarefactory-project/rdopkg/blob/master/setup.py

import re
import setuptools
import sys

try:
    import multiprocessing  # noqa
except ImportError:
    pass

def getscripts():
    from os import listdir
    from os.path import isfile,join
    scriptdir = 'gempython/__longpackage__/bin'
    scripts   = listdir(scriptdir)
    return ['{0:s}/{1:s}'.format(scriptdir,x) for x in scripts if isfile(join(scriptdir,x)) ]

setuptools.setup(
    setup_requires=['pbr'],
    pbr=True,
    scripts=getscripts(),
)
