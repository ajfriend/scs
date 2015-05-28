import cyscs

import numpy as np
import scipy.sparse as sp


def mytest():
    ij = np.array([[0,1,2,3],[0,1,2,3]])
    A = sp.csc_matrix(([-1.,-1.,1.,1.], ij), (4,4))
    A.indices = A.indices.astype(np.int64)
    A.indptr = A.indptr.astype(np.int64)
    b = np.array([0.,0.,1,1])
    c = np.array([1.,1.,-1,-1])
    cone = {'l':4}

    data = dict(A=A, b=b, c=c, cones=cone)

    return data, cyscs.Workspace(data, scale=2)



data, w = mytest()


w.settings = {'max_iters':4}
print w.settings


data, w = mytest()
print w.settings
print data
