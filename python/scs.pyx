#cimport numpy as cnp
#import numpy as np # for some reason, the regular numpy import gives me a segfault

def version():
    cdef char* c_string = scs_version()
    return c_string

# use the python malloc/free to have the memory attributed to python.
from cpython.mem cimport PyMem_Malloc, PyMem_Free

# QUESTION: why do i get segfaults when compiling on OSX?

# IDEA: scs_solve interface is simple, the cached interface is a little more
# complicated, with the data input only updating what's necessary.

# maybe I don't even need the c function scs? maybe just do it for error checking?



#cimport cpython.array
#import array # also get a segfault witht this

stg_default = dict(normalize = 1,
                   scale = 1,
                   rho_x = 1e-3,
                   max_iters = 2500,
                   eps = 1e-3,
                   alpha = 1.5,
                   cg_rate = 2,
                   verbose = 1,
                   warm_start = 0)

def scs(data, cone, **settings):
    """ This should follow the same API as the current SCS python interface.
    """
    print "Implement me!"


# QUESTION: why can't i make settings a kwargs: **settings (i get a segfault)
# QUESTION: why do i get a segfault if i use "def" instead of "cpdef"?
cpdef myscs_solve(dict data, Workspace workspace=None, sol=None, settings=None):

    cdef scs_int m, n
    m, n = data['A'].shape

    if settings is None:
        settings = {}

    if workspace is None:
        workspace = Workspace(data, **settings)

    # *update* the settings dict
    workspace.settings = settings

    # sol is either none or a dict with x, y, s keys
    if sol is None:
        raise Exception('sol needs to contain vectors to write the solution')
        #sol = dict(x=np.zeros(n), y=np.zeros(m), s=np.zeros(m))
    
    cdef Sol _sol = make_sol(sol['x'], sol['y'], sol['s'])

    cdef scs_int status
    #status = scs_solve(Work* w, const Data* d, const Cone* k, Sol* sol, Info* info)

    return sol, workspace


    workspace.set_settings(settings)
    # sol is a dict of numpy arrays
    # if none, make the numpy arras yourself

    # work already contains a pointer to info, and knows the setup time
    # work also has a pointer to (the previously set) settings

    # work will contain the exit status. (should we convert from int to string?)

    #warmstart! (needs sol to be provided)
    #scs_int scs_solve(Work * w, const Data * d, const Cone * k, Sol * sol, Info * info)

    return sol, workspace


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
        cdef scs_float[:] b = data['b']
        cdef scs_float[:] c = data['c']

        self._data = Data(m, n, &self._A, &b[0], &c[0], &self._settings)
        self._cone = make_cone(data['cones'])

        self._work = scs_init(&self._data, &self._cone, &self._info)

        if self._work == NULL: 
            raise MemoryError("Memory error in allocating Workspace.")

    def __dealloc__(self):
        if self._work != NULL:
            scs_finish(self._work);

    # TODO: maybe make data optional. if its got a key, update that data entry.
    def solve(self, dict data, sol=None, **settings):
        m, n = self._data.m, self._data.n

        self.settings = settings

        # sol is either none or a dict with x, y, s keys
        if sol is None:
            raise Exception('sol needs to contain vectors to write the solution')
            #x = array('d', [0]*n)
            #y = array('d', [0]*m)
            #s = array('d', [0]*m)
            #sol = dict(x=x, y=y, s=s)
        
        cdef Sol _sol = make_sol(sol['x'], sol['y'], sol['s'])

        cdef scs_int status

        # do we really want to use the saved data and cone? should we re-create it?
        # data and cone might actually be pretty fast
        # maybe the input data can be only 'b' and 'c', what you want to update.
        # maybe prep the cone dict so that it has numpy arrays we can manipulate, just like we do in prepping the A matrix
        # this module would only expect to deal with numpy arrays.
        status = scs_solve(self._work, &self._data, &self._cone, &_sol, &self._info)

        return status, sol


cdef Sol make_sol(scs_float[:] x, scs_float[:] y, scs_float[:] s):
    cdef Sol sol = Sol(&x[0], &y[0], &s[0])
    return sol

cdef AMatrix make_amatrix(scs_float[:] data, scs_int[:] ind, scs_int[:] indptr, scs_int m, scs_int n):
    # Amatrix is not really big, so there's no need to dynamically allocate it.
    # difference with C/python? don't need to make this dynamically declared?
    # maybe fill a local array and then memcopy to dynamically allocated array
    cdef AMatrix cA = AMatrix(&data[0], &ind[0], &indptr[0], m, n)
    return cA


# todo: memory leak where used
cdef scs_int* make_carray_int(sizes):
    cdef scs_int n = len(sizes)
    cdef scs_int * q = <scs_int*>PyMem_Malloc(n*sizeof(scs_int))
    if not q:
        raise MemoryError()

    cdef scs_int i = 0
    for s in sizes:
        q[i] = s
        i += 1

    return q

# todo: memory leak where used!
cdef scs_float* make_carray_float(sizes):
    cdef scs_int n = len(sizes)
    cdef scs_float * q = <scs_float*>PyMem_Malloc(n*sizeof(scs_float))
    if not q:
        raise MemoryError()

    cdef scs_int i = 0
    for s in sizes:
        q[i] = s
        i += 1

    return q



#TODO: should I just wrap Cone with an extension type?
# TODO: memory leak here!
cdef Cone make_cone(dict pycone):
    cdef Cone ccone = Cone(f=0,l=0,q=NULL,qsize=0,s=NULL,ssize=0,ep=0,ed=0,psize=0,p=NULL)
    if 'f' in pycone:
        ccone.f = pycone['f']
    if 'l' in pycone:
        ccone.l = pycone['l']
    if 'q' in pycone:
        # we have a memory leak here!
        q = pycone['q']
        ccone.q = make_carray_int(q)
        ccone.qsize = len(q)
    if 's' in pycone:
        s = pycone['s']
        ccone.s = make_carray_int(s)
        ccone.ssize = len(s)
    if 'ep' in pycone:
        ccone.ep = pycone['ep']
    if 'ed' in pycone:
        ccone.ed = pycone['ed']

    if 'p' in pycone:
        p = pycone['p']
        ccone.p = make_carray_float(p)
        ccone.psize = len(p)

    # return the allocated numpy arrays so that they don't get garbage collected
    # TODO!! : worry about the numpy arrays here getting garbage collected

    # maybe we should just make sure to allocate and free this memory
    return ccone

def show_cone(dict pycone):
    cdef Cone ccone = make_cone(pycone)

    print 'f: ', ccone.f
    print 'l: ', ccone.l
    print 'ep: ', ccone.ep
    print 'ed: ', ccone.ed
    
    cdef scs_int i = 0

    if ccone.qsize > 0:
        print 'q: ',
        print " ".join([str(ccone.q[i]) for i in range(ccone.qsize)])

    if ccone.ssize > 0:
        print 's: ',
        print " ".join([str(ccone.s[i]) for i in range(ccone.ssize)])

    if ccone.psize > 0:
        print 'p: ',
        print " ".join([str(ccone.p[i]) for i in range(ccone.psize)])

    same_cone(ccone, pycone)

# make a test to assert that Cone and dict representations of cones are the same

cdef same_cone(Cone ccone, dict pycone):
    if 'f' in pycone:
        assert pycone['f'] == ccone.f
    if 'l' in pycone:
        assert pycone['l'] == ccone.l
    if 'ep' in pycone:
        assert pycone['ep'] == ccone.ep
    if 'ed' in pycone:
        assert pycone['ed'] == ccone.ed

    if 'q' in pycone:
        assert len(pycone['q']) == ccone.qsize
        for i, val in enumerate(pycone['q']):
            assert val == ccone.q[i]

    if 's' in pycone:
        assert len(pycone['s']) == ccone.ssize
        for i, val in enumerate(pycone['s']):
            assert val == ccone.s[i]

    if 'p' in pycone:
        assert len(pycone['p']) == ccone.psize
        for i, val in enumerate(pycone['p']):
            assert abs(val - ccone.p[i]) < 1e-5


# TODO: get this cone code working, with new cython memoryview syntax.
# figure out what's going on with the memory of a cone here
# wrap the cone in an object?
# wha happens with returning stack allocated objects from cython functions?