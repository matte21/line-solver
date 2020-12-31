/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * pfqn_amvabs.c
 *
 * Code generation for function 'pfqn_amvabs'
 *
 */

/* Include files */
#include "pfqn_amvabs.h"
#include "eml_int_forloop_overflow_check.h"
#include "pfqn_amvabs_data.h"
#include "pfqn_amvabs_emxutil.h"
#include "pfqn_amvabs_types.h"
#include "rt_nonfinite.h"
#include "mwmathutil.h"

/* Variable Definitions */
static emlrtRSInfo emlrtRSI = { 44,    /* lineNo */
  "pfqn_amvabs",                       /* fcnName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pathName */
};

static emlrtRSInfo b_emlrtRSI = { 56,  /* lineNo */
  "pfqn_amvabs",                       /* fcnName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pathName */
};

static emlrtRSInfo c_emlrtRSI = { 20,  /* lineNo */
  "sum",                               /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/lib/matlab/datafun/sum.m"/* pathName */
};

static emlrtRSInfo d_emlrtRSI = { 99,  /* lineNo */
  "sumprod",                           /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/lib/matlab/datafun/private/sumprod.m"/* pathName */
};

static emlrtRSInfo e_emlrtRSI = { 133, /* lineNo */
  "combineVectorElements",             /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/lib/matlab/datafun/private/combineVectorElements.m"/* pathName */
};

static emlrtRSInfo f_emlrtRSI = { 194, /* lineNo */
  "colMajorFlatIter",                  /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/lib/matlab/datafun/private/combineVectorElements.m"/* pathName */
};

static emlrtRSInfo g_emlrtRSI = { 21,  /* lineNo */
  "eml_int_forloop_overflow_check",    /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/lib/matlab/eml/eml_int_forloop_overflow_check.m"/* pathName */
};

static emlrtRSInfo h_emlrtRSI = { 18,  /* lineNo */
  "abs",                               /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/lib/matlab/elfun/abs.m"/* pathName */
};

static emlrtRSInfo i_emlrtRSI = { 75,  /* lineNo */
  "applyScalarFunction",               /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/applyScalarFunction.m"/* pathName */
};

static emlrtRSInfo j_emlrtRSI = { 14,  /* lineNo */
  "max",                               /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/lib/matlab/datafun/max.m"/* pathName */
};

static emlrtRSInfo k_emlrtRSI = { 44,  /* lineNo */
  "minOrMax",                          /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/minOrMax.m"/* pathName */
};

static emlrtRSInfo l_emlrtRSI = { 79,  /* lineNo */
  "maximum",                           /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/minOrMax.m"/* pathName */
};

static emlrtRSInfo m_emlrtRSI = { 169, /* lineNo */
  "unaryMinOrMax",                     /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/unaryMinOrMax.m"/* pathName */
};

static emlrtRSInfo n_emlrtRSI = { 328, /* lineNo */
  "unaryMinOrMaxDispatch",             /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/unaryMinOrMax.m"/* pathName */
};

static emlrtRSInfo o_emlrtRSI = { 396, /* lineNo */
  "minOrMax2D",                        /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/unaryMinOrMax.m"/* pathName */
};

static emlrtRSInfo p_emlrtRSI = { 478, /* lineNo */
  "minOrMax2DColumnMajorDim1",         /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/unaryMinOrMax.m"/* pathName */
};

static emlrtRSInfo q_emlrtRSI = { 476, /* lineNo */
  "minOrMax2DColumnMajorDim1",         /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/unaryMinOrMax.m"/* pathName */
};

static emlrtRSInfo r_emlrtRSI = { 18,  /* lineNo */
  "ifWhileCond",                       /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/ifWhileCond.m"/* pathName */
};

static emlrtRSInfo s_emlrtRSI = { 31,  /* lineNo */
  "checkNoNaNs",                       /* fcnName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/ifWhileCond.m"/* pathName */
};

static emlrtRTEInfo c_emlrtRTEI = { 97,/* lineNo */
  27,                                  /* colNo */
  "unaryMinOrMax",                     /* fName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/unaryMinOrMax.m"/* pName */
};

static emlrtRTEInfo d_emlrtRTEI = { 26,/* lineNo */
  27,                                  /* colNo */
  "unaryMinOrMax",                     /* fName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/unaryMinOrMax.m"/* pName */
};

static emlrtRTEInfo e_emlrtRTEI = { 20,/* lineNo */
  15,                                  /* colNo */
  "rdivide_helper",                    /* fName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/rdivide_helper.m"/* pName */
};

static emlrtBCInfo emlrtBCI = { -1,    /* iFirst */
  -1,                                  /* iLast */
  44,                                  /* lineNo */
  37,                                  /* colNo */
  "CN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtRTEInfo f_emlrtRTEI = { 26,/* lineNo */
  8,                                   /* colNo */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pName */
};

static emlrtBCInfo b_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  30,                                  /* lineNo */
  29,                                  /* colNo */
  "QN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo c_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  30,                                  /* lineNo */
  37,                                  /* colNo */
  "weight",                            /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo d_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  30,                                  /* lineNo */
  13,                                  /* colNo */
  "relprio",                           /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo e_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  35,                                  /* lineNo */
  23,                                  /* colNo */
  "L",                                 /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo f_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  35,                                  /* lineNo */
  13,                                  /* colNo */
  "CN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo g_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  38,                                  /* lineNo */
  31,                                  /* colNo */
  "CN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo h_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  38,                                  /* lineNo */
  41,                                  /* colNo */
  "L",                                 /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo i_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  38,                                  /* lineNo */
  48,                                  /* colNo */
  "QN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo j_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  38,                                  /* lineNo */
  56,                                  /* colNo */
  "relprio",                           /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo k_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  38,                                  /* lineNo */
  69,                                  /* colNo */
  "relprio",                           /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo l_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  38,                                  /* lineNo */
  21,                                  /* colNo */
  "CN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo m_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  48,                                  /* lineNo */
  23,                                  /* colNo */
  "XN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo n_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  48,                                  /* lineNo */
  29,                                  /* colNo */
  "CN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo o_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  48,                                  /* lineNo */
  13,                                  /* colNo */
  "QN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo p_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  40,                                  /* lineNo */
  31,                                  /* colNo */
  "CN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo q_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  40,                                  /* lineNo */
  41,                                  /* colNo */
  "L",                                 /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo r_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  40,                                  /* lineNo */
  48,                                  /* colNo */
  "QN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo s_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  40,                                  /* lineNo */
  57,                                  /* colNo */
  "N",                                 /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo t_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  40,                                  /* lineNo */
  70,                                  /* colNo */
  "relprio",                           /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo u_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  40,                                  /* lineNo */
  83,                                  /* colNo */
  "relprio",                           /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo v_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  40,                                  /* lineNo */
  21,                                  /* colNo */
  "CN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo w_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  53,                                  /* lineNo */
  23,                                  /* colNo */
  "XN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo x_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  53,                                  /* lineNo */
  29,                                  /* colNo */
  "L",                                 /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo y_emlrtBCI = { -1,  /* iFirst */
  -1,                                  /* iLast */
  53,                                  /* lineNo */
  13,                                  /* colNo */
  "UN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo ab_emlrtBCI = { -1, /* iFirst */
  -1,                                  /* iLast */
  44,                                  /* lineNo */
  17,                                  /* colNo */
  "N",                                 /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo bb_emlrtBCI = { -1, /* iFirst */
  -1,                                  /* iLast */
  44,                                  /* lineNo */
  23,                                  /* colNo */
  "Z",                                 /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtBCInfo cb_emlrtBCI = { -1, /* iFirst */
  -1,                                  /* iLast */
  44,                                  /* lineNo */
  9,                                   /* colNo */
  "XN",                                /* aName */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m",/* pName */
  0                                    /* checkKind */
};

static emlrtRTEInfo h_emlrtRTEI = { 14,/* lineNo */
  1,                                   /* colNo */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pName */
};

static emlrtRTEInfo i_emlrtRTEI = { 23,/* lineNo */
  1,                                   /* colNo */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pName */
};

static emlrtRTEInfo j_emlrtRTEI = { 24,/* lineNo */
  1,                                   /* colNo */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pName */
};

static emlrtRTEInfo k_emlrtRTEI = { 27,/* lineNo */
  5,                                   /* colNo */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pName */
};

static emlrtRTEInfo l_emlrtRTEI = { 24,/* lineNo */
  4,                                   /* colNo */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pName */
};

static emlrtRTEInfo m_emlrtRTEI = { 56,/* lineNo */
  16,                                  /* colNo */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pName */
};

static emlrtRTEInfo n_emlrtRTEI = { 31,/* lineNo */
  21,                                  /* colNo */
  "applyScalarFunction",               /* fName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/applyScalarFunction.m"/* pName */
};

static emlrtRTEInfo o_emlrtRTEI = { 468,/* lineNo */
  21,                                  /* colNo */
  "unaryMinOrMax",                     /* fName */
  "/usr/local/MATLAB/R2020b/toolbox/eml/eml/+coder/+internal/unaryMinOrMax.m"/* pName */
};

static emlrtRTEInfo p_emlrtRTEI = { 56,/* lineNo */
  8,                                   /* colNo */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pName */
};

static emlrtRTEInfo q_emlrtRTEI = { 25,/* lineNo */
  1,                                   /* colNo */
  "pfqn_amvabs",                       /* fName */
  "/home/gcasale/Dropbox/code/line-dev.git/src/solvers/MVA/lib/pfqn_amvabs.m"/* pName */
};

/* Function Definitions */
void pfqn_amvabs(const emlrtStack *sp, const emxArray_real_T *L, const
                 emxArray_real_T *N, const emxArray_real_T *Z, real_T tol,
                 real_T maxiter, emxArray_real_T *QN, const emxArray_real_T
                 *weight, emxArray_real_T *XN, emxArray_real_T *UN)
{
  emlrtStack b_st;
  emlrtStack c_st;
  emlrtStack d_st;
  emlrtStack e_st;
  emlrtStack f_st;
  emlrtStack g_st;
  emlrtStack h_st;
  emlrtStack i_st;
  emlrtStack st;
  emxArray_boolean_T *x;
  emxArray_real_T *CN;
  emxArray_real_T *QN_1;
  emxArray_real_T *maxval;
  emxArray_real_T *relprio;
  real_T b;
  real_T y;
  int32_T M;
  int32_T R;
  int32_T b_i;
  int32_T i;
  int32_T it;
  int32_T n;
  int32_T nx;
  int32_T r;
  int32_T unnamed_idx_0;
  int32_T unnamed_idx_1;
  boolean_T exitg1;
  boolean_T exitg2;
  boolean_T overflow;
  st.prev = sp;
  st.tls = sp->tls;
  b_st.prev = &st;
  b_st.tls = st.tls;
  c_st.prev = &b_st;
  c_st.tls = b_st.tls;
  d_st.prev = &c_st;
  d_st.tls = c_st.tls;
  e_st.prev = &d_st;
  e_st.tls = d_st.tls;
  f_st.prev = &e_st;
  f_st.tls = e_st.tls;
  g_st.prev = &f_st;
  g_st.tls = f_st.tls;
  h_st.prev = &g_st;
  h_st.tls = g_st.tls;
  i_st.prev = &h_st;
  i_st.tls = h_st.tls;
  emlrtHeapReferenceStackEnterFcnR2012b(sp);
  emxInit_real_T(sp, &CN, 2, &h_emlrtRTEI, true);

  /*  [XN,QN,UN]=PFQN_AMVABS(L,N,Z,TOL,MAXITER,QN,WEIGHT) */
  R = L->size[1] - 1;
  M = L->size[0] - 1;
  i = CN->size[0] * CN->size[1];
  CN->size[0] = L->size[0];
  CN->size[1] = L->size[1];
  emxEnsureCapacity_real_T(sp, CN, i, &h_emlrtRTEI);
  n = L->size[0] * L->size[1];
  for (i = 0; i < n; i++) {
    CN->data[i] = 0.0;
  }

  n = QN->size[1];
  for (i = 0; i < n; i++) {
    nx = QN->size[0];
    for (unnamed_idx_0 = 0; unnamed_idx_0 < nx; unnamed_idx_0++) {
      QN->data[unnamed_idx_0 + QN->size[0] * i] += 2.2204460492503131E-16;
    }
  }

  /*  0 gives problems */
  i = XN->size[0] * XN->size[1];
  XN->size[0] = 1;
  XN->size[1] = L->size[1];
  emxEnsureCapacity_real_T(sp, XN, i, &i_emlrtRTEI);
  n = L->size[1];
  for (i = 0; i < n; i++) {
    XN->data[i] = 0.0;
  }

  unnamed_idx_0 = L->size[0];
  unnamed_idx_1 = L->size[1];
  i = UN->size[0] * UN->size[1];
  UN->size[0] = L->size[0];
  UN->size[1] = L->size[1];
  emxEnsureCapacity_real_T(sp, UN, i, &j_emlrtRTEI);
  n = L->size[0] * L->size[1];
  for (i = 0; i < n; i++) {
    UN->data[i] = 0.0;
  }

  emlrtForLoopVectorCheckR2012b(1.0, 1.0, maxiter, mxDOUBLE_CLASS, (int32_T)
    maxiter, &f_emlrtRTEI, sp);
  it = 0;
  emxInit_real_T(sp, &relprio, 2, &q_emlrtRTEI, true);
  emxInit_real_T(sp, &QN_1, 2, &k_emlrtRTEI, true);
  emxInit_real_T(sp, &maxval, 2, &p_emlrtRTEI, true);
  emxInit_boolean_T(sp, &x, 2, &p_emlrtRTEI, true);
  exitg1 = false;
  while ((!exitg1) && (it <= (int32_T)maxiter - 1)) {
    i = QN_1->size[0] * QN_1->size[1];
    QN_1->size[0] = QN->size[0];
    QN_1->size[1] = QN->size[1];
    emxEnsureCapacity_real_T(sp, QN_1, i, &k_emlrtRTEI);
    n = QN->size[0] * QN->size[1];
    for (i = 0; i < n; i++) {
      QN_1->data[i] = QN->data[i];
    }

    i = relprio->size[0] * relprio->size[1];
    relprio->size[0] = L->size[0];
    relprio->size[1] = L->size[1];
    emxEnsureCapacity_real_T(sp, relprio, i, &l_emlrtRTEI);
    for (b_i = 0; b_i <= M; b_i++) {
      for (r = 0; r <= R; r++) {
        i = QN->size[0];
        if ((b_i + 1 < 1) || (b_i + 1 > i)) {
          emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, i, &b_emlrtBCI, sp);
        }

        i = QN->size[1];
        if ((r + 1 < 1) || (r + 1 > i)) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, i, &b_emlrtBCI, sp);
        }

        if ((b_i + 1 < 1) || (b_i + 1 > weight->size[0])) {
          emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, weight->size[0], &c_emlrtBCI,
            sp);
        }

        if ((r + 1 < 1) || (r + 1 > weight->size[1])) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, weight->size[1], &c_emlrtBCI,
            sp);
        }

        if ((b_i + 1 < 1) || (b_i + 1 > relprio->size[0])) {
          emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, relprio->size[0],
            &d_emlrtBCI, sp);
        }

        if ((r + 1 < 1) || (r + 1 > relprio->size[1])) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, relprio->size[1], &d_emlrtBCI,
            sp);
        }

        relprio->data[b_i + relprio->size[0] * r] = QN->data[b_i + QN->size[0] *
          r] * weight->data[b_i + weight->size[0] * r];
        if (*emlrtBreakCheckR2012bFlagVar != 0) {
          emlrtBreakCheckR2012b(sp);
        }
      }

      if (*emlrtBreakCheckR2012bFlagVar != 0) {
        emlrtBreakCheckR2012b(sp);
      }
    }

    for (r = 0; r <= R; r++) {
      for (b_i = 0; b_i <= M; b_i++) {
        if ((b_i + 1 < 1) || (b_i + 1 > L->size[0])) {
          emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, L->size[0], &e_emlrtBCI, sp);
        }

        if ((r + 1 < 1) || (r + 1 > L->size[1])) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, L->size[1], &e_emlrtBCI, sp);
        }

        if ((b_i + 1 < 1) || (b_i + 1 > CN->size[0])) {
          emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, CN->size[0], &f_emlrtBCI, sp);
        }

        if ((r + 1 < 1) || (r + 1 > CN->size[1])) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, CN->size[1], &f_emlrtBCI, sp);
        }

        CN->data[b_i + CN->size[0] * r] = L->data[b_i + L->size[0] * r];
        for (nx = 0; nx <= R; nx++) {
          if (nx + 1 != r + 1) {
            if ((b_i + 1 < 1) || (b_i + 1 > CN->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, CN->size[0], &g_emlrtBCI,
                sp);
            }

            if ((r + 1 < 1) || (r + 1 > CN->size[1])) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, CN->size[1], &g_emlrtBCI,
                sp);
            }

            if ((b_i + 1 < 1) || (b_i + 1 > L->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, L->size[0], &h_emlrtBCI,
                sp);
            }

            if ((r + 1 < 1) || (r + 1 > L->size[1])) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, L->size[1], &h_emlrtBCI,
                sp);
            }

            i = QN->size[0];
            if ((b_i + 1 < 1) || (b_i + 1 > i)) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, i, &i_emlrtBCI, sp);
            }

            i = QN->size[1];
            if ((nx + 1 < 1) || (nx + 1 > i)) {
              emlrtDynamicBoundsCheckR2012b(nx + 1, 1, i, &i_emlrtBCI, sp);
            }

            if ((b_i + 1 < 1) || (b_i + 1 > relprio->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, relprio->size[0],
                &j_emlrtBCI, sp);
            }

            if ((nx + 1 < 1) || (nx + 1 > relprio->size[1])) {
              emlrtDynamicBoundsCheckR2012b(nx + 1, 1, relprio->size[1],
                &j_emlrtBCI, sp);
            }

            if ((b_i + 1 < 1) || (b_i + 1 > relprio->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, relprio->size[0],
                &k_emlrtBCI, sp);
            }

            if ((r + 1 < 1) || (r + 1 > relprio->size[1])) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, relprio->size[1],
                &k_emlrtBCI, sp);
            }

            if ((b_i + 1 < 1) || (b_i + 1 > CN->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, CN->size[0], &l_emlrtBCI,
                sp);
            }

            if ((r + 1 < 1) || (r + 1 > CN->size[1])) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, CN->size[1], &l_emlrtBCI,
                sp);
            }

            CN->data[b_i + CN->size[0] * r] += L->data[b_i + L->size[0] * r] *
              QN->data[b_i + QN->size[0] * nx] * relprio->data[b_i +
              relprio->size[0] * nx] / relprio->data[b_i + relprio->size[0] * r];
          } else {
            if ((b_i + 1 < 1) || (b_i + 1 > CN->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, CN->size[0], &p_emlrtBCI,
                sp);
            }

            if ((r + 1 < 1) || (r + 1 > CN->size[1])) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, CN->size[1], &p_emlrtBCI,
                sp);
            }

            if ((b_i + 1 < 1) || (b_i + 1 > L->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, L->size[0], &q_emlrtBCI,
                sp);
            }

            if ((r + 1 < 1) || (r + 1 > L->size[1])) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, L->size[1], &q_emlrtBCI,
                sp);
            }

            i = QN->size[0];
            if ((b_i + 1 < 1) || (b_i + 1 > i)) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, i, &r_emlrtBCI, sp);
            }

            i = QN->size[1];
            if ((r + 1 < 1) || (r + 1 > i)) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, i, &r_emlrtBCI, sp);
            }

            if ((r + 1 < 1) || (r + 1 > N->size[1])) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, N->size[1], &s_emlrtBCI,
                sp);
            }

            if ((b_i + 1 < 1) || (b_i + 1 > relprio->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, relprio->size[0],
                &t_emlrtBCI, sp);
            }

            if ((nx + 1 < 1) || (nx + 1 > relprio->size[1])) {
              emlrtDynamicBoundsCheckR2012b(nx + 1, 1, relprio->size[1],
                &t_emlrtBCI, sp);
            }

            if ((b_i + 1 < 1) || (b_i + 1 > relprio->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, relprio->size[0],
                &u_emlrtBCI, sp);
            }

            if ((r + 1 < 1) || (r + 1 > relprio->size[1])) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, relprio->size[1],
                &u_emlrtBCI, sp);
            }

            if ((b_i + 1 < 1) || (b_i + 1 > CN->size[0])) {
              emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, CN->size[0], &v_emlrtBCI,
                sp);
            }

            if ((r + 1 < 1) || (r + 1 > CN->size[1])) {
              emlrtDynamicBoundsCheckR2012b(r + 1, 1, CN->size[1], &v_emlrtBCI,
                sp);
            }

            CN->data[b_i + CN->size[0] * r] += L->data[b_i + L->size[0] * r] *
              QN->data[b_i + QN->size[0] * r] * (N->data[r] - 1.0) / N->data[r] *
              relprio->data[b_i + relprio->size[0] * nx] / relprio->data[b_i +
              relprio->size[0] * r];
          }

          if (*emlrtBreakCheckR2012bFlagVar != 0) {
            emlrtBreakCheckR2012b(sp);
          }
        }

        if (*emlrtBreakCheckR2012bFlagVar != 0) {
          emlrtBreakCheckR2012b(sp);
        }
      }

      st.site = &emlrtRSI;
      i = r + 1;
      if ((i < 1) || (i > CN->size[1])) {
        emlrtDynamicBoundsCheckR2012b(i, 1, CN->size[1], &emlrtBCI, &st);
      }

      b_st.site = &c_emlrtRSI;
      i = CN->size[0];
      c_st.site = &d_emlrtRSI;
      if (CN->size[0] == 0) {
        y = 0.0;
      } else {
        d_st.site = &e_emlrtRSI;
        y = CN->data[CN->size[0] * r];
        e_st.site = &f_emlrtRSI;
        if (2 > CN->size[0]) {
          overflow = false;
        } else {
          overflow = (CN->size[0] > 2147483646);
        }

        if (overflow) {
          f_st.site = &g_emlrtRSI;
          check_forloop_overflow_error(&f_st);
        }

        for (n = 2; n <= i; n++) {
          y += CN->data[(n + CN->size[0] * r) - 1];
        }
      }

      if ((r + 1 < 1) || (r + 1 > N->size[1])) {
        emlrtDynamicBoundsCheckR2012b(r + 1, 1, N->size[1], &ab_emlrtBCI, sp);
      }

      if ((r + 1 < 1) || (r + 1 > Z->size[1])) {
        emlrtDynamicBoundsCheckR2012b(r + 1, 1, Z->size[1], &bb_emlrtBCI, sp);
      }

      if ((r + 1 < 1) || (r + 1 > XN->size[1])) {
        emlrtDynamicBoundsCheckR2012b(r + 1, 1, XN->size[1], &cb_emlrtBCI, sp);
      }

      XN->data[r] = N->data[r] / (Z->data[r] + y);
      if (*emlrtBreakCheckR2012bFlagVar != 0) {
        emlrtBreakCheckR2012b(sp);
      }
    }

    for (r = 0; r <= R; r++) {
      for (b_i = 0; b_i <= M; b_i++) {
        if ((r + 1 < 1) || (r + 1 > XN->size[1])) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, XN->size[1], &m_emlrtBCI, sp);
        }

        if ((b_i + 1 < 1) || (b_i + 1 > CN->size[0])) {
          emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, CN->size[0], &n_emlrtBCI, sp);
        }

        if ((r + 1 < 1) || (r + 1 > CN->size[1])) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, CN->size[1], &n_emlrtBCI, sp);
        }

        i = QN->size[0];
        if ((b_i + 1 < 1) || (b_i + 1 > i)) {
          emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, i, &o_emlrtBCI, sp);
        }

        i = QN->size[1];
        if ((r + 1 < 1) || (r + 1 > i)) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, i, &o_emlrtBCI, sp);
        }

        QN->data[b_i + QN->size[0] * r] = XN->data[r] * CN->data[b_i + CN->size
          [0] * r];
        if (*emlrtBreakCheckR2012bFlagVar != 0) {
          emlrtBreakCheckR2012b(sp);
        }
      }

      if (*emlrtBreakCheckR2012bFlagVar != 0) {
        emlrtBreakCheckR2012b(sp);
      }
    }

    i = UN->size[0] * UN->size[1];
    UN->size[0] = unnamed_idx_0;
    UN->size[1] = unnamed_idx_1;
    emxEnsureCapacity_real_T(sp, UN, i, &l_emlrtRTEI);
    for (r = 0; r <= R; r++) {
      for (b_i = 0; b_i <= M; b_i++) {
        if ((r + 1 < 1) || (r + 1 > XN->size[1])) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, XN->size[1], &w_emlrtBCI, sp);
        }

        if ((b_i + 1 < 1) || (b_i + 1 > L->size[0])) {
          emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, L->size[0], &x_emlrtBCI, sp);
        }

        if ((r + 1 < 1) || (r + 1 > L->size[1])) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, L->size[1], &x_emlrtBCI, sp);
        }

        if ((b_i + 1 < 1) || (b_i + 1 > UN->size[0])) {
          emlrtDynamicBoundsCheckR2012b(b_i + 1, 1, UN->size[0], &y_emlrtBCI, sp);
        }

        if ((r + 1 < 1) || (r + 1 > UN->size[1])) {
          emlrtDynamicBoundsCheckR2012b(r + 1, 1, UN->size[1], &y_emlrtBCI, sp);
        }

        UN->data[b_i + UN->size[0] * r] = XN->data[r] * L->data[b_i + L->size[0]
          * r];
        if (*emlrtBreakCheckR2012bFlagVar != 0) {
          emlrtBreakCheckR2012b(sp);
        }
      }

      if (*emlrtBreakCheckR2012bFlagVar != 0) {
        emlrtBreakCheckR2012b(sp);
      }
    }

    st.site = &b_emlrtRSI;
    if ((QN->size[0] != QN_1->size[0]) || (QN->size[1] != QN_1->size[1])) {
      emlrtErrorWithMessageIdR2018a(&st, &e_emlrtRTEI, "MATLAB:dimagree",
        "MATLAB:dimagree", 0);
    }

    st.site = &b_emlrtRSI;
    b_st.site = &b_emlrtRSI;
    n = QN->size[0] * QN->size[1];
    i = QN_1->size[0] * QN_1->size[1];
    QN_1->size[0] = QN->size[0];
    QN_1->size[1] = QN->size[1];
    emxEnsureCapacity_real_T(&b_st, QN_1, i, &m_emlrtRTEI);
    for (i = 0; i < n; i++) {
      QN_1->data[i] = 1.0 - QN->data[i] / QN_1->data[i];
    }

    c_st.site = &h_emlrtRSI;
    nx = QN_1->size[0] * QN_1->size[1];
    i = relprio->size[0] * relprio->size[1];
    relprio->size[0] = QN_1->size[0];
    relprio->size[1] = QN_1->size[1];
    emxEnsureCapacity_real_T(&c_st, relprio, i, &n_emlrtRTEI);
    d_st.site = &i_emlrtRSI;
    if ((1 <= nx) && (nx > 2147483646)) {
      e_st.site = &g_emlrtRSI;
      check_forloop_overflow_error(&e_st);
    }

    for (n = 0; n < nx; n++) {
      relprio->data[n] = muDoubleScalarAbs(QN_1->data[n]);
    }

    b_st.site = &j_emlrtRSI;
    c_st.site = &k_emlrtRSI;
    d_st.site = &l_emlrtRSI;
    if (((relprio->size[0] != 1) || (relprio->size[1] != 1)) && (relprio->size[0]
         == 1)) {
      emlrtErrorWithMessageIdR2018a(&d_st, &d_emlrtRTEI,
        "Coder:toolbox:autoDimIncompatibility",
        "Coder:toolbox:autoDimIncompatibility", 0);
    }

    if (relprio->size[0] < 1) {
      emlrtErrorWithMessageIdR2018a(&d_st, &c_emlrtRTEI,
        "Coder:toolbox:eml_min_or_max_varDimZero",
        "Coder:toolbox:eml_min_or_max_varDimZero", 0);
    }

    e_st.site = &m_emlrtRSI;
    f_st.site = &n_emlrtRSI;
    g_st.site = &o_emlrtRSI;
    nx = relprio->size[0];
    n = relprio->size[1];
    i = maxval->size[0] * maxval->size[1];
    maxval->size[0] = 1;
    maxval->size[1] = relprio->size[1];
    emxEnsureCapacity_real_T(&g_st, maxval, i, &o_emlrtRTEI);
    if (relprio->size[1] >= 1) {
      h_st.site = &q_emlrtRSI;
      if (relprio->size[1] > 2147483646) {
        i_st.site = &g_emlrtRSI;
        check_forloop_overflow_error(&i_st);
      }

      for (r = 0; r < n; r++) {
        maxval->data[r] = relprio->data[relprio->size[0] * r];
        h_st.site = &p_emlrtRSI;
        if ((2 <= nx) && (nx > 2147483646)) {
          i_st.site = &g_emlrtRSI;
          check_forloop_overflow_error(&i_st);
        }

        for (b_i = 2; b_i <= nx; b_i++) {
          y = maxval->data[r];
          b = relprio->data[(b_i + relprio->size[0] * r) - 1];
          if ((!muDoubleScalarIsNaN(b)) && (muDoubleScalarIsNaN(y) || (y < b)))
          {
            maxval->data[r] = b;
          }
        }
      }
    }

    st.site = &b_emlrtRSI;
    i = x->size[0] * x->size[1];
    x->size[0] = 1;
    x->size[1] = maxval->size[1];
    emxEnsureCapacity_boolean_T(&st, x, i, &p_emlrtRTEI);
    n = maxval->size[0] * maxval->size[1];
    for (i = 0; i < n; i++) {
      x->data[i] = (maxval->data[i] < tol);
    }

    overflow = (x->size[1] != 0);
    if (overflow) {
      b_st.site = &r_emlrtRSI;
      c_st.site = &s_emlrtRSI;
      if ((1 <= x->size[1]) && (x->size[1] > 2147483646)) {
        d_st.site = &g_emlrtRSI;
        check_forloop_overflow_error(&d_st);
      }

      n = 0;
      exitg2 = false;
      while ((!exitg2) && (n <= x->size[1] - 1)) {
        if (!x->data[n]) {
          overflow = false;
          exitg2 = true;
        } else {
          n++;
        }
      }
    }

    if (overflow) {
      exitg1 = true;
    } else {
      it++;
      if (*emlrtBreakCheckR2012bFlagVar != 0) {
        emlrtBreakCheckR2012b(sp);
      }
    }
  }

  emxFree_boolean_T(&x);
  emxFree_real_T(&maxval);
  emxFree_real_T(&QN_1);
  emxFree_real_T(&relprio);
  emxFree_real_T(&CN);
  emlrtHeapReferenceStackLeaveFcnR2012b(sp);
}

/* End of code generation (pfqn_amvabs.c) */
