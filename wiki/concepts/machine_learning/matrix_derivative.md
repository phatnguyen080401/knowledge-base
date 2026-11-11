---
title: Matrix Derivative
tags: [machine-learning, model-training, linear-regression]
created: 2026-11-06 15:49:01
updated: 2026-11-06 15:49:01
---

# Matrix Derivative

The matrix derivative of a scalar function $f(A)$ with respect to a matrix $A$ is the matrix of
partial derivatives $\partial f / \partial A_{ij}$, laid out in the same shape as $A$. It lets a
gradient over many parameters be written and manipulated as one matrix expression. Its standard
use in introductory machine learning is deriving the
[[concepts/machine_learning/normal_equations|Normal Equations]] for
[[concepts/machine_learning/least_squares|Least Squares]].

## Why It Matters

- **Compact gradients.** One identity replaces pages of index-by-index partial derivatives.
- **Closed-form solutions.** Setting a matrix gradient to zero yields solutions such as the normal
  equations and the maximum-likelihood estimates for Gaussian models.
- **Checking backpropagation.** Hand-derived matrix gradients verify what automatic
  differentiation computes in [[concepts/machine_learning/gradient_descent|Gradient Descent]].

## Definition

For $f : \mathbb{R}^{m \times n} \to \mathbb{R}$, the gradient is the $m \times n$ matrix

$$
\nabla_A f(A) =
\begin{bmatrix}
\dfrac{\partial f}{\partial A_{11}} & \cdots & \dfrac{\partial f}{\partial A_{1n}} \\
\vdots & \ddots & \vdots \\
\dfrac{\partial f}{\partial A_{m1}} & \cdots & \dfrac{\partial f}{\partial A_{mn}}
\end{bmatrix}
$$

> [!example] A 2×2 example
> For $f(A) = \tfrac{3}{2}A_{11} + 5A_{12}^2 + A_{21}A_{22}$, the gradient is
> $\nabla_A f(A) = \begin{bmatrix} 3/2 & 10A_{12} \\ A_{22} & A_{21} \end{bmatrix}$.

This is the *denominator layout*, in which the gradient has the shape of the variable. Some texts
use the transposed *numerator layout*; mixing the two is the most common source of results that
are correct except for a missing transpose.

## The Trace

The trace of a square matrix is the sum of its diagonal, $\operatorname{tr} A = \sum_i A_{ii}$. A
scalar equals its own trace, so scalar expressions can be rewritten as traces and rearranged.

| Property | Identity |
| --- | --- |
| Cyclic | $\operatorname{tr} AB = \operatorname{tr} BA$, and $\operatorname{tr} ABC = \operatorname{tr} CAB = \operatorname{tr} BCA$ |
| Transpose | $\operatorname{tr} A = \operatorname{tr} A^\top$ |
| Linear | $\operatorname{tr}(A + B) = \operatorname{tr} A + \operatorname{tr} B$, and $\operatorname{tr}(aA) = a \operatorname{tr} A$ |
| Scalar | $\operatorname{tr} a = a$ for a real number $a$ |

## Core Identities

For matrices of compatible shape:

| Identity | Notes |
| --- | --- |
| $\nabla_A \operatorname{tr} AB = B^\top$ | The basic building block |
| $\nabla_{A^\top} f(A) = \left(\nabla_A f(A)\right)^\top$ | Differentiating with respect to the transpose |
| $\nabla_A \operatorname{tr} ABA^\top C = CAB + C^\top A B^\top$ | Gives the quadratic case below |
| $\nabla_A \lvert A \rvert = \lvert A \rvert (A^{-1})^\top$ | For square, invertible $A$; used in Gaussian maximum likelihood |

For vectors $x$, $b$ and a matrix $A$, the special cases used most often:

| Identity | Notes |
| --- | --- |
| $\nabla_x\, b^\top x = b$ | Linear term |
| $\nabla_x\, x^\top A x = (A + A^\top)\,x$ | Equals $2Ax$ when $A$ is symmetric |
| $\nabla_x \lVert Ax - b \rVert^2 = 2A^\top(Ax - b)$ | The least-squares gradient |

## Worked Use: The Least-Squares Gradient

With $J(\theta) = \tfrac{1}{2}(X\theta - \vec{y})^\top(X\theta - \vec{y})$, expand and differentiate
term by term:

$$
\begin{aligned}
\nabla_\theta J(\theta)
&= \tfrac{1}{2}\nabla_\theta\left(\theta^\top X^\top X\theta - \theta^\top X^\top\vec{y} - \vec{y}^\top X\theta + \vec{y}^\top\vec{y}\right) \\
&= \tfrac{1}{2}\left(2X^\top X\theta - 2X^\top\vec{y}\right) \\
&= X^\top X\theta - X^\top\vec{y}
\end{aligned}
$$

The quadratic term uses $\nabla_x x^\top A x = 2Ax$ with the symmetric $A = X^\top X$; the two middle
terms are equal scalars and each contributes $X^\top\vec{y}$; the last term does not depend on
$\theta$. Setting the result to zero gives the normal equations.

> [!tip] Check the shapes
> A gradient with respect to $\theta \in \mathbb{R}^d$ must be a $d$-vector. If an identity yields a
> row vector or the wrong dimensions, a transpose has gone missing. A finite-difference check on a
> small random example catches the rest.

## Related Concepts

- [[concepts/machine_learning/normal_equations|Normal Equations]] — the closed-form result these identities derive
- [[concepts/machine_learning/least_squares|Least Squares]] — the cost whose gradient is worked out above
- [[concepts/machine_learning/gradient_descent|Gradient Descent]] — uses the same gradients iteratively instead of solving for zero

## References

- Ng, A. *CS229 Lecture Notes: Supervised Learning*, Part I §2.1. Stanford University.
- Petersen and Pedersen (2012). *The Matrix Cookbook.* Technical University of Denmark.
- Magnus and Neudecker (2019). *Matrix Differential Calculus with Applications in Statistics and Econometrics*, 3rd ed. Wiley.
