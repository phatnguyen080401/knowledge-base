# Hot Questions

Routes from answered questions to the note sections that answered them, newest first: a router, never a source (the `wiki-query` skill).

- **Why write skew survives snapshot isolation but not serializable** → [[concepts/databases/isolation_levels#Write skew|Transaction Isolation Levels › Write skew]], [[concepts/databases/isolation_levels#The Standard Levels|Transaction Isolation Levels › The Standard Levels]], [[concepts/databases/isolation_levels#Repeatable Read and Snapshot Isolation|Transaction Isolation Levels › Repeatable Read and Snapshot Isolation]], [[concepts/databases/isolation_levels#Serializable|Transaction Isolation Levels › Serializable]] — No classic read anomaly; write skew (incl. phantom-driven) survives because first-committer-wins catches only same-row writes; 2PL predicate locks or SSI close it. · 2026-10-26 17:29:15
