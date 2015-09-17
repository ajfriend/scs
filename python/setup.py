from setuptools import setup, Extension
from platform import system
from Cython.Build import cythonize
import copy
from collections import defaultdict
from helper import glober, add_blas_lapack_info
import numpy

# use 'export OMP_NUM_THREADS=16' to control num of threads (in that case, 16)
USE_OPENMP = False

# set to true if linking against blas/lapack libraries that use longs instead of ints for indices:
USE_64_BIT_BLAS = False

# ext is a dictionary collecting the keyword arguments that will be passed into 
# the Extension module constructor
# We first collect the arguments which are the same between the direct and
# indirection versions of the solver, and later form distinct dictionaries
# for the two versions
ext = defaultdict(list)

# ext['define_macros'] += [('EXTRAVERBOSE', 999)] # for debugging

if system() == 'Linux':
    ext['libraries'] += ['rt']

if USE_OPENMP:
    ext['define_macros'] += [('OPENMP', None)]
    ext['extra_compile_args'] += ['-fopenmp']
    ext['extra_link_args'] += ['-lgomp']

if USE_64_BIT_BLAS:
    ext['define_macros'] += [('BLAS64', None)]

# location of SCS root directory, containing 'src/' etc.
rootDir = '../'

# collect the extension module options common to both direct and indirect versions
ext['sources'] += glober(rootDir, ['src/*.c', 'linsys/*.c'])
ext['include_dirs'] += glober(rootDir, ['', 'include', 'linsys'])
ext['define_macros'] += [('PYTHON', None), ('DLONG', None),
                         ('CTRLC', 1),     ('COPYAMATRIX', None)]
ext['extra_compile_args'] += ["-O3"]


# add the blas and lapack info
add_blas_lapack_info(ext)
ext['include_dirs'] += [numpy.get_include()]

# TODO: remove for cython version
# ext['sources'] += ['scsmodule.c']

# create the extension module arguments for the direct solver version
# deep copy so that the dictionaries do not point to the same list objects
ext_direct = copy.deepcopy(ext)
ext_direct['name'] = '_scs_direct'
ext_direct['sources'] += glober(rootDir, ['linsys/direct/*.c', 'linsys/direct/external/*.c'])
ext_direct['include_dirs'] += glober(rootDir, ['linsys/direct/', 'linsys/direct/external/'])

# indirect solver extension module arguments
ext_cyscs = copy.deepcopy(ext_direct)
ext_cyscs['name'] = 'cyscs'
ext_cyscs['sources'] += ['cyscs.pyx']
cyscs = Extension(**ext_cyscs)


# for a while, build both original SCS and cython versions


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

