/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * pfqn_amvabs.h
 *
 * Code generation for function 'pfqn_amvabs'
 *
 */

#pragma once

/* Include files */
#include "pfqn_amvabs_types.h"
#include "rtwtypes.h"
#include "emlrt.h"
#include "mex.h"
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Function Declarations */
void pfqn_amvabs(const emlrtStack *sp, const emxArray_real_T *L, const
                 emxArray_real_T *N, const emxArray_real_T *Z, real_T tol,
                 real_T maxiter, emxArray_real_T *QN, const emxArray_real_T
                 *weight, emxArray_real_T *XN, emxArray_real_T *UN);

/* End of code generation (pfqn_amvabs.h) */
