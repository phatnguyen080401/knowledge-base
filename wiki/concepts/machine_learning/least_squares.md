---
title: Least Squares
tags: [machine-learning, model-training, linear-regression]
created: 2026-11-06 15:49:01
updated: 2026-11-06 15:49:01
---

# Least Squares

Least squares fits a model by choosing the parameters that minimize the sum of squared differences
between its predictions and the observed targets. Applied to a linear model it gives ordinary
least squares (OLS) linear regression, the standard first example of
[[concepts/machine_learning/supervised_learning|Supervised Learning]] and of a
[[concepts/machine_learning/cost_function|Cost Function]]. Legendre published the method in 1805,
and Gauss claimed to have used it since 1795.

## Why It Matters

- **It has a closed-form solution.** For a linear model the minimizer can be written down exactly,
  which is rare in machine learning.
- **It is well understood.** Its geometry, statistics, and failure modes have been studied for two
  centuries.
- **It is the baseline.** A new regression model should beat linear least squares before it earns
  its extra complexity.

## The Model and the Cost

Add an intercept feature $x_0 = 1$, so a linear hypothesis over $d$ features is

$$
h_\theta(x) = \theta_0 + \theta_1 x_1 + \dots + \theta_d x_d = \theta^\top x
$$

The least-squares cost sums the squared errors over the $n$ training examples:

$$
J(\theta) = \frac{1}{2}\sum_{i=1}^{n}\left(\theta^\top x^{(i)} - y^{(i)}\right)^2 = \frac{1}{2}\lVert X\theta - \vec{y} \rVert^2
$$

Here the design matrix $X$ is $n \times (d+1)$ with one training input per row, and $\vec{y}$ is the
vector of targets. $J$ is a convex quadratic, so any point where its gradient is zero is the global
minimum.

## Two Ways to Minimize It

| | [[concepts/machine_learning/least_mean_squares\|LMS Algorithm]] (gradient descent) | [[concepts/machine_learning/normal_equations\|Normal Equations]] (closed form) |
| --- | --- | --- |
| Solution | $\theta_j := \theta_j + \alpha\,(y^{(i)} - h_\theta(x^{(i)}))\,x_j^{(i)}$, repeated | $\theta = (X^\top X)^{-1} X^\top \vec{y}$ |
| Cost | $O(nd)$ per pass over the data | $O(nd^2 + d^3)$ once |
| Needs a learning rate | Yes | No |
| Works when | Data is large, streaming, or $d$ is huge | $d$ is moderate (up to thousands) and $X^\top X$ is invertible |
| Generalizes to | Any differentiable model | Only linear least-squares problems |

The closed form is derived with [[concepts/machine_learning/matrix_derivative|Matrix Derivatives]].

## Why Squared Error? The Probabilistic View

Assume each target is the linear prediction plus Gaussian noise:

$$
y^{(i)} = \theta^\top x^{(i)} + \epsilon^{(i)}, \qquad \epsilon^{(i)} \sim \mathcal{N}(0, \sigma^2) \text{ independently}
$$

The log-likelihood of the data is then

$$
\ell(\theta) = n \log \frac{1}{\sqrt{2\pi}\,\sigma} - \frac{1}{\sigma^2} \cdot \frac{1}{2}\sum_{i=1}^{n}\left(y^{(i)} - \theta^\top x^{(i)}\right)^2
$$

Maximizing it means minimizing the second term, which is exactly $J(\theta)$. So least squares is
maximum-likelihood estimation under independent Gaussian noise, and the best $\theta$ does not
depend on $\sigma$. The assumption is sufficient but not necessary; least squares is also justified
in other ways.

## The Geometric View

$X\theta$ ranges over the column space of $X$. Least squares picks the point in that space closest
to $\vec{y}$, which is the orthogonal projection of $\vec{y}$ onto it. The residual
$\vec{y} - X\theta$ is therefore perpendicular to every column of $X$:
$X^\top(\vec{y} - X\theta) = 0$, which rearranges to the normal equations. "Normal" here means
perpendicular.

## Pitfalls and Extensions

- **Outliers.** Squaring makes one large error dominate. Use Huber or absolute loss when the data
  has outliers.
- **Collinear features.** When features are nearly linear combinations of each other, $X^\top X$
  is close to singular and $\theta$ becomes unstable. Ridge regression adds $\lambda \lVert\theta\rVert^2$
  and solves $(X^\top X + \lambda I)\theta = X^\top \vec{y}$, which is always invertible for
  $\lambda > 0$.
- **Non-linear relationships.** "Linear" means linear in $\theta$, not in $x$. Adding features such
  as $x^2$ or $\log x$ fits curves with the same machinery, at the risk of overfitting.
- **Locally weighted regression.** Weighting each example's error by its closeness to the query
  point, $w^{(i)} = \exp\!\left(-\lVert x^{(i)} - x \rVert^2 / 2\tau^2\right)$, fits a separate line
  around every prediction. It is a non-parametric method, because the whole training set must be
  kept.

## Related Concepts

- [[concepts/machine_learning/least_mean_squares|LMS Algorithm]] — the gradient-descent route to the least-squares solution
- [[concepts/machine_learning/normal_equations|Normal Equations]] — the closed-form route
- [[concepts/machine_learning/matrix_derivative|Matrix Derivative]] — the calculus used to derive the closed form
- [[concepts/machine_learning/cost_function|Cost Function]] — least squares is one choice of cost among many
- [[concepts/machine_learning/gradient_descent|Gradient Descent]] — its worked example fits linear regression by minibatch SGD

## References

- Legendre (1805). *Nouvelles méthodes pour la détermination des orbites des comètes.*
- Gauss (1809). *Theoria motus corporum coelestium.*
- Ng, A. *CS229 Lecture Notes: Supervised Learning*, Part I. Stanford University.
- Hastie, Tibshirani, and Friedman (2009). *The Elements of Statistical Learning*, 2nd ed., chapter 3. Springer.
