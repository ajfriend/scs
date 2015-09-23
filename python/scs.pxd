# commenting out these two lines also avoids the segfault
cdef extern from "scs.h":
    ctypedef float dummy_type