/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 *
 * main.c
 *
 * Code generation for function 'main'
 *
 */

/*************************************************************************/
/* This automatically generated example C main file shows how to call    */
/* entry-point functions that MATLAB Coder generated. You must customize */
/* this file for your application. Do not modify this file directly.     */
/* Instead, make a copy of this file, modify it, and integrate it into   */
/* your development environment.                                         */
/*                                                                       */
/* This file initializes entry-point function arguments to a default     */
/* size and value before calling the entry-point functions. It does      */
/* not store or use any values returned from the entry-point functions.  */
/* If necessary, it does pre-allocate memory for returned values.        */
/* You can use this file as a starting point for a main function that    */
/* you can deploy in your application.                                   */
/*                                                                       */
/* After you copy the file, and before you deploy it, you must make the  */
/* following changes:                                                    */
/* * For variable-size function arguments, change the example sizes to   */
/* the sizes that your application requires.                             */
/* * Change the example values of function arguments to the values that  */
/* your application requires.                                            */
/* * If the entry-point functions return values, store these values or   */
/* otherwise use them as required by your application.                   */
/*                                                                       */
/*************************************************************************/

/* Include files */
#include "main.h"
#include "pfqn_amvabs.h"
#include "pfqn_amvabs_emxAPI.h"
#include "pfqn_amvabs_terminate.h"
#include "pfqn_amvabs_types.h"
#include "rt_nonfinite.h"

/* Function Declarations */
static emxArray_real_T *argInit_1xUnbounded_real_T(void);
static double argInit_real_T(void);
static emxArray_real_T *c_argInit_UnboundedxUnbounded_r(void);
static void main_pfqn_amvabs(void);

/* Function Definitions */
static emxArray_real_T *argInit_1xUnbounded_real_T(void)
{
  emxArray_real_T *result;
  int idx0;
  int idx1;

  /* Set the size of the array.
     Change this size to the value that the application requires. */
  result = emxCreate_real_T(1, 2);

  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < 1; idx0++) {
    for (idx1 = 0; idx1 < result->size[1U]; idx1++) {
      /* Set the value of the array element.
         Change this value to the value that the application requires. */
      result->data[idx1] = argInit_real_T();
    }
  }

  return result;
}

static double argInit_real_T(void)
{
  return 0.0;
}

static emxArray_real_T *c_argInit_UnboundedxUnbounded_r(void)
{
  emxArray_real_T *result;
  int idx0;
  int idx1;

  /* Set the size of the array.
     Change this size to the value that the application requires. */
  result = emxCreate_real_T(2, 2);

  /* Loop over the array to initialize each element. */
  for (idx0 = 0; idx0 < result->size[0U]; idx0++) {
    for (idx1 = 0; idx1 < result->size[1U]; idx1++) {
      /* Set the value of the array element.
         Change this value to the value that the application requires. */
      result->data[idx0 + result->size[0] * idx1] = argInit_real_T();
    }
  }

  return result;
}

static void main_pfqn_amvabs(void)
{
  emxArray_real_T *L;
  emxArray_real_T *N;
  emxArray_real_T *QN;
  emxArray_real_T *UN;
  emxArray_real_T *XN;
  emxArray_real_T *Z;
  emxArray_real_T *weight;
  double tol_tmp;
  emxInitArray_real_T(&XN, 2);
  emxInitArray_real_T(&UN, 2);

  /* Initialize function 'pfqn_amvabs' input arguments. */
  /* Initialize function input argument 'L'. */
  L = c_argInit_UnboundedxUnbounded_r();

  /* Initialize function input argument 'N'. */
  N = argInit_1xUnbounded_real_T();

  /* Initialize function input argument 'Z'. */
  Z = argInit_1xUnbounded_real_T();
  tol_tmp = argInit_real_T();

  /* Initialize function input argument 'QN'. */
  QN = c_argInit_UnboundedxUnbounded_r();

  /* Initialize function input argument 'weight'. */
  weight = c_argInit_UnboundedxUnbounded_r();

  /* Call the entry-point 'pfqn_amvabs'. */
  pfqn_amvabs(L, N, Z, tol_tmp, tol_tmp, QN, weight, XN, UN);
  emxDestroyArray_real_T(UN);
  emxDestroyArray_real_T(XN);
  emxDestroyArray_real_T(weight);
  emxDestroyArray_real_T(QN);
  emxDestroyArray_real_T(Z);
  emxDestroyArray_real_T(N);
  emxDestroyArray_real_T(L);
}

int main(int argc, const char * const argv[])
{
  (void)argc;
  (void)argv;

  /* The initialize function is being called automatically from your entry-point function. So, a call to initialize is not included here. */
  /* Invoke the entry-point functions.
     You can call entry-point functions multiple times. */
  main_pfqn_amvabs();

  /* Terminate the application.
     You do not need to do this more than one time. */
  pfqn_amvabs_terminate();
  return 0;
}

/* End of code generation (main.c) */
