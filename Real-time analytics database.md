# What is real-time analytics?
Real-time analytics is the process of capturing real-time data, transforming it, and exposing the transformed result set to the end user in a matter of seconds or less.
There are five core facets to real-time analytics, and a real-time analytics database must support all of them:
1. **High Data Freshness**. Streaming data must be written and available for querying in seconds or less (without impacting read performance).
2. **Low Query Latency**. Queries must return results in ~<100 milliseconds, aka "web time."
3. **High Query Complexity**. We're talking about analytics, not transactions. That means filters, aggregates, and joins.
4. **High Query Concurrency**. Real-time analytics databases often underpin user-facing apps. They must support thousands of concurrent, user-initiated queries without lagging.
5. **Long Data Retention**. Real-time analytics [diverges from stream processing](https://www.tinybird.co/blog-posts/ksqldb-alternative) or "streaming analytics" as it must perform complex queries over unbounded time windows. Real-time analytics systems must retain perhaps years' worth of data, with raw tables containing trillions of rows or more.
# What is a real-time database?
A real-time database is designed to meet all five facets of real-time analytics at scale. While traditional databases can be adapted for real-time use cases, they often require complex configurations like sharding and extensive performance tuning. Purpose-built databases are generally recommended for achieving true real-time analytics capabilities.
# Real-time Databases vs. Analytics Databases

It's important to distinguish between real-time databases and general analytics databases. Not all analytics databases are equipped to handle the stringent requirements of real-time applications. For example, data warehouses might struggle with low query latency and high data freshness, while in-memory databases may face limitations in long-term data storage and complex analytical processing.
# Selection Criteria for a Real-time Analytics Database

When selecting a real-time analytics database, consider the following criteria:
- **Ingestion Throughput:** The database should be able to handle a high volume of incoming data, potentially millions of events per second. Databases employing Log-Structured Merge Tree (LSMT) structures are particularly efficient for write-heavy workloads.
- **Read Patterns:** The database should efficiently process filtered aggregations, which are common in analytical queries. Columnar databases excel in this area by minimizing the amount of data that needs to be scanned.
- **Query Performance:** Complex queries should be answered in milliseconds (50-100ms). Columnar databases are advantageous here, and minimizing query distribution across nodes can further reduce latency.
- **Concurrency:** The system must support a high degree of concurrency, handling thousands of simultaneous requests. This is especially important for applications with user-facing analytics, where queries are generated on-demand.
- **Scalability:** The database should scale horizontally and/or vertically to maintain performance as data volumes and query loads increase.
- **Ease of Use and Interoperability:** While specialized databases offer performance benefits, they should also be relatively easy to deploy and integrate with existing systems. Support for SQL is often a significant advantage.
# Best Databases for Real-time Analytics

Several databases are well-suited for real-time analytics:
- **ClickHouse:** A popular open-source, column-oriented, distributed OLAP database known for its performance and scalability.
- **Apache Druid:** Designed for real-time analytics on event data, Druid excels at handling high-velocity data streams.
- **Apache Pinot:** Another open-source, distributed OLAP database, Pinot is particularly well-suited for user-facing analytics.

All three are excellent choices, and the best option often depends on the specific use case, the team's familiarity with the technology, and the required features. Deployment can be complex, so managed versions are often preferred for ease of use.

