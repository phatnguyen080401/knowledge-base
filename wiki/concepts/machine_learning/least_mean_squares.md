---
title: Least Mean Squares (LMS) Algorithm
tags: [machine-learning, model-training, linear-regression, stochastic-optimization]
created: 2026-11-06 15:49:01
updated: 2026-11-06 15:49:01
---

# Least Mean Squares (LMS) Algorithm

The least mean squares (LMS) algorithm fits a linear model by repeatedly nudging each parameter in
proportion to the current prediction error. It is
[[concepts/machine_learning/gradient_descent|Gradient Descent]] applied to the
[[concepts/machine_learning/least_squares|Least Squares]] cost. Widrow and Hoff introduced it in
1960 to train ADALINE, an early adaptive neuron, which is why it is also called the Widrow-Hoff
rule or the delta rule.

## Why It Matters

- **The update is intuitive.** A large error produces a large correction; a correct prediction
  produces none.
- **It is cheap and online.** Each update touches one example in $O(d)$ time, so it can adapt to a
  stream of data that never ends.
- **It is the template for neural network training.** Replace the linear model with a network and
  the same error-times-input update becomes backpropagation with SGD.
- **It is still used in signal processing.** Adaptive filters for echo cancellation, channel
  equalization, and noise cancellation run LMS continuously.

## Deriving the Update

With $h_\theta(x) = \theta^\top x$ and the cost for one example $J(\theta) = \tfrac{1}{2}(h_\theta(x) - y)^2$,
the partial derivative for parameter $j$ is

$$
\frac{\partial J}{\partial \theta_j} = \left(h_\theta(x) - y\right) \cdot \frac{\partial}{\partial \theta_j}\left(\sum_{k} \theta_k x_k - y\right) = \left(h_\theta(x) - y\right) x_j
$$

A gradient step with learning rate $\alpha$ then gives the LMS update rule:

$$
\theta_j := \theta_j + \alpha\left(y^{(i)} - h_\theta(x^{(i)})\right) x_j^{(i)}
$$

> [!important] Error times input
> The correction is the error $(y - h_\theta(x))$ times the input $x_j$. A feature that was zero for
> this example gets no update, and features with large values move the most.

## Batch and Stochastic Forms

| Form | One update uses | Rule |
| --- | --- | --- |
| Batch gradient descent | All $n$ examples | $\theta := \theta + \alpha \sum_{i=1}^{n}\left(y^{(i)} - h_\theta(x^{(i)})\right) x^{(i)}$ |
| Stochastic (incremental) gradient descent | One example at a time, in turn | $\theta := \theta + \alpha\left(y^{(i)} - h_\theta(x^{(i)})\right) x^{(i)}$ |

Because the least-squares cost is a convex quadratic with one global minimum, batch gradient descent
converges to it when $\alpha$ is small enough. The stochastic form starts improving after the first
example and is usually faster on large datasets. With a fixed $\alpha$ it keeps oscillating near
the minimum rather than settling exactly on it; letting $\alpha$ decay to zero makes it converge.

```python
import numpy as np

def lms(X, y, alpha=0.01, epochs=50, seed=0):
    """Stochastic LMS. X is (n, d) with a leading column of ones; y is (n,)."""
    rng = np.random.default_rng(seed)
    theta = np.zeros(X.shape[1])
    for _ in range(epochs):
        for i in rng.permutation(len(X)):
            error = y[i] - X[i] @ theta
            theta += alpha * error * X[i]      # the LMS update
    return theta
```

## Choosing the Learning Rate

- **Too large** and the updates overshoot and diverge. For a stable update, $\alpha$ must be below
  $2$ divided by the largest eigenvalue of the input correlation matrix, the same limit described in
  [[concepts/machine_learning/gradient_descent#The Update Rule|Gradient Descent]].
- **Too small** and convergence is slow.
- **Normalized LMS (NLMS)** divides the step by $\lVert x^{(i)} \rVert^2$, so the step size no
  longer depends on how large the inputs are. It is the usual choice in adaptive filtering.
- **Standardize features** before training, so that no single feature dictates the safe step size.

## Related Concepts

- [[concepts/machine_learning/least_squares|Least Squares]] — the cost LMS minimizes
- [[concepts/machine_learning/normal_equations|Normal Equations]] — the closed-form alternative that reaches the same answer in one step
- [[concepts/machine_learning/gradient_descent|Gradient Descent]] — the general method; LMS is its simplest useful case
- [[concepts/machine_learning/cost_function|Cost Function]] — why squared error, and what other costs would change in the update

## References

- Widrow and Hoff (1960). *Adaptive Switching Circuits.* IRE WESCON Convention Record.
- Haykin (2002). *Adaptive Filter Theory*, 4th ed. Prentice Hall.
- Ng, A. *CS229 Lecture Notes: Supervised Learning*, Part I. Stanford University.
