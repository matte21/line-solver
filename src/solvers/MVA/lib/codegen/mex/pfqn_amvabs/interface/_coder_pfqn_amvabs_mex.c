/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * _coder_pfqn_amvabs_mex.c
 *
 * Code generation for function '_coder_pfqn_amvabs_mex'
 *
 */

/* Include files */
#include "_coder_pfqn_amvabs_mex.h"
#include "_coder_pfqn_amvabs_api.h"
#include "pfqn_amvabs_data.h"
#include "pfqn_amvabs_initialize.h"
#include "pfqn_amvabs_terminate.h"
#include "rt_nonfinite.h"

/* Function Definitions */
void mexFunction(int32_T nlhs, mxArray *plhs[], int32_T nrhs, const mxArray
                 *prhs[])
{
  mexAtExit(&pfqn_amvabs_atexit);

  /* Module initialization. */
  pfqn_amvabs_initialize();

  /* Dispatch the entry-point. */
  pfqn_amvabs_mexFunction(nlhs, plhs, nrhs, prhs);

  /* Module termination. */
  pfqn_amvabs_terminate();
}

emlrtCTX mexFunctionCreateRootTLS(void)
{
  emlrtCreateRootTLS(&emlrtRootTLSGlobal, &emlrtContextGlobal, NULL, 1);
  return emlrtRootTLSGlobal;
}

void pfqn_amvabs_mexFunction(int32_T nlhs, mxArray *plhs[3], int32_T nrhs, const
  mxArray *prhs[7])
{
  emlrtStack st = { NULL,              /* site */
    NULL,                              /* tls */
    NULL                               /* prev */
  };

  const mxArray *outputs[3];
  int32_T b_nlhs;
  st.tls = emlrtRootTLSGlobal;

  /* Check for proper number of arguments. */
  if (nrhs != 7) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:WrongNumberOfInputs", 5, 12, 7, 4,
                        11, "pfqn_amvabs");
  }

  if (nlhs > 3) {
    emlrtErrMsgIdAndTxt(&st, "EMLRT:runTime:TooManyOutputArguments", 3, 4, 11,
                        "pfqn_amvabs");
  }

  /* Call the function. */
  pfqn_amvabs_api(prhs, nlhs, outputs);

  /* Copy over outputs to the caller. */
  if (nlhs < 1) {
    b_nlhs = 1;
  } else {
    b_nlhs = nlhs;
  }

  emlrtReturnArrays(b_nlhs, plhs, outputs);
}

/* End of code generation (_coder_pfqn_amvabs_mex.c) */
