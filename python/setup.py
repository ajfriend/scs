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


# location of SCS root directory, containing 'src/' etc.
rootDir = '../'

# TODO: collect local directories. do glob and root dir only at end

ext = defaultdict(list)

if system() == 'Linux':
    ext['libraries'] += ['rt']

ext['sources'] += glob(rootDir + 'src/*.c') + glob(rootDir + 'linsys/*.c')
ext['include_dirs'] += [rootDir, rootDir + 'include', numpy.get_include(), rootDir + 'linsys']
ext['define_macros'] += [('PYTHON', None), ('DLONG', None), ('CTRLC', 1), ('COPYAMATRIX', None)]
# define_macros += [('EXTRAVERBOSE', 999)] # for debugging
ext['extra_compile_args'] += ["-O3"]

blas_info=get_info('blas_opt')
lapack_info=get_info('lapack_opt')

if blas_info or lapack_info:
    ext['define_macros'] += [('LAPACK_LIB_FOUND', None)] + blas_info.pop('define_macros', []) + lapack_info.pop('define_macros', [])
    ext['include_dirs'] += blas_info.pop('include_dirs', []) + lapack_info.pop('include_dirs', [])
    ext['library_dirs'] += blas_info.pop('library_dirs', []) + lapack_info.pop('library_dirs', [])
    ext['libraries'] += blas_info.pop('libraries', []) + lapack_info.pop('libraries', [])
    ext['extra_link_args'] += blas_info.pop('extra_link_args', []) + lapack_info.pop('extra_link_args', [])
    ext['extra_compile_args'] += blas_info.pop('extra_compile_args', []) + lapack_info.pop('extra_compile_args', [])


# deep copy so that the dictionaries do not point to the same list objects
ext_direct = copy.deepcopy(ext)
ext_direct['sources'] += glob(rootDir + 'linsys/direct/*.c') + glob(rootDir + 'linsys/direct/external/*.c')
ext_direct['include_dirs'] += [rootDir + 'linsys/direct/', rootDir + 'linsys/direct/external/']


# ext_indirect = copy.deepcopy(ext)
# ext_indirect['sources'] += glob(rootDir + 'linsys/indirect/*.c')
# ext_indirect['define_macros'] += [('INDIRECT', None)]
# ext_indirect['include_dirs'] += [rootDir + 'linsys/indirect/']


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
        long_description="Solves convex cone programs via operator splitting. Can solve: linear programs (LPs), second-order cone programs (SOCPs), semidefinite programs (SDPs), exponential cone programs (ECPs), and power cone programs (PCPs), or problems with any combination of those cones. See http://github.com/cvxgrp/scs for more details."
        )

