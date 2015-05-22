from distutils.core import setup, Extension
from Cython.Build import cythonize

ext = Extension(name='ajtest',
                sources=['ajtest.pyx'],
                library_dirs=['/Users/ajfriend/Dropbox/work/scs/out'],
                libraries=['scsdir'])

setup(
    ext_modules = cythonize(ext)
)

#scs/out/libscsdir.dylib