from distutils.core import setup, Extension
from Cython.Build import cythonize

ext = [Extension(name='cyscs',
                sources=['cyscs.pyx'],
]

setup(
    ext_modules = cythonize(ext)
)