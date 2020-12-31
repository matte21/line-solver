/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_pfqn_amvabs_api.h
 *
 * Code generation for function 'pfqn_amvabs'
 *
 */

#ifndef _CODER_PFQN_AMVABS_API_H
#define _CODER_PFQN_AMVABS_API_H

/* Include files */
#include "emlrt.h"
#include "tmwtypes.h"
#include <string.h>

/* Type Definitions */
#ifndef struct_emxArray_real_T
#define struct_emxArray_real_T

struct emxArray_real_T
{
  real_T *data;
  int32_T *size;
  int32_T allocatedSize;
  int32_T numDimensions;
  boolean_T canFreeData;
};

#endif                                 /*struct_emxArray_real_T*/

#ifndef typedef_emxArray_real_T
#define typedef_emxArray_real_T

typedef struct emxArray_real_T emxArray_real_T;

#endif                                 /*typedef_emxArray_real_T*/

/* Variable Declarations */
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

#ifdef __cplusplus

extern "C" {

#endif

  /* Function Declarations */
  void pfqn_amvabs(emxArray_real_T *L, emxArray_real_T *N, emxArray_real_T *Z,
                   real_T tol, real_T maxiter, emxArray_real_T *QN,
                   emxArray_real_T *weight, emxArray_real_T *XN, emxArray_real_T
                   *UN);
  void pfqn_amvabs_api(const mxArray * const prhs[7], int32_T nlhs, const
                       mxArray *plhs[3]);
  void pfqn_amvabs_atexit(void);
  void pfqn_amvabs_initialize(void);
  void pfqn_amvabs_terminate(void);
  void pfqn_amvabs_xil_shutdown(void);
  void pfqn_amvabs_xil_terminate(void);

#ifdef __cplusplus

}
#endif
#endif

/* End of code generation (_coder_pfqn_amvabs_api.h) */
