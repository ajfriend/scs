from distutils.core import setup, Extension
from Cython.Build import cythonize

include_dirs = ["../include", "../linsys"]

ext = [Extension(name='cyscs',
                sources=['cyscs.pyx'],
                library_dirs=['../out'],
                libraries=['scsdir'],
                include_dirs=include_dirs)
]

setup(
    ext_modules = cythonize(ext)
)