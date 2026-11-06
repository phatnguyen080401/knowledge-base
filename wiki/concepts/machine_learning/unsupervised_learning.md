---
title: Unsupervised Learning
tags: [machine-learning, representation-learning, learning-paradigms]
created: 2026-11-06 15:49:01
updated: 2026-11-06 15:49:01
---

# Unsupervised Learning

Unsupervised learning finds structure in data that has no labels: groups of similar examples, a
few directions that explain most of the variation, or a model of how the data is distributed. It
differs from [[concepts/machine_learning/supervised_learning|Supervised Learning]] in having
inputs $x^{(i)}$ but no target $y^{(i)}$ to predict.

## Why It Matters

- **Unlabelled data is plentiful.** Logs, text, images, and sensor streams arrive without labels,
  and labelling them is expensive.
- **It explores data before anyone knows what to ask.** Clustering customers or reducing
  dimensions to plot the data often comes before any supervised model.
- **It produces features for other models.** Learned representations, such as
  [[concepts/machine_learning/word2vec|Word2Vec]] vectors, feed supervised models downstream.

## Main Tasks

| Task | Goal | Classic methods |
| --- | --- | --- |
| Clustering | Partition examples into groups of similar ones | k-means, hierarchical clustering, DBSCAN, Gaussian mixture models |
| Dimensionality reduction | Represent each example with fewer numbers while keeping most of the information | PCA, ICA, t-SNE and UMAP (for visualization), autoencoders |
| Density estimation | Model the probability distribution $p(x)$ the data came from | Gaussian mixtures fit by expectation-maximization (EM), kernel density estimation |
| Anomaly detection | Flag examples unlikely under the learned distribution | Isolation forest, one-class SVM, density thresholds |
| Association rules | Find items that tend to occur together | Apriori, FP-growth |

### Example: k-Means

k-means picks $k$ cluster centres and alternates two steps until assignments stop changing:

1. Assign each example to its nearest centre.
2. Move each centre to the mean of the examples assigned to it.

Each step lowers the total squared distance from examples to their centres, so the algorithm
converges, though possibly to a local minimum. Running it from several random starts is standard.

## How Success Is Judged

With no labels there is no single correct answer, which makes evaluation the hard part.

- **Internal measures** score the result itself: within-cluster distance, silhouette score, or the
  share of variance a PCA keeps.
- **Likelihood on held-out data** scores density models.
- **Downstream use** is often the real test: does the clustering or representation improve the
  supervised model or business decision that uses it?

## Related Paradigms

| Paradigm | Supervision | Example |
| --- | --- | --- |
| Supervised | A label for every example | Price prediction, spam filtering |
| Unsupervised | None | Customer segmentation |
| Self-supervised | Labels derived from the data itself, e.g. a masked or next word | Word2Vec, language-model pretraining |
| Semi-supervised | A few labels plus many unlabelled examples | Pseudo-labelling |
| Reinforcement | A reward signal from acting in an environment | Game playing, robot control |

Self-supervised learning is often grouped with unsupervised learning because no human labels are
needed. Technically it trains like supervised learning, on targets it builds itself.

## Related Concepts

- [[concepts/machine_learning/supervised_learning|Supervised Learning]] — the labelled counterpart; unsupervised features and clusters are often its inputs
- [[concepts/machine_learning/word2vec|Word2Vec]] — a self-supervised method that learns word vectors from raw text with no labels
- [[concepts/ai_engineering/embeddings|Embeddings]] — the dense representations that unsupervised and self-supervised training produce

## References

- Ng, A. *CS229 Lecture Notes: Unsupervised Learning (k-means, EM, PCA).* Stanford University.
- Hastie, Tibshirani, and Friedman (2009). *The Elements of Statistical Learning*, 2nd ed., chapter 14. Springer.
