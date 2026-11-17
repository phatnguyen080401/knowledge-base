# Hot Questions

Routes from answered questions to the note sections that answered them, newest first: a router, never a source (the `wiki-query` skill).

- **Which read anomalies snapshot isolation allows vs. serializable; why write skew survives** → Transaction Isolation Levels: [[concepts/databases/isolation_levels#Write skew|Write skew]], [[concepts/databases/isolation_levels#The Standard Levels|The Standard Levels]], [[concepts/databases/isolation_levels#Repeatable Read and Snapshot Isolation|Repeatable Read and Snapshot Isolation]], [[concepts/databases/isolation_levels#Serializable|Serializable]] — No classic read anomaly; write skew (incl. phantom-driven) survives because first-committer-wins catches only same-row writes; 2PL predicate locks or SSI close it. · 2026-10-26 17:29:15
