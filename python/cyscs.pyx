
def foo():
    print 'hello'

def summer(double[:] mv):
    cdef double d, ss = 0.0
    for d in mv:
        ss += d
    return ss