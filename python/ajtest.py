import cyscs

import numpy as np
import scipy.sparse as sp

a = np.random.rand(4)
b = np.array([1,2,3,4])

cyscs.hello()

cyscs.howdy(a, b)
cyscs.howdy(a, b[2:])


b = np.array(b, dtype=np.int32)

try:
    cyscs.howdy(a, b[2:])
except Exception as e:
    print 'We got the error we were expecting!'
    print "should be something like: Buffer dtype mismatch, expected 'scs_int' but got 'int'"
    print e

b = np.array(b, dtype=np.int16)

try:
    cyscs.howdy(a, b[2:])
except Exception as e:
    print "should be something like: Buffer dtype mismatch, expected 'scs_int' but got 'short'"
    print e


def mytest3():
    ij = np.array([[0,1,2,3],[0,1,2,3]])
    A = sp.csc_matrix(([-1.,-1.,1.,1.], ij), (4,4))
    A.indices = A.indices.astype(np.int64)
    A.indptr = A.indptr.astype(np.int64)
    b = np.array([0.,0.,1,1])
    c = np.array([1.,1.,-1,-1])
    cone = {'l':4}

    data = dict(A=A, b=b, c=c, cones=cone)

    return cyscs.Workspace(data, scale=2), b



w, b = mytest3()
w.show()
b[2] = 13
w.show()

w.settings = {'max_iters':4}
print w.settings


# def myscs(data, cone, **settings):
#     #only setting missing here is warm start
#    _A = data['A']
#    m,n = _A.shape

   # # TODO: do we always need this conversion?
   # # check what scs_int is?
   # _A.indices = _A.indices.astype(np.int64)
   # _A.indptr = _A.indptr.astype(np.int64)

   # cdef AMatrix A = make_amatrix(_A.data, _A.indices, _A.indptr, m, n)

   # stgs = stg_default.copy()
   # stgs.update(settings)

   # cdef Settings csettings = stgs

   # cdef np.ndarray[double] b = data['b']
   # cdef np.ndarray[double] c = data['c']

   # cdef Data cdata = Data(m, n, &A, <scs_float*>b.data, <scs_float*>c.data, &csettings)

   # cdef Info info # doesn't need to be initialized

   # x = np.zeros(n)
   # y = np.zeros(m)
   # s = np.zeros(m)
   # cdef Sol sol = make_sol(x, y, s)

   # cdef Cone ccone = make_cone(cone)

   # cdef scs_int result = scs(&cdata, &ccone, &sol, &info)

   # return {'x':x, 'y':y, 's':s, 'info':info, 'settings':csettings}
