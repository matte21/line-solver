/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * pfqn_amvabs_initialize.c
 *
 * Code generation for function 'pfqn_amvabs_initialize'
 *
 */

/* Include files */
#include "pfqn_amvabs_initialize.h"
#include "_coder_pfqn_amvabs_mex.h"
#include "pfqn_amvabs_data.h"
#include "rt_nonfinite.h"

/* Function Definitions */
void pfqn_amvabs_initialize(void)
{
  emlrtStack st = { NULL,              /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  mex_InitInfAndNan();
  mexFunctionCreateRootTLS();
  emlrtBreakCheckR2012bFlagVar = emlrtGetBreakCheckFlagAddressR2012b();
  st.tls = emlrtRootTLSGlobal;
  emlrtClearAllocCountR2012b(&st, false, 0U, 0);
  emlrtEnterRtStackR2012b(&st);
  emlrtFirstTimeR2012b(emlrtRootTLSGlobal);
}

/* End of code generation (pfqn_amvabs_initialize.c) */
