---
title: Data Quality
tags: [data-governance, data-quality]
created: 2026-09-22 00:00:00
updated: 2026-09-24 10:10:13
---
# Data Quality

Data quality is a measure of the condition of data based on factors such as accuracy, completeness, consistency, reliability and that the data is up to date. It is a critical component of data management and governance, ensuring that data is fit for its intended use in operations, decision-making, and planning.

## Why Does It Matter?

Data quality matters because poor quality data can have a significant negative impact on an organization. It can lead to:

*   **Poor Decision-Making**: If data is inaccurate or incomplete, it can lead to flawed decisions that can have serious consequences.
*   **Inefficiency**: Poor data quality can lead to wasted time and resources as employees struggle to work with unreliable data.
*   **Damaged Reputation**: Data quality issues can damage a company's reputation, leading to loss of customers and revenue.
*   **Compliance Risks**: Poor data quality can lead to non-compliance with regulations, resulting in fines and legal action.

## Core Dimensions of Data Quality

The following are the six core dimensions of data quality:

1.  **Accuracy**: The degree to which data correctly reflects the 'real world' or a verifiable source.
    *   *Relevant checks include*:
        *   **Fact verification**: Cross-reference data with reliable external sources (e.g., public records, authoritative databases).
        *   **Address validation**: Use services like USPS to confirm mailing addresses are real and deliverable.
        *   **Manual review**: Have subject matter experts periodically review data samples for correctness.
        *   **Data profiling**: Analyze data to find values that are out of place or don't fit the expected patterns.
2.  **Completeness**: The proportion of data that is present and not missing.
    *   *Relevant checks include*:
        *   **Required field analysis**: Identify and count null or empty values in critical columns.
        *   **Record count validation**: Compare the number of records in a source system to a target system after an ETL process.
        *   **Data profiling**: Analyze the percentage of missing values for each attribute in a dataset.
        *   **Business rule validation**: Ensure that if a certain field has a value, a related field is also populated (e.g., if `order_status` is 'shipped', then `shipping_date` cannot be null).
3.  **Consistency**: The uniformity of data as it moves across networks and applications. Data should not be contradictory in different systems.
    *   *Relevant checks include*:
        *   **Format standardization**: Ensure consistent data formatting across datasets (e.g., date formats, numeric precision).
        *   **Field-level consistency**: Compare repeated values across datasets for uniformity (e.g., customer ID).
        *   **Version control validation**: Verify that the most recent data versions are used across systems.
        *   **Cross-system checks**: Ensure consistency between integrated datasets or systems.
        *   **Schema consistency**: Confirm that database schemas adhere to a unified standard.
4.  **Timeliness**: The degree to which data is up-to-date and available when needed.
    *   *Relevant checks include*:
        *   **Data latency monitoring**: Measure the time between an event happening and the data being available in the system.
        *   **Report generation time**: Track how long it takes for reports and dashboards to be updated with the latest data.
        *   **Service Level Agreement (SLA) tracking**: Monitor if data is being delivered within the timeframes defined in SLAs.
        *   **Data refresh frequency validation**: Check if data is being updated as frequently as required (e.g., daily, hourly, real-time).
5.  **Validity**: The degree to which data conforms to the syntax (format, type, range) of its definition.
    *   *Relevant checks include*:
        *   **Data type validation**: Check that data in a column matches the expected data type (e.g., a `date` column doesn't contain text).
        *   **Range checks**: Ensure that values fall within an expected range (e.g., `age` is between 0 and 120).
        *   **Format validation**: Check that data conforms to a standard format (e.g., phone numbers are `(###) ###-####`).
        *   **Referential integrity checks**: Ensure that foreign keys in one table correspond to primary keys in another.
6.  **Uniqueness**: The degree to which data records are unique and not duplicated.
    *   *Relevant checks include*:
        *   **Duplicate record detection**: Scan for and flag records that are identical or near-identical.
        *   **Primary key validation**: Ensure that the primary key for each record is unique.
        *   **Data deduplication**: Use tools to merge or remove duplicate records.
        *   **Cross-dataset duplicate checks**: Look for duplicate records across different datasets that should be unique.

## Where Do Data Quality Problems Come From?

Data quality issues can arise from a variety of sources throughout the data lifecycle. Understanding these sources is the first step toward preventing and correcting errors.

*   **Data Entry Errors**: Manual data entry is a leading cause of inaccuracies. Typos, misinterpretations, and formatting inconsistencies can all be introduced when humans key in data.
*   **Data Migration**: When moving data from one system to another (e.g., during a system upgrade), data can be lost, corrupted, or mapped incorrectly between old and new schemas.
*   **System Errors**: Software bugs, hardware malfunctions, or design flaws in applications can corrupt data or cause it to be captured incorrectly.
*   **Data Decay**: Information can become outdated over time. Customers move, products are discontinued, and contact information changes, leading to a decline in accuracy.
*   **Lack of Data Governance**: Without clear standards, policies, and ownership for data assets, inconsistencies and errors are more likely to occur and go uncorrected.
*   **Multiple Data Sources**: Integrating data from various systems often reveals inconsistencies in definitions, formats, and values, leading to duplicate or contradictory records.

## Data Quality Lifecycle

Managing data quality is not a one-time project; it's a continuous, cyclical process. The Data Quality Lifecycle provides a framework for systematically improving and maintaining the health of data assets.

1.  **Define**: Establish what "high-quality" data means in the context of your business. This includes defining data quality rules, standards, and metrics that align with organizational goals and regulatory requirements.
2.  **Assess**: Measure the current state of your data against the defined metrics. This stage involves data profiling, which analyzes datasets to identify anomalies, inconsistencies, and redundancies, providing a clear picture of where quality issues exist.
3.  **Improve**: Take action to correct the issues identified during the assessment. This includes data cleansing (correcting or removing errors), data enrichment (adding missing information), and data standardization (converting data to a consistent format).
4.  **Monitor**: Continuously track data quality to ensure it meets the defined standards over time. This involves implementing automated checks, dashboards, and alerting systems to quickly detect and report any degradation in data quality.
5.  **Govern**: Implement and enforce data governance policies to create a long-term framework for quality. This includes establishing data ownership, defining roles and responsibilities, and creating processes that prevent poor-quality data from entering systems in the first place.

## Data Quality Tools

Several tools can help automate and streamline the data quality lifecycle. Here are a few popular options:

### dbt (Data Build Tool)

*   **Description**: [[concepts/dbt|dbt]] is a transformation workflow tool that lets teams quickly and collaboratively deploy analytics code following software engineering best practices like modularity, portability, CI/CD, and documentation. It allows you to build and test data models in SQL.
*   **Pros**:
    *   Integrated testing framework allows you to define and run data quality tests directly within your transformation pipeline.
    *   Strong community and extensive documentation.
    *   Enables SQL-based transformations and testing, making it accessible to analysts.
    *   Version control and CI/CD integration.
*   **Cons**:
    *   Primarily focused on transformations and testing within the data warehouse; not a standalone data quality monitoring tool.
    *   Testing capabilities are powerful but may not be as comprehensive as specialized data quality tools.
*   **Website**: [https://www.getdbt.com/](https://www.getdbt.com/)

### Soda

*   **Description**: Soda is a data reliability and quality management platform that allows teams to detect, resolve, and prevent data issues. It offers a declarative language (SodaCL) to define data quality checks.
*   **Pros**:
    *   Comprehensive data monitoring and observability features.
    *   Easy to set up and get started with.
    *   Integrates with a wide range of data sources.
    *   Provides a centralized platform for data quality management.
*   **Cons**:
    *   Advanced features are part of a paid commercial offering.
    *   Can have a steeper learning curve for those not familiar with YAML-based configurations.
*   **Website**: [https://www.soda.io/](https://www.soda.io/)

### Great Expectations

*   **Description**: Great Expectations is an open-source Python library for data validation, documentation, and profiling. It helps data teams eliminate pipeline debt, through data testing, documentation, and profiling.
*   **Pros**:
    *   Extensive library of pre-built "expectations" (tests).
    *   Automatically generates data documentation and quality reports ("Data Docs").
    *   Highly customizable and extensible.
    *   Strong focus on data testing and validation.
*   **Cons**:
    *   Can be complex to set up and configure, especially for larger projects.
    *   Primarily Python-based, which may be a barrier for non-Python users.
    *   Managing "Expectation Suites" can become cumbersome at scale.
*   **Website**: [https://greatexpectations.io/](https://greatexpectations.io/)

## Pros and Cons of Applying Data Quality

### Pros

*   **Improved Decision-Making**: High-quality data leads to more accurate and reliable business intelligence, which in turn leads to better decision-making.
*   **Increased Efficiency**: Clean data reduces the time spent on identifying and fixing data errors, leading to more efficient operations.
*   **Enhanced Customer Satisfaction**: Accurate data ensures that customers are billed correctly, receive the right products, and have a positive experience with the company.
*   **Better Regulatory Compliance**: High-quality data helps organizations meet regulatory requirements and avoid fines.

### Cons

*   **Cost**: Implementing data quality processes and tools can be expensive.
*   **Complexity**: Data quality management can be complex, requiring specialized skills and knowledge.
*   **Time-Consuming**: Improving data quality can be a time-consuming process, especially for large and complex datasets.
