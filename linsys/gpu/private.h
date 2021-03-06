#ifndef PRIV_H_GUARD
#define PRIV_H_GUARD

#include "glbopts.h"
#include "scs.h"
#include "cs.h"
#include "../common.h"
#include "linAlg.h"

#include "include/cusparse.h"
#include "include/cublas_v2.h"

struct PRIVATE_DATA {
    scs_int Annz; /* num non-zeros in A matrix */
    /* CUDA */
    cublasHandle_t cublasHandle;
    cusparseHandle_t cusparseHandle;
    cusparseMatDescr_t descr;
    /* ALL BELOW HOSTED ON THE GPU */
    scs_float * p; /* cg iterate, n  */
    scs_float * r; /* cg residual, n */
    scs_float * Gp; /* G * p, n */
    scs_float * bg; /* b, n */
    scs_float * tmp_m; /* m, used in matVec */
    AMatrix * Ag;   /* A matrix on GPU */
    AMatrix * Agt; /* A trans matrix on GPU */
};

#endif
