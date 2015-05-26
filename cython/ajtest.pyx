# use the python malloc/free to have the memory attributed to python.
from cpython.mem cimport PyMem_Malloc, PyMem_Free
import numpy as np
import scipy.sparse as sp
cimport numpy as np


cdef extern from "../include/glbopts.h":
    ctypedef SCS_PROBLEM_DATA Data
    ctypedef SCS_SETTINGS Settings
    ctypedef SCS_SOL_VARS Sol
    ctypedef SCS_INFO Info
    ctypedef SCS_WORK Work
    ctypedef SCS_CONE Cone


cdef extern from "../include/linsys.h":
    ctypedef A_DATA_MATRIX AMatrix


cdef extern from "../include/scs.h":
    ctypedef double scs_float
    ctypedef int scs_int

    scs_int scs(const Data * d, const Cone * k, Sol * sol, Info * info)
    Work * scs_init(const Data * d, const Cone * k, Info * info)
    scs_int scs_solve(Work * w, const Data * d, const Cone * k, Sol * sol, Info * info)

    struct SCS_SETTINGS:
        scs_int normalize
        scs_float scale
        scs_float rho_x

        scs_int max_iters
        scs_float eps
        scs_float alpha
        scs_float cg_rate
        scs_int verbose
        scs_int warm_start


    struct SCS_PROBLEM_DATA:
        # these cannot change for multiple runs for the same call to scs_init
        scs_int m, n # A has m rows, n cols
        AMatrix * A # A is supplied in data format specified by linsys solver

        # these can change for multiple runs for the same call to scs_init
        scs_float * b
        scs_float * c # dense arrays for b (size m), c (size n)

        Settings * stgs # contains solver settings specified by user

    # contains primal-dual solution arrays */
    struct SCS_SOL_VARS:
        scs_float * x
        scs_float * y
        scs_float * s


    # contains terminating information
    struct SCS_INFO:
        scs_int iter # number of iterations taken */
        char status[32] # status string, e.g. 'Solved' */
        scs_int statusVal # status as scs_int, defined in constants.h */
        scs_float pobj # primal objective */
        scs_float dobj # dual objective */
        scs_float resPri # primal equality residual */
        scs_float resDual # dual equality residual */
        scs_float resInfeas # infeasibility cert residual */
        scs_float resUnbdd # unbounded cert residual */
        scs_float relGap # relative duality gap */
        scs_float setupTime # time taken for setup phase */
        scs_float solveTime # time taken for solve phase */

    # workspace for SCS
    struct SCS_WORK:
        pass

    char * scs_version()


cdef extern from "../linsys/amatrix.h":
    struct A_DATA_MATRIX:
        # A is supplied in column compressed format
        scs_float * x  # A values, size: NNZ A 
        scs_int * i    # A row index, size: NNZ A 
        scs_int * p    # A column pointer, size: n+1 
        scs_int m, n   # m rows, n cols



cdef extern from "../include/cones.h":
# NB: rows of data matrix A must be specified in this exact order
    struct SCS_CONE:
        scs_int f # number of linear equality constraints
        scs_int l # length of LP cone
        scs_int *q # array of second-order cone constraints */
        scs_int qsize # length of SOC array */
        scs_int *s # array of SD constraints */
        scs_int ssize # length of SD array */
        scs_int ep # number of primal exponential cone triples */
        scs_int ed # number of dual exponential cone triples */
        scs_int psize # number of (primal and dual) power cone triples */
        scs_float * p # array of power cone params, must be \in [-1, 1],
                       # negative values are interpreted as specifying the dual cone */

#cdef class Workspace:
#    cdef Work * _work
#    cdef Settings _settings
#    cdef Info _info
#    cdef AMatrix _A
#    cdef Data _data
#    cdef Cone _cone

#    def __cinit__(self, data, **settings):

#        # this is a copy of the dict to the settings struct
#        self._settings = stg_default.copy().update(settings)

#        A = data['A']
#        m,n = A.shape

#        # TODO: do we always need this conversion?
#        # check what scs_int is?
#        A.indices = A.indices.astype(np.int64)
#        A.indptr = A.indptr.astype(np.int64)

#        self._A = make_amatrix(A.data, A.indices, A.indptr, m, n)

#        # TODO: double check that this isn't a copy.
#        cdef np.ndarray[double] b = data['b']
#        cdef np.ndarray[double] c = data['c']

#        self._data = Data(m, n, &self._A, <scs_float*>b.data, <scs_float*>c.data, &self._settings)
#        self._cone = make_cone(data['cones'])

#        self._work = scs_init(&self._data, &self._cone, &self._info)
#        #cdef Work * scs_init(const Data * d, const Cone * k, Info * info)

#        if self._work == NULL: 
#            raise MemoryError("Memory error in allocating Workspace.")



#def myscs_init(data, **settings):
#    # data is a dict with keys A,b,c, cones
#    # info is a dict. the set up function just needs it to write down the setuptime
#    #cdef Work * scs_init(const Data * d, const Cone * k, Info * info)
#    workspace = None
#    return workspace
#    # work contains a pointer to settings, let the user access

#def myscs_solve(data, workspace=None, sol=None, **settings):
#    if workspace is None:
#        workspace = myscs_init(data, **settings)
#    # sol is a dict of numpy arrays
#    # if none, make the numpy arras yourself

#    # work already contains a pointer to info, and knows the setup time
#    # work also has a pointer to (the previously set) settings

#    # work will contain the exit status. (should we convert from int to string?)

#    #warmstart! (needs sol to be provided)
#    #scs_int scs_solve(Work * w, const Data * d, const Cone * k, Sol * sol, Info * info)

#    return sol, workspace


def myscs(data, cone, **settings):
     #only setting missing here is warm start
    _A = data['A']
    m,n = _A.shape

    # TODO: do we always need this conversion?
    # check what scs_int is?
    _A.indices = _A.indices.astype(np.int64)
    _A.indptr = _A.indptr.astype(np.int64)

    cdef AMatrix A = make_amatrix(_A.data, _A.indices, _A.indptr, m, n)

    stgs = stg_default.copy()
    stgs.update(settings)

    cdef Settings csettings = stgs

    cdef np.ndarray[double] b = data['b']
    cdef np.ndarray[double] c = data['c']

    cdef Data cdata = Data(m, n, &A, <scs_float*>b.data, <scs_float*>c.data, &csettings)

    cdef Info info # doesn't need to be initialized

    x = np.zeros(n)
    y = np.zeros(m)
    s = np.zeros(m)
    cdef Sol sol = make_sol(x, y, s)

    cdef Cone ccone = make_cone(cone)

    cdef scs_int result = scs(&cdata, &ccone, &sol, &info)

    return {'x':x, 'y':y, 's':s, 'info':info, 'settings':csettings}



stg_default = dict(normalize = 1,
                   scale = 1,
                   rho_x = 1e-3,
                   max_iters = 2500,
                   eps = 1e-3,
                   alpha = 1.5,
                   cg_rate = 2,
                   verbose = 1,
                   warm_start = 0)

def mytest3():

    ij = np.array([[0,1,2,3],[0,1,2,3]])
    A = sp.csc_matrix(([-1.,-1.,1.,1.], ij), (4,4))
    cdef np.ndarray[double] b = np.array([0.,0.,1,1])
    cdef np.ndarray[double] c = np.array([1.,1.,-1,-1])
    cone = {'l':4}

    data = dict(A=A, b=b, c=c)

    return myscs(data, cone)


# this first version messes up everything, for some reason
#cdef Sol make_sol(x, y, s):
cdef Sol make_sol(np.ndarray[scs_float] x, np.ndarray[scs_float] y, np.ndarray[scs_float] s):
    cdef Sol sol = Sol(<scs_float*>x.data, <scs_float*>y.data, <scs_float*>s.data)
    #cdef Sol sol = Sol(NULL, NULL, NULL)
    return sol

cdef AMatrix make_amatrix(np.ndarray[scs_float] data, np.ndarray[scs_int] ind, np.ndarray[scs_int] indptr, int m, int n):
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






