# File detection modes
## Directory listing mode
**Mechanism:** In this mode, Auto Loader identifies new files by periodically listing the contents of the input directory on the cloud storage (e.g., AWS S3, Azure Blob Storage, Google Cloud Storage). It scans the specified path and compares the current list of files against the metadata of files it has already processed, which is stored in a scalable key-value store (RocksDB) within the stream's checkpoint location.

**Simplicity:** It's the default and easiest mode to set up, requiring minimal configuration beyond granting Auto Loader access to your data on cloud storage. No additional cloud services or permissions are needed for eventing.

**Scalability for Smaller Datasets:** While it can handle a large number of files, its performance can degrade as the number of files and directories grows significantly, because it relies on API calls to list directory contents. The cost of discovery scales with the number of directories scanned.

**Optimizations:** Databricks has implemented optimizations for directory listing, especially for files arriving with lexical ordering (e.g., `YYYY/MM/DD/HH/fileName`). In such cases, Auto Loader can leverage this ordering to reduce the number of API calls by listing from recently ingested files rather than rescanning the entire directory. It also performs asynchronous backfills to ensure eventual completeness.

**Use Cases:**
- Small to medium-sized directories.
- Scenarios with infrequent file arrivals or batch processing.
- Quickly getting started with Auto Loader without complex cloud service configurations.
- When file notification services are not available or feasible for your specific cloud storage setup.

**Configuration:**
- This is the default mode, so you don't explicitly set an option to enable it.
- You can control backfill intervals (`cloudFiles.backfillInterval`) to ensure all files are eventually processed, even if some were missed during incremental listings.
## File notification mode
**Mechanism:** This mode leverages native cloud event notification services (e.g., AWS S3 Events, Azure Event Grid/Queue Storage, Google Cloud Pub/Sub) to get real-time notifications when new files arrive in the cloud storage. Auto Loader can either automatically set up these notification and queue services for you (requiring elevated cloud permissions) or you can configure them manually.

**Performance and Scalability:** File notification mode is generally more performant and scalable, especially for large input directories or high volumes of continuously arriving files. Instead of polling directories, it reacts to events, making file discovery much more efficient and cost-effective. The cost of discovery scales with the number of files ingested, not the number of directories.

**Lower Latency:** Because it relies on real-time events, it can offer lower latency for data ingestion compared to periodic directory listings.

**Permissions:** Setting up file notification mode, particularly if Auto Loader is to automatically provision the cloud resources, requires additional cloud permissions to create and manage the necessary notification and queuing services.

**Unity Catalog Integration (Recommended):** With Unity Catalog, Databricks recommends enabling file events on external locations. This allows Auto Loader to use a single Databricks-managed file notification queue for all streams processing files from that external location, simplifying management and permissions.

**Use Cases:**
- Large datasets with a high volume of continuously arriving files.
- Real-time or near real-time data ingestion pipelines.
- When cost optimization for file discovery is a priority for high-volume scenarios.
- When you have the necessary cloud permissions and are comfortable with the setup of cloud eventing services.

**Configuration:**
- To enable this mode, you typically set the option `cloudFiles.useNotifications` to `true`.
- If using Unity Catalog, the recommended approach is to enable file events for the external location and set `cloudFiles.useManagedFileEvents` to `true`.
- You might need to provide additional cloud-specific options and permissions to allow Auto Loader to create and manage the notification resources.

**Limitations on Auto Loader with file events**
The file events service optimizes file discovery by caching the most recently created files. If Auto Loader runs infrequently, this cache can expire, and Auto Loader falls back to directory listing to discover files and update the cache. To avoid this scenario, invoke Auto Loader at least once every seven days.
### Comparison Summary:

| Feature/Mode         | Directory Listing Mode                                                                                                                                      | File Notification Mode                                                                          |
| :------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------- |
| **Detection Mech.**  | Periodically lists directory contents via API calls.                                                                                                        | Leverages cloud-native event/queue services.                                                    |
| **Setup Complexity** | Simple; default mode, minimal permissions beyond data access.                                                                                               | More complex; requires additional cloud permissions for event/queue service setup.              |
| **Performance**      | Good for small to medium directories/infrequent updates. Can slow down with very large or deeply nested directories. Optimized for lexically ordered files. | Highly scalable and faster for large datasets and high volume. Event-driven, so more efficient. |
| **Cost**             | Discovery cost scales with the number of directories scanned.                                                                                               | Discovery cost scales with the number of files ingested (generally cheaper for high volume).    |
| **Latency**          | Higher (depends on listing interval).                                                                                                                       | Lower (near real-time as events are triggered).                                                 |
| **Permissions**      | Basic read access to cloud storage.                                                                                                                         | Elevated permissions to create and manage cloud event/queue resources.                          |
| **Databricks Rec.**  | Generally recommended to migrate to File Notification mode with file events for most workloads.                                                             | **Recommended** for most production workloads, especially with Unity Catalog and file events.   |
| **Fault Tolerance**  | Both modes offer exactly-once processing through checkpointing.                                                                                             | Both modes offer exactly-once processing through checkpointing.                                 |
