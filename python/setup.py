from __future__ import print_function
import os
from setuptools import setup, Extension
from glob import glob
from platform import system
import numpy
from numpy.distutils.system_info import get_info
from Cython.Build import cythonize

import copy

from collections import defaultdict

ext = defaultdict(list)

if system() == 'Linux':
    ext['libraries'] += ['rt']

# location of SCS root directory, containing 'src/' etc.
rootDir = '../'

def glober(names):
    out = []
    for name in names:
        out += glob(rootDir + name)
    return out

# collect the extension module options common to all versions
ext['sources'] = glober(['src/*.c', 'linsys/*.c'])
ext['include_dirs'] = glober(['include', 'linsys']) # note that I'm leaving out the root dir. I don't think we need it
ext['define_macros'] += [('PYTHON', None), ('DLONG', None),
                         ('CTRLC', 1),     ('COPYAMATRIX', None)]
ext['extra_compile_args'] += ["-O3"]


# add blas/lapack info
lapack_found = False
for name in 'blas_opt', 'lapack_opt': #'blas', 'lapack'
    d = get_info(name)
    for key in d:
        lapack_found = True
        ext[key] += d[key]

if lapack_found:
    ext['define_macros'] += [('LAPACK_LIB_FOUND', None)]

ext['include_dirs'] += [numpy.get_include()]

# create the extension module options for the direct solver version
# deep copy so that the dictionaries do not point to the same list objects
ext_direct = copy.deepcopy(ext)
ext_direct['sources'] += glober(['linsys/direct/*.c', 'linsys/direct/external/*.c'])
ext_direct['include_dirs'] += glober(['linsys/direct/', 'linsys/direct/external/'])

ext_cyscs = copy.deepcopy(ext_direct)
ext_cyscs['name'] = 'cyscs'
ext_cyscs['sources'] += ['cyscs.pyx']
cyscs = Extension(**ext_cyscs)


setup(name='cyscs',
        version='9.9.9',
        author = 'Brendan O\'Donoghue',
        author_email = 'bodonoghue85@gmail.com',
        url = 'http://github.com/cvxgrp/scs',
        description='scs: splitting conic solver',
        ext_modules=cythonize(cyscs),
        install_requires=["numpy >= 1.7","scipy >= 0.13.2"],
        license = "MIT",
        long_description=("Solves convex cone programs via operator splitting. "
        "Can solve: linear programs (LPs), second-order cone programs (SOCPs), "
        "semidefinite programs (SDPs), exponential cone programs (ECPs), and "
        "power cone programs (PCPs), or problems with any combination of those "
        "cones. See http://github.com/cvxgrp/scs for more details.")
        )

