![[Network protocol.png]]
# Short polling
# Long polling
# Websocket
# SSE (Server-Sent Events)
# RPC (Remote Procedure Call)

gRPC works from start to end:

Step 1: A REST call is made from the client. The request body is usually in JSON format.

Steps 2 - 4: The order service (acting as a gRPC client) receives the REST call, transforms it into a suitable format, and then initiates an RPC call to the payment service. gPRC encodes the client stub into binary format and sends it to the low-level transport layer.

Step 5: gRPC sends the packets over the network via HTTP2. Binary encoding and network optimizations make gRPC reportedly up to five times faster than JSON.

Steps 6 - 8: The payment service (acting as a gRPC server) receives the packets, decodes them, and invokes the server application.

Steps 9 - 11: The result from the server application gets encoded and sent to the transport layer.

Steps 12 - 14: The order service receives the packets, decodes them, and sends the result to the client application.

![[gRPC Flow.png]]

