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

#ifndef PFQN_AMVABS_H
#define PFQN_AMVABS_H

/* Include files */
#include "pfqn_amvabs_types.h"
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>
#ifdef __cplusplus

extern "C" {

#endif

  /* Function Declarations */
  extern void pfqn_amvabs(const emxArray_real_T *L, const emxArray_real_T *N,
    const emxArray_real_T *Z, double tol, double maxiter, emxArray_real_T *QN,
    const emxArray_real_T *weight, emxArray_real_T *XN, emxArray_real_T *UN);

#ifdef __cplusplus

}
#endif
#endif

/* End of code generation (pfqn_amvabs.h) */
