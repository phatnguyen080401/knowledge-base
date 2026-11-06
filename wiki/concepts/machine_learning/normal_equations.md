---
title: Normal Equations
tags: [machine-learning, model-training, linear-regression]
created: 2026-11-06 15:49:01
updated: 2026-11-06 15:49:01
---

# Normal Equations

The normal equations $X^\top X\theta = X^\top \vec{y}$ give the parameters of a linear
[[concepts/machine_learning/least_squares|Least Squares]] fit in closed form, with no iteration
and no learning rate. They come from setting the gradient of the least-squares cost to zero, a
step carried out with [[concepts/machine_learning/matrix_derivative|Matrix Derivatives]].

## Why It Matters

- **One step, exact answer.** For moderate numbers of features, solving them is faster and
  simpler than running gradient descent to convergence.
- **They reveal the structure of the problem.** Invertibility of $X^\top X$, collinearity, and the
  effect of regularization are all visible in one formula.
- **They are the reference.** Iterative methods such as the
  [[concepts/machine_learning/least_mean_squares|LMS Algorithm]] are checked against them.

## Derivation

Stack the $n$ training inputs as rows of the design matrix $X$ ($n \times d$, intercept column
included) and the targets as $\vec{y}$. The cost is

$$
J(\theta) = \frac{1}{2}(X\theta - \vec{y})^\top(X\theta - \vec{y}) = \frac{1}{2}\left(\theta^\top X^\top X \theta - 2\,\vec{y}^\top X\theta + \vec{y}^\top\vec{y}\right)
$$

using $\theta^\top X^\top \vec{y} = \vec{y}^\top X\theta$, since both are scalars. With the vector
identities $\nabla_\theta\, b^\top\theta = b$ and $\nabla_\theta\, \theta^\top A\theta = 2A\theta$ for
symmetric $A$:

$$
\nabla_\theta J(\theta) = X^\top X\theta - X^\top \vec{y}
$$

Setting this to zero gives the normal equations and, when $X^\top X$ is invertible, the solution:

$$
X^\top X\,\theta = X^\top \vec{y}
\qquad\Longrightarrow\qquad
\theta = (X^\top X)^{-1} X^\top \vec{y}
$$

The cost is convex, so this stationary point is the global minimum. The name comes from geometry:
the residual $\vec{y} - X\theta$ is *normal* (perpendicular) to every column of $X$.

## Computing the Solution

> [!warning] Do not form the inverse
> Computing $(X^\top X)^{-1}$ explicitly is slow and loses precision, because forming $X^\top X$
> squares the condition number of $X$. Use a solver.

| Method | How | Notes |
| --- | --- | --- |
| Cholesky | Factor $X^\top X = LL^\top$, then two triangular solves | Fastest; fine when $X$ is well conditioned |
| QR decomposition | Factor $X = QR$, then solve $R\theta = Q^\top\vec{y}$ | Never forms $X^\top X$, so it is more accurate; the usual default |
| SVD / pseudoinverse | $\theta = X^{+}\vec{y}$ | Slowest; handles rank-deficient $X$ by returning the minimum-norm solution |

```python
import numpy as np

rng = np.random.default_rng(0)
X = np.column_stack([np.ones(100), rng.normal(size=(100, 2))])   # intercept + 2 features
y = X @ np.array([1.0, 2.0, -3.0]) + 0.1 * rng.normal(size=100)

theta_solve = np.linalg.solve(X.T @ X, X.T @ y)      # the normal equations, solved directly
theta_lstsq, *_ = np.linalg.lstsq(X, y, rcond=None)  # SVD-based, preferred in practice
print(theta_solve, theta_lstsq)                       # both close to [1, 2, -3]
```

## When $X^\top X$ Is Not Invertible

It is singular when some features are exact linear combinations of others (for example, a length
recorded in both metres and feet) or when there are more features than examples ($d > n$).

- **Remove redundant features** to restore full rank.
- **Use the pseudoinverse,** which picks the solution with the smallest $\lVert\theta\rVert$.
- **Add ridge regularization.** Minimizing $J(\theta) + \tfrac{\lambda}{2}\lVert\theta\rVert^2$ changes
  the equations to $(X^\top X + \lambda I)\theta = X^\top\vec{y}$, which is invertible for any
  $\lambda > 0$. The intercept is usually left unpenalized.

## Normal Equations or Gradient Descent?

| | Normal equations | Gradient descent |
| --- | --- | --- |
| Learning rate | None | Must be tuned |
| Iterations | None | Many |
| Cost | $O(nd^2 + d^3)$ | $O(nd)$ per pass |
| Good for | $d$ up to a few thousand | Very large $d$ or $n$, or streaming data |
| Applies to | Linear least squares only | Any differentiable cost |

## Related Concepts

- [[concepts/machine_learning/least_squares|Least Squares]] — the problem the normal equations solve, with its probabilistic and geometric interpretations
- [[concepts/machine_learning/matrix_derivative|Matrix Derivative]] — the identities used to take the gradient
- [[concepts/machine_learning/least_mean_squares|LMS Algorithm]] — the iterative alternative that converges to the same $\theta$
- [[concepts/machine_learning/gradient_descent|Gradient Descent]] — preferred when the closed form is too expensive

## References

- Ng, A. *CS229 Lecture Notes: Supervised Learning*, Part I §2. Stanford University.
- Golub and Van Loan (2013). *Matrix Computations*, 4th ed., chapter 5. Johns Hopkins University Press.
- Trefethen and Bau (1997). *Numerical Linear Algebra*, lectures 11 and 18. SIAM.
