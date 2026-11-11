---
title: XGBoost (Extreme Gradient Boosting)
tags: [machine-learning, model-training, xgboost]
created: 2026-11-06 15:42:10
updated: 2026-11-06 15:42:10
---

# XGBoost (Extreme Gradient Boosting)

XGBoost is a gradient-boosted decision tree library and the regularized boosting algorithm behind
it. It builds an ensemble of shallow trees one at a time, and each new tree corrects the errors of
the trees before it. It applies the idea of [[concepts/machine_learning/gradient_descent|Gradient Descent]]
to whole functions instead of to a parameter vector. Tianqi Chen started it in 2014, and Chen and
Guestrin described it in their 2016 KDD paper.

## Why It Matters

- **It is a strong default for tabular data.** On structured rows and columns, gradient-boosted
  trees often match or beat deep networks with far less tuning (Grinsztajn et al., 2022). XGBoost
  won many Kaggle competitions after 2015.
- **It needs little preprocessing.** Trees split on thresholds, so features need no scaling, and
  XGBoost learns where missing values should go.
- **It regularizes the trees themselves.** Penalties on the number of leaves and on leaf weights
  are part of the objective, so the algorithm controls overfitting directly.
- **It is built for speed.** It parallelizes split finding, uses caches efficiently, can train on
  data larger than memory, and runs on multiple machines or on GPUs.

## Gradient Boosting in Brief

A boosted model predicts with the sum of $K$ trees:

$$
\hat{y}_i = \sum_{k=1}^{K} f_k(x_i)
$$

Training is additive. At round $t$, the trees already built stay fixed and one new tree $f_t$ is
added to reduce the loss. Friedman's (2001) gradient boosting fits each new tree to the negative
gradient of the loss with respect to the current predictions. For squared error that negative
gradient is just the residual $y_i - \hat{y}_i$. Each round is therefore a step of gradient descent
in function space, and the learning rate scales the step.

| | Bagging (random forest) | Boosting (XGBoost) |
| --- | --- | --- |
| Trees are built | Independently, in parallel | One after another, each fixing the last |
| Typical tree | Deep, low bias, high variance | Shallow, high bias, low variance |
| Combination | Average of the trees | Sum of the trees, scaled by the learning rate |
| What it mainly reduces | Variance | Bias |

## The Regularized Objective

At round $t$ XGBoost minimizes the loss plus a complexity penalty on the new tree:

$$
\mathcal{L}^{(t)} = \sum_{i=1}^{n} l\left(y_i,\ \hat{y}_i^{(t-1)} + f_t(x_i)\right) + \Omega(f_t),
\qquad
\Omega(f) = \gamma T + \tfrac{1}{2}\lambda \sum_{j=1}^{T} w_j^2
$$

Here $T$ is the number of leaves and $w_j$ is the score of leaf $j$. The library also offers an L1
term $\alpha \sum_j |w_j|$.

### Second-Order Approximation

XGBoost expands the loss to second order around the current predictions. For each example it
computes the gradient $g_i = \partial_{\hat{y}} l$ and the Hessian $h_i = \partial^2_{\hat{y}} l$.
For a leaf $j$, let $G_j$ and $H_j$ be the sums of $g_i$ and $h_i$ over the examples that fall into
it. The best weight for that leaf and the resulting objective then have closed forms:

$$
w_j^{*} = -\frac{G_j}{H_j + \lambda},
\qquad
\mathcal{L}^{*} = -\frac{1}{2}\sum_{j=1}^{T} \frac{G_j^2}{H_j + \lambda} + \gamma T
$$

> [!important] One gradient pass per round
> Any loss with a first and second derivative works the same way. The tree builder only ever sees
> the per-example $g_i$ and $h_i$. Using the Hessian makes each round a Newton step rather than a
> plain gradient step, which is why this is sometimes called Newton boosting.

### Split Gain

Splitting a leaf into left and right children changes the objective by

$$
\text{Gain} = \frac{1}{2}\left[\frac{G_L^2}{H_L + \lambda} + \frac{G_R^2}{H_R + \lambda} - \frac{(G_L + G_R)^2}{H_L + H_R + \lambda}\right] - \gamma
$$

A split is kept only when its gain is positive, so $\gamma$ acts as a minimum gain required to grow
the tree. The sum of $h_i$ in a child must also reach `min_child_weight`, which stops leaves built
from too little evidence.

## Making Tree Building Fast

| Technique | What it does |
| --- | --- |
| Exact greedy | Sorts every feature and tries every threshold. Exact but slow on large data |
| Weighted quantile sketch | Proposes candidate thresholds at quantiles weighted by $h_i$, so each bucket carries similar weight |
| Histogram (`tree_method="hist"`) | Buckets each feature into at most `max_bin` bins once, then sums gradients per bin. The default since XGBoost 2.0 |
| Sparsity-aware splits | Learns a default direction per split for missing or zero values, so sparse data costs time proportional to its non-zero entries |
| Column blocks | Stores pre-sorted feature columns in compressed blocks that are reused across rounds and split across threads |
| Out-of-core and distributed | Streams blocks from disk; trains on Spark, Dask, and Ray clusters |
| GPU (`device="cuda"`) | Builds histograms on the GPU |

## Main Hyperparameters

| Parameter | Default | Effect |
| --- | --- | --- |
| `n_estimators` | 100 | Number of boosting rounds (trees) |
| `learning_rate` (`eta`) | 0.3 | Shrinks each tree's contribution; lower values need more rounds but usually generalize better |
| `max_depth` | 6 | Maximum tree depth; deeper trees capture more feature interactions and overfit sooner |
| `min_child_weight` | 1 | Minimum Hessian sum in a leaf |
| `gamma` (`min_split_loss`) | 0 | Minimum gain needed to make a split |
| `lambda` (`reg_lambda`) | 1 | L2 penalty on leaf weights |
| `alpha` (`reg_alpha`) | 0 | L1 penalty on leaf weights |
| `subsample` | 1 | Fraction of rows sampled for each tree |
| `colsample_bytree` | 1 | Fraction of features sampled for each tree |

> [!tip] Tune with early stopping
> Fix a small learning rate (0.01 to 0.1), set `n_estimators` high, and let
> `early_stopping_rounds` stop training when the validation metric stops improving. Then tune
> `max_depth`, `min_child_weight`, and the subsampling rates.

Common objectives include `reg:squarederror`, `binary:logistic`, `multi:softprob`,
`count:poisson`, `survival:cox`, and the learning-to-rank objectives such as `rank:ndcg`.

## Using It in Practice

```python
import xgboost as xgb
from sklearn.datasets import load_breast_cancer
from sklearn.model_selection import train_test_split

X, y = load_breast_cancer(return_X_y=True)
X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=0)

model = xgb.XGBClassifier(
    n_estimators=2000,
    learning_rate=0.05,
    max_depth=4,
    subsample=0.8,
    colsample_bytree=0.8,
    tree_method="hist",
    early_stopping_rounds=50,
    eval_metric="logloss",
)
model.fit(X_train, y_train, eval_set=[(X_val, y_val)], verbose=False)
print(model.best_iteration, model.score(X_val, y_val))
```

- **Categorical features.** Pass a pandas `category` column with `enable_categorical=True` to split
  on categories directly instead of one-hot encoding them.
- **Interpretation.** Built-in importances (`weight`, `gain`, `cover`) can disagree with each other
  and favour features with many possible split points. SHAP values, computed exactly for trees
  with `pred_contribs=True`, are more reliable.
- **Constraints.** Monotonic and interaction constraints force the model to respect known
  relationships, such as risk never falling as debt rises.

## Limitations

- **No extrapolation.** A tree predicts a constant per leaf, so predictions never leave the range
  of values seen in training. A trend that continues past the training data is not followed.
- **Not for raw perception data.** Images, audio, and free text need learned representations;
  neural networks such as an [[concepts/machine_learning/long_short_term_memory|LSTM]] handle those
  better.
- **Many interacting hyperparameters.** Depth, learning rate, and the number of rounds trade off
  against each other, and a large model overfits small datasets.
- **Sequential rounds.** Boosting rounds cannot run in parallel, only the work inside a round.

## Alternatives

| Library | Distinguishing idea |
| --- | --- |
| LightGBM (Microsoft, 2017) | Grows trees leaf-wise rather than level by level; gradient-based one-side sampling and exclusive feature bundling for speed |
| CatBoost (Yandex, 2017) | Ordered boosting and target statistics for categorical features, reducing target leakage; symmetric trees |
| scikit-learn `HistGradientBoosting` | A histogram-based booster inspired by LightGBM, built into scikit-learn |
| Random forest | Bagging instead of boosting; fewer hyperparameters, usually somewhat less accurate |

## Related Concepts

- [[concepts/machine_learning/gradient_descent|Gradient Descent]] — boosting is gradient descent in function space, and the learning rate plays the same role as the step size
- [[concepts/machine_learning/long_short_term_memory|Long Short-Term Memory (LSTM)]] — the neural choice for sequence data, where XGBoost needs hand-built lag features instead

## References

- Friedman (2001). *Greedy Function Approximation: A Gradient Boosting Machine.* Annals of Statistics.
- Chen and Guestrin (2016). *XGBoost: A Scalable Tree Boosting System.* KDD.
- Ke et al. (2017). *LightGBM: A Highly Efficient Gradient Boosting Decision Tree.* NeurIPS.
- Prokhorenkova et al. (2018). *CatBoost: Unbiased Boosting with Categorical Features.* NeurIPS.
- Grinsztajn, Oyallon, and Varoquaux (2022). *Why do tree-based models still outperform deep learning on tabular data?* NeurIPS Datasets and Benchmarks.
- [XGBoost documentation](https://xgboost.readthedocs.io)
