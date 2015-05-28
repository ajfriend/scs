# use the python malloc/free to have the memory attributed to python.
#from cpython.mem cimport PyMem_Malloc, PyMem_Free

# QUESTION: why do i get segfaults when compiling on OSX?

import numpy as np
cimport numpy as np

stg_default = dict(normalize = 1,
                   scale = 1,
                   rho_x = 1e-3,
                   max_iters = 2500,
                   eps = 1e-3,
                   alpha = 1.5,
                   cg_rate = 2,
                   verbose = 1,
                   warm_start = 0)


cpdef hello():
    print "hello"
    cdef scs_int a = -4
    cdef scs_float b = 2.2357
    test_numeric_type(a, b)

cpdef hi(np.ndarray[scs_int] a, np.ndarray[scs_float] b):
    print "hi"
    test_numeric_type(a[0], b[0])

cpdef howdy(np.ndarray[scs_float] a, np.ndarray[scs_int] b):
    print "howdy"
    print_numeric_type(<scs_float*> a.data, b[0])


# QUESTION: why can't i make settings a kwargs: **settings (i get a segfault)
# QUESTION: why do i get a segfault if i use "def" instead of "cpdef"?
cpdef myscs_solve(data, workspace=None, sol=None, settings=None):
    if settings is None:
        settings = {}

    if workspace is None:
        workspace = Workspace(data, **settings)

    # *update* the settings dict
    workspace.settings = settings


    #workspace.set_settings(settings)
#    # sol is a dict of numpy arrays
#    # if none, make the numpy arras yourself

#    # work already contains a pointer to info, and knows the setup time
#    # work also has a pointer to (the previously set) settings

#    # work will contain the exit status. (should we convert from int to string?)

#    #warmstart! (needs sol to be provided)
#    #scs_int scs_solve(Work * w, const Data * d, const Cone * k, Sol * sol, Info * info)

#    return sol, workspace


cdef class Workspace:
    cdef:
        Work * _work
        Settings _settings
        Info _info
        AMatrix _A
        # maybe it doesn't really make sense to have Workspace keep the _data or the cone
        Data _data
        Cone _cone

    property settings:
        def __get__(self):
            return <dict>self._settings
        def __set__(self, rhs):
            """ Not really a setter. Actually just updates the internal Settings
            struct/dict. Unknown keys are ignored.

            For example,

            workspace.settings = dict(apples=-17, max_iter=137)

            would leave the current settings unchanged, except for max_iter,
            which is updated. The 'apples' key is ignored.
            """
            # need to cdef stgs as a dict so that the struct is converted to a dict
            cdef dict stgs = self._settings
            stgs.update(rhs)
            self._settings = stgs

    property info:
        def __get__(self):
            return <dict>self._info


    # need to make a dealloc method
    # make sure we aren't freeing anythign else when we free work

    def __cinit__(self, data, **settings):
        stgs = stg_default.copy()
        if settings:
            stgs.update(settings)

        self._settings = stgs

        A = data['A']
        cdef scs_int m, n
        m,n = A.shape

        # TODO: do we always need this conversion?
        # check what scs_int is?
        #A.indices = A.indices.astype(np.int64)
        #A.indptr = A.indptr.astype(np.int64)

        self._A = make_amatrix(A.data, A.indices, A.indptr, m, n)

        # QUESTION: if i put data[b] in the call below, i get an error, why?
        cdef np.ndarray[scs_float] b = data['b']
        cdef np.ndarray[scs_float] c = data['c']

        self._data = Data(m, n, &self._A, <scs_float*>b.data, <scs_float*>c.data, &self._settings)
        self._cone = make_cone(data['cones'])

        self._work = scs_init(&self._data, &self._cone, &self._info)

        if self._work == NULL: 
            raise MemoryError("Memory error in allocating Workspace.")

    def show(self):
        print "showing data"
        print self._settings
        print self._info
        #print self._data.stgs
        cdef scs_int m = self._data.m
        cdef scs_float * b = self._data.b

        # QUESTION: why do i get segfaults whenever i try to use memoryviews?

        for i in range(m):
            print b[i]


## this first version messes up everything, for some reason
##cdef Sol make_sol(x, y, s):
cdef Sol make_sol(np.ndarray[scs_float] x, np.ndarray[scs_float] y, np.ndarray[scs_float] s):
    cdef Sol sol = Sol(<scs_float*>x.data, <scs_float*>y.data, <scs_float*>s.data)
    #cdef Sol sol = Sol(NULL, NULL, NULL)
    return sol

cdef AMatrix make_amatrix(np.ndarray[scs_float] data, np.ndarray[scs_int] ind, np.ndarray[scs_int] indptr, scs_int m, scs_int n):
    # Amatrix is not really big, so there's no need to dynamically allocate it.
    # difference with C/python? don't need to make this dynamically declared?
    # maybe fill a local array and then memcopy to dynamically allocated array
    cdef AMatrix cA = AMatrix(<scs_float*>data.data, <scs_int*>ind.data, <scs_int*>indptr.data, m, n)
    return cA

cdef Cone make_cone(pycone):
    # maybe we should be wrapping cone in a python object to manage memory and deallocation
    cdef np.ndarray[scs_int] q = None
    cdef np.ndarray[scs_int] s = None
    cdef np.ndarray[scs_float] p = None

    cdef Cone ccone = Cone(f=0,l=0,q=NULL,qsize=0,s=NULL,ssize=0,ep=0,ed=0,psize=0,p=NULL)
    if 'f' in pycone:
        ccone.f = pycone['f']
    if 'l' in pycone:
        ccone.l = pycone['l']
    if 'q' in pycone:
        # todo: careful with the integer types here
        q = np.array(pycone['q'], dtype=np.int64)
        ccone.q = <scs_int*>q.data
        ccone.qsize = len(q)
    if 's' in pycone:
        # todo: careful with the integer types here
        s = np.array(pycone['s'], dtype=np.int64)
        ccone.s = <scs_int*>s.data
        ccone.ssize = len(s)
    if 'ep' in pycone:
        ccone.ep = pycone['ep']
    if 'ed' in pycone:
        ccone.ed = pycone['ed']
    if 'p' in pycone:
        # todo: careful with the integer types here
        p = np.array(pycone['p'], dtype=np.float64)
        ccone.p = <scs_float*>p.data
        ccone.psize = len(p)

    # return the allocated numpy arrays so that they don't get garbage collected
    # TODO!! : worry about the numpy arrays here getting garbage collected

    # maybe we should just make sure to allocate and free this memory
    return ccone






