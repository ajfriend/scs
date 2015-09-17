from numpy.distutils.system_info import get_info
from collections import defaultdict
import numpy
from glob import glob

def glober(root, names):
    out = []
    for name in names:
        out += glob(root + name)
    return out

# move this to a setup_helper.py file?
def add_blas_lapack_info(info=None):
    # for debugging purposes
    if info is None:
        info = defaultdict(list)

    # add blas/lapack info
    lapack_found = False
    for name in 'blas_opt', 'lapack_opt': #'blas', 'lapack'
        d = get_info(name)
        for key in d:
            lapack_found = True
            info[key] += d[key]

    if lapack_found:
        info['define_macros'] += [('LAPACK_LIB_FOUND', None)]

    info['include_dirs'] += [numpy.get_include()]

    return info