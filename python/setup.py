from setuptools import setup, Extension
from platform import system
from Cython.Build import cythonize
from collections import defaultdict
from helper import glober

ext = defaultdict(list)

if system() == 'Linux':
    ext['libraries'] += ['rt']

# location of SCS root directory, containing 'src/' etc.
rootDir = '../'

ext['include_dirs'] += glober(rootDir, ['', 'include', 'linsys'])
ext['define_macros'] += [('PYTHON', None), ('DLONG', None),
                         ('CTRLC', 1),     ('COPYAMATRIX', None)]
ext['extra_compile_args'] += ["-O3"]

ext['libraries'] += ['scsdir']
ext['library_dirs'] += glober(rootDir, ['out'])

# add cython stuff
ext['name'] = 'scs'
ext['sources'] += ['scs.pyx']
cyscs = Extension(**ext)


setup(name='scs',
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

