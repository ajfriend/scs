from __future__ import print_function
from numpy.distutils.system_info import get_info
from collections import defaultdict
from glob import glob
import os

def glober(root, names):
    out = []
    for name in names:
        out += glob(root + name)
    return out

def from_system_info(names):
    # set define_macros, include_dirs, library_dirs, libraries, extra_link_args, extra_compile_args

    info = defaultdict(list)

    # add blas/lapack info
    for name in names: #'blas_opt', 'lapack_opt': #'blas', 'lapack'
        d = get_info(name)
        for key in d:
            info[key] += d[key]

    return info


def from_env():
    PATHS = 'BLAS_LAPACK_LIB_PATHS'
    LIBS = 'BLAS_LAPACK_LIBS'

    info = defaultdict(list)
    if PATHS in os.environ:
        info['library_dirs'] += os.environ[PATHS].split()

    if LIBS in os.environ:
        info['libraries'] += os.environ[LIBS].split()

    return info

def get_blas_lapack_info():
    info = defaultdict(list)

    if not info:
        print("Trying using environment variables for blas/lapack libraries")
        info = from_env()

    if not info:
        print("Trying using blas_opt / lapack_opt")
        info = from_system_info(['blas_opt', 'lapack_opt'])

    if not info:
        print("blas_opt / lapack_opt failed, trying blas / lapack")
        info = from_system_info(['blas', 'lapack'])

    if info:
        info['define_macros'] += [('LAPACK_LIB_FOUND', None)]
    else:
        print("###############################################################################################")
        print("# failed to find blas/lapack libs, SCS cannot solve SDPs but can solve LPs, SOCPs, ECPs, PCPs #")
        print("# install blas/lapack and run this install script again to allow SCS to solve SDPs            #")
        print("#                                                                                             #")
        print("# scs will use environment variables BLAS_LAPACK_LIB_PATHS and BLAS_LAPACK_LIBS if set        #")
        print("# use this to link against blas/lapack libs that scs can't find on it's own, usage ex:        #")
        print("#        >> export BLAS_LAPACK_LIB_PATHS=/usr/lib/:/other/dir                                 #")
        print("#        >> export BLAS_LAPACK_LIBS=blas:lapack                                               #")
        print("#        >> python setup.py install                                                           #")
        print("###############################################################################################")

    return info

def add_blas_lapack_info(ext):
    tmp = get_blas_lapack_info()
    for key in tmp:
        ext[key] += tmp[key]

