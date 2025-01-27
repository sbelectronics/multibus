import os
import sys

from setuptools import setup, Extension

from diskdirect.version import __version__

diskdirect_ext = Extension('diskdirect.diskdirect_ext',
                     sources = ['diskdirect/diskdirect_ext.c'],
                     library_dirs = ['/usr/local/lib'],
                     libraries = ['pigpio'])


# python 3.x
# wiringpi is not supported
setup_result = setup(name='diskdirect',
      version=__version__,
      description="Scott Baker's disk emulator library",
      packages=['diskdirect'],
      zip_safe=False,
      ext_modules=[diskdirect_ext]
)
