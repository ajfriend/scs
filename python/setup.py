from __future__ import print_function
import os
from setuptools import setup, Extension
from platform import system
from Cython.Build import cythonize
import copy
from collections import defaultdict
from helper import glober, add_blas_lapack_info

ext = defaultdict(list)

if system() == 'Linux':
    ext['libraries'] += ['rt']

# location of SCS root directory, containing 'src/' etc.
rootDir = '../'

# collect the extension module options common to all versions
ext['sources'] = glober(rootDir, ['src/*.c', 'linsys/*.c'])
ext['include_dirs'] = glober(rootDir, ['include', 'linsys'])
ext['define_macros'] += [('PYTHON', None), ('DLONG', None),
                         ('CTRLC', 1),     ('COPYAMATRIX', None)]
ext['extra_compile_args'] += ["-O3"]


# add the blas and lapack info
add_blas_lapack_info(ext)

# create the extension module options for the direct solver version
# deep copy so that the dictionaries do not point to the same list objects
ext_direct = copy.deepcopy(ext)
ext_direct['sources'] += glober(rootDir, ['linsys/direct/*.c', 'linsys/direct/external/*.c'])
ext_direct['include_dirs'] += glober(rootDir, ['linsys/direct/', 'linsys/direct/external/'])

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

