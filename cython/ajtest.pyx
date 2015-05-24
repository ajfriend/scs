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
    ctypedef SCS_SCALING Scaling
    ctypedef SCS_WORK Work
    ctypedef SCS_CONE Cone


cdef extern from "../include/linsys.h":
    ctypedef A_DATA_MATRIX AMatrix


cdef extern from "../include/scs.h":
    ctypedef double scs_float
    ctypedef int scs_int

    scs_int scs(const Data * d, const Cone * k, Sol * sol, Info * info)

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

    struct residuals:
        scs_int lastIter
        scs_float resDual
        scs_float resPri
        scs_float resInfeas
        scs_float resUnbdd
        scs_float relGap
        scs_float cTx_by_tau
        scs_float bTy_by_tau
        scs_float tau
        scs_float kap


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


    # contains normalization variables
    struct SCS_SCALING:
        scs_float * D # for normalization
        scs_float * E # for normalization
        scs_float meanNormRowA, meanNormColA

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




# do i really want to expose a settings object to the user? can this just be a dict to the user and a struct internally?
# maybe I really do want to expose the settings for the cached stuff?
#cdef class Settings:
#    cdef SCS_SETTINGS *_ptr
#    def __cinit__(self):
#        self._ptr = <SCS_SETTINGS*>PyMem_Malloc(sizeof(SCS_SETTINGS))
#        if not self._ptr:
#            raise MemoryError()

#        self._ptr.normalize = 1
#        self._ptr.scale = 5
#        self._ptr.rho_x = 1e-3
#        self._ptr.max_iters = 2500
#        self._ptr.eps = 1e-3
#        self._ptr.alpha = 1.8
#        self._ptr.cg_rate = 2
#        self._ptr.verbose = 1
#        self._ptr.warm_start = 0

#    def __dealloc__(self):
#        PyMem_Free(self._ptr)



stg_default = dict(normalize = 1,
                   scale = 5,
                   rho_x = 1e-3,
                   max_iters = 2500,
                   eps = 1e-3,
                   alpha = 1.8,
                   cg_rate = 2,
                   verbose = 1,
                   warm_start = 0)


def mytest2():
    c = scs_version()
    print 'Our version of scs is:', c

    ij = np.array([[0,1,2,3],[0,1,2,3]])
    A = sp.csc_matrix(([-1.,-1.,1.,1.], ij), (4,4))
    
    c = np.array([1.,1.,-1,-1])
    m,n = A.shape

    # a copy of the cA data structure is returned
    cdef AMatrix cA = make_amatrix(A)
    cdef Settings stgs = stg_default


    cdef np.ndarray[scs_float] npb = np.array([11.,0.,1,1])
    cdef scs_float * b = [1,2.0,3,4]
    b = <scs_float*>npb.data

    cdef Data data = Data(m, n, &cA, b, <scs_float*>c.data, &stgs)

    cdef Cone cone = Cone(f=0,l=4,q=NULL,qsize=0,s=NULL,ssize=0,ep=0,ed=0,psize=0,p=NULL)

    cdef Info info # doesn't need to be initialized

    print 'scs_float: ', sizeof(scs_float)

    x = np.array(n)
    y = np.array(m)
    s = np.array(m)
    cdef Sol sol = make_sol(x,y,s)

    cdef scs_int result = scs(&data, &cone, &sol, &info)

    print result


cdef Sol make_sol(x,y,s):
    cdef Sol sol = Sol(<scs_float*>x.data, <scs_float*>y.data, <scs_float*>s.data)
    return sol

cdef AMatrix make_amatrix(A):
    # Amatrix is not really big, so there's no need to dynamically allocate it.

    # convert to sparse if not
    m, n = A.shape

    # difference with C/python? don't need to make this dynamically declared?
    # maybe fill a local array and then memcopy to dynamically allocated array
    cdef AMatrix cA = AMatrix(<scs_float*>A.data.data, <scs_int*>A.indices.data, <scs_int*>A.indptr.data, m, n)
    return cA




