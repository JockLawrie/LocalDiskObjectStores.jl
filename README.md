# LocalDiskStores 

A `LocalDiskStore` is a bucket store that uses the local file system as the storage back end.

It is a concrete subtype of `AbstractStorageBackend`.


# Usage

An instance is created by simply calling the constructor `LocalDiskStore()`.
This is then passed to your `BucketStore` instance.

For example, `store = BucketStore("mystore", "/tmp/rootbucket", LocalDiskStore())`.

See the test cases for a thorough walk-through of creating and using a `BucketStore` with a `LocalDiskStore` as the storage backend.
