---
title: Cost Function
tags: [machine-learning, model-training, linear-regression]
created: 2026-11-06 15:49:01
updated: 2026-11-06 15:49:01
---

# Cost Function

A cost function $J(\theta)$ measures how badly a model with parameters $\theta$ fits its training
data, as a single number to be minimized. Training a
[[concepts/machine_learning/supervised_learning|Supervised Learning]] model means finding the
$\theta$ that makes this number as small as possible, usually by
[[concepts/machine_learning/gradient_descent|Gradient Descent]].

## Why It Matters

- **It defines what "good" means.** The optimizer pursues exactly the cost it is given, so choosing
  the cost is choosing what the model will get right and what it will trade away.
- **It decides how training works.** A convex, differentiable cost can be minimized reliably; a
  non-convex or non-differentiable one needs other methods or a surrogate.
- **Its form often follows from a probability model.** Squared error and cross-entropy are both
  negative log-likelihoods, which explains when each is appropriate.

## Loss, Cost, and Objective

The terms are often used interchangeably, but a common convention separates them:

| Term | Scope | Example |
| --- | --- | --- |
| Loss $\ell(h_\theta(x), y)$ | One example | $(h_\theta(x) - y)^2$ |
| Cost $J(\theta)$ | The whole training set, usually an average or sum of losses | $\frac{1}{n}\sum_i \ell(h_\theta(x^{(i)}), y^{(i)})$ |
| Objective | Whatever is optimized, possibly with a regularization term | $J(\theta) + \lambda \lVert \theta \rVert^2$ |

## The Least-Squares Cost

The standard first example, from linear regression with $h_\theta(x) = \theta^\top x$:

$$
J(\theta) = \frac{1}{2}\sum_{i=1}^{n}\left(h_\theta(x^{(i)}) - y^{(i)}\right)^2
$$

It adds up the squared prediction errors. The factor $\tfrac{1}{2}$ only cancels the 2 that
appears when differentiating. This cost is a convex bowl in $\theta$, so it has a single minimum,
found either iteratively by the
[[concepts/machine_learning/least_mean_squares|LMS Algorithm]] or in closed form by the
[[concepts/machine_learning/normal_equations|Normal Equations]]. The
[[concepts/machine_learning/least_squares|Least Squares]] note covers it in full.

## Common Losses

| Loss | Formula (one example) | Used for | Property |
| --- | --- | --- | --- |
| Squared error | $(\hat{y} - y)^2$ | Regression | Punishes large errors heavily; sensitive to outliers |
| Absolute error | $\lvert \hat{y} - y \rvert$ | Regression | Robust to outliers; predicts the median |
| Huber | Squared when the error is small, absolute when it is large | Regression | A compromise between the two |
| 0–1 | $1$ if the predicted class is wrong, else $0$ | Classification (evaluation) | What accuracy counts, but not differentiable |
| Cross-entropy (log loss) | $-\left[y \log \hat{p} + (1-y)\log(1-\hat{p})\right]$ | Classification | Rewards confident correct probabilities; the standard for neural networks |
| Hinge | $\max(0,\ 1 - y\,\hat{y})$ with $y \in \{-1, 1\}$ | Classification (SVMs) | Ignores examples already classified with enough margin |

> [!tip] Surrogate losses
> The 0–1 loss is what accuracy measures, but it is flat almost everywhere, so gradients tell the
> optimizer nothing. Cross-entropy and hinge are smooth or convex stand-ins that are minimized
> instead, and lowering them tends to lower the 0–1 loss too.

## Choosing a Cost

- **Match the noise.** If errors are roughly Gaussian, minimizing squared error is maximum
  likelihood. If they are heavy-tailed, absolute or Huber loss is safer.
- **Match the decision.** When false negatives cost more than false positives, weight the classes
  or the examples accordingly.
- **Add regularization.** An L2 penalty $\lambda \lVert \theta \rVert^2$ (ridge) or L1 penalty
  $\lambda \lVert \theta \rVert_1$ (lasso) discourages large or unnecessary parameters and reduces
  overfitting.
- **Keep evaluation separate.** The training cost and the metric reported to stakeholders may
  differ, for example cross-entropy for training and F1 for reporting.

## Related Concepts

- [[concepts/machine_learning/least_squares|Least Squares]] — the squared-error cost worked out in full for linear regression
- [[concepts/machine_learning/gradient_descent|Gradient Descent]] — the general method for minimizing a differentiable cost
- [[concepts/machine_learning/supervised_learning|Supervised Learning]] — regression and classification problems, which call for different costs
- [[concepts/machine_learning/xgboost|XGBoost]] — accepts any cost with a first and second derivative as its objective
- [[concepts/ai_engineering/alignment/ai_alignment|AI Alignment]] — the gap between a stated objective and the real goal, at the scale of advanced systems

## References

- Ng, A. *CS229 Lecture Notes: Supervised Learning.* Stanford University.
- Bishop (2006). *Pattern Recognition and Machine Learning.* Springer.
