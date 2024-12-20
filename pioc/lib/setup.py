import os
import sys

from setuptools import setup, Extension

from iocdirect.version import __version__

iocdirect_ext = Extension('iocdirect.iocdirect_ext',
                     sources = ['iocdirect/iocdirect_ext.c'],
                     library_dirs = ['/usr/local/lib'],
                     libraries = ['pigpio'])


# python 3.x
# wiringpi is not supported
setup_result = setup(name='iocdirect',
      version=__version__,
      description="Scott Baker's IOC emulator library",
      packages=['iocdirect'],
      zip_safe=False,
      ext_modules=[iocdirect_ext]
)
