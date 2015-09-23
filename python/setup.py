from setuptools import setup, Extension
from Cython.Build import cythonize
from collections import defaultdict

ext = defaultdict(list)

ext['include_dirs'] += ['../include']
ext['name'] = 'scs'
ext['sources'] += ['scs.pyx']
cyscs = Extension(**ext)

setup(name='scs', version='9.9.9', ext_modules=cythonize(cyscs))