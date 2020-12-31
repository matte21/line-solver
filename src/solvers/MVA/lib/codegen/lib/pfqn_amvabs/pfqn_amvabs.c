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
#include "pfqn_amvabs_emxutil.h"
#include "pfqn_amvabs_types.h"
#include "rt_nonfinite.h"
#include "rt_nonfinite.h"
#include <math.h>

/* Function Definitions */
void pfqn_amvabs(const emxArray_real_T *L, const emxArray_real_T *N, const
                 emxArray_real_T *Z, double tol, double maxiter, emxArray_real_T
                 *QN, const emxArray_real_T *weight, emxArray_real_T *XN,
                 emxArray_real_T *UN)
{
  emxArray_boolean_T *x;
  emxArray_real_T *CN;
  emxArray_real_T *QN_1;
  emxArray_real_T *maxval;
  emxArray_real_T *relprio;
  double b;
  double y;
  int M;
  int R;
  int i;
  int it;
  int n;
  int nx;
  int r;
  int unnamed_idx_0;
  int unnamed_idx_1;
  boolean_T b_y;
  boolean_T exitg1;
  boolean_T exitg2;
  emxInit_real_T(&CN, 2);

  /*  [XN,QN,UN]=PFQN_AMVABS(L,N,Z,TOL,MAXITER,QN,WEIGHT) */
  R = L->size[1] - 1;
  M = L->size[0] - 1;
  i = CN->size[0] * CN->size[1];
  CN->size[0] = L->size[0];
  CN->size[1] = L->size[1];
  emxEnsureCapacity_real_T(CN, i);
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
  emxEnsureCapacity_real_T(XN, i);
  n = L->size[1];
  for (i = 0; i < n; i++) {
    XN->data[i] = 0.0;
  }

  unnamed_idx_0 = L->size[0];
  unnamed_idx_1 = L->size[1];
  i = UN->size[0] * UN->size[1];
  UN->size[0] = L->size[0];
  UN->size[1] = L->size[1];
  emxEnsureCapacity_real_T(UN, i);
  n = L->size[0] * L->size[1];
  for (i = 0; i < n; i++) {
    UN->data[i] = 0.0;
  }

  it = 0;
  emxInit_real_T(&relprio, 2);
  emxInit_real_T(&QN_1, 2);
  emxInit_real_T(&maxval, 2);
  emxInit_boolean_T(&x, 2);
  exitg1 = false;
  while ((!exitg1) && (it <= (int)maxiter - 1)) {
    i = QN_1->size[0] * QN_1->size[1];
    QN_1->size[0] = QN->size[0];
    QN_1->size[1] = QN->size[1];
    emxEnsureCapacity_real_T(QN_1, i);
    n = QN->size[0] * QN->size[1];
    for (i = 0; i < n; i++) {
      QN_1->data[i] = QN->data[i];
    }

    i = relprio->size[0] * relprio->size[1];
    relprio->size[0] = L->size[0];
    relprio->size[1] = L->size[1];
    emxEnsureCapacity_real_T(relprio, i);
    for (i = 0; i <= M; i++) {
      for (r = 0; r <= R; r++) {
        relprio->data[i + relprio->size[0] * r] = QN->data[i + QN->size[0] * r] *
          weight->data[i + weight->size[0] * r];
      }
    }

    for (r = 0; r <= R; r++) {
      for (i = 0; i <= M; i++) {
        CN->data[i + CN->size[0] * r] = L->data[i + L->size[0] * r];
        for (nx = 0; nx <= R; nx++) {
          if (nx + 1 != r + 1) {
            CN->data[i + CN->size[0] * r] += L->data[i + L->size[0] * r] *
              QN->data[i + QN->size[0] * nx] * relprio->data[i + relprio->size[0]
              * nx] / relprio->data[i + relprio->size[0] * r];
          } else {
            CN->data[i + CN->size[0] * r] += L->data[i + L->size[0] * r] *
              QN->data[i + QN->size[0] * r] * (N->data[r] - 1.0) / N->data[r] *
              relprio->data[i + relprio->size[0] * nx] / relprio->data[i +
              relprio->size[0] * r];
          }
        }
      }

      i = CN->size[0];
      if (CN->size[0] == 0) {
        y = 0.0;
      } else {
        y = CN->data[CN->size[0] * r];
        for (n = 2; n <= i; n++) {
          y += CN->data[(n + CN->size[0] * r) - 1];
        }
      }

      XN->data[r] = N->data[r] / (Z->data[r] + y);
    }

    i = UN->size[0] * UN->size[1];
    UN->size[0] = unnamed_idx_0;
    UN->size[1] = unnamed_idx_1;
    emxEnsureCapacity_real_T(UN, i);
    for (r = 0; r <= R; r++) {
      for (i = 0; i <= M; i++) {
        y = XN->data[r];
        QN->data[i + QN->size[0] * r] = y * CN->data[i + CN->size[0] * r];
        UN->data[i + UN->size[0] * r] = y * L->data[i + L->size[0] * r];
      }
    }

    n = QN->size[0] * QN->size[1];
    i = QN_1->size[0] * QN_1->size[1];
    QN_1->size[0] = QN->size[0];
    QN_1->size[1] = QN->size[1];
    emxEnsureCapacity_real_T(QN_1, i);
    for (i = 0; i < n; i++) {
      QN_1->data[i] = 1.0 - QN->data[i] / QN_1->data[i];
    }

    nx = QN_1->size[0] * QN_1->size[1];
    i = relprio->size[0] * relprio->size[1];
    relprio->size[0] = QN_1->size[0];
    relprio->size[1] = QN_1->size[1];
    emxEnsureCapacity_real_T(relprio, i);
    for (n = 0; n < nx; n++) {
      relprio->data[n] = fabs(QN_1->data[n]);
    }

    nx = relprio->size[0];
    n = relprio->size[1];
    i = maxval->size[0] * maxval->size[1];
    maxval->size[0] = 1;
    maxval->size[1] = relprio->size[1];
    emxEnsureCapacity_real_T(maxval, i);
    if (relprio->size[1] >= 1) {
      for (r = 0; r < n; r++) {
        maxval->data[r] = relprio->data[relprio->size[0] * r];
        for (i = 2; i <= nx; i++) {
          y = maxval->data[r];
          b = relprio->data[(i + relprio->size[0] * r) - 1];
          if ((!rtIsNaN(b)) && (rtIsNaN(y) || (y < b))) {
            maxval->data[r] = b;
          }
        }
      }
    }

    i = x->size[0] * x->size[1];
    x->size[0] = 1;
    x->size[1] = maxval->size[1];
    emxEnsureCapacity_boolean_T(x, i);
    n = maxval->size[0] * maxval->size[1];
    for (i = 0; i < n; i++) {
      x->data[i] = (maxval->data[i] < tol);
    }

    b_y = (x->size[1] != 0);
    if (b_y) {
      n = 0;
      exitg2 = false;
      while ((!exitg2) && (n <= x->size[1] - 1)) {
        if (!x->data[n]) {
          b_y = false;
          exitg2 = true;
        } else {
          n++;
        }
      }
    }

    if (b_y) {
      exitg1 = true;
    } else {
      it++;
    }
  }

  emxFree_boolean_T(&x);
  emxFree_real_T(&maxval);
  emxFree_real_T(&QN_1);
  emxFree_real_T(&relprio);
  emxFree_real_T(&CN);
}

/* End of code generation (pfqn_amvabs.c) */
