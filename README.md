# LocalDiskStores 

A `LocalDiskStore` is a bucket store that uses the local file system as the storage back end.

It is a concrete subtype of `AbstractBucketStore`.


# Usage

### Read-only permission

```julia
using LocalDiskStores

store = LocalDiskStore(:readonly, "/var")

listcontents(store)                    # Lists the contents of the root bucket (non-recursively)
listcontents(store, "zzz") == nothing  # True because the bucket does not exist

isbucket(store, "local")               # True, bucket exists.

hasbucket(store, "local")              # False, bucket exists but was not created by the store.
                                       # Bucket can be read but not updated or deleted unless permission is :unlimited.

isobject(store, "local")               # False, "local" is a bucket not an object.

createbucket!(store, "mybucket")       # Failed (returns false), cannot create a bucket because permission is :readonly

store["myobject"] = "My first object"  # Fails, cannot create an object because permission is :readonly
hasobject(store, "myobject")           # False.
```

### Limited write permission

```julia
using LocalDiskStores

store = LocalDiskStore(:limited, "/tmp/rootbucket")  # /tmp/rootbucket is created if it doesn't already exist

listcontents(store)           # Lists the contents of the root bucket (non-recursively)

# Deleting a bucket that was not created by the store is not permitted if write permission is :limited.
mkdir("/tmp/rootbucket/xxx")
isbucket(store, "xxx")        # True, bucket exists
hasbucket(store, "xxx")       # False, bucket was not created by the store
listcontents(store)           # Bucket xxx exists
deletebucket!(store, "xxx")   # Failed (returns false) because the bucket was not created by the store
listcontents(store)           # Bucket xxx still exists
rm("/tmp/rootbucket/xxx")
listcontents(store)           # Bucket xxx no longer exists

# Similarly, objects not created by the store cannot be updated or deleted
write("/tmp/rootbucket/myobject", "My first object")
isobject(store, "myobject")           # True, object exists
hasobject(store, "myobject")          # False, object was not created by the store
String(store["myobject"])             # Reading is permitted
store["myobject"] = "Some new value"  # Failed (returns false), cannot update object that was not created by the store
String(store["myobject"])             # Value hasn't changed
delete!(store, "myobject")            # Failed (returns false), cannot delete an object that was not created by the store
rm("/tmp/rootbucket/myobject")        # Cleaning up...leave it how we found it

# Buckets and objects created by the store can be updated and deleted
createbucket!(store, "xxx")                 # Success (returns true)
listcontents(store)                         # Lists the contents of the root bucket
createbucket!(store, "xxx")                 # Failed (returns false) because the bucket already exists
store["xxx/myobject"] = "My first object"   # Success (returns true)
listcontents(store, "xxx")                  # Lists the contents of the xxx bucket
listcontents(store, "xxx/myobject")         # Failed (returns false) because we can only list the contents of buckets, not objects
String(store["xxx/myobject"])               # Get myobject's value
String(store["xxx/my_nonexistent_object"])  # Failed (returns false) because the object does not exist

createbucket!(store, "xxx/yyy")  # Success (returns true), bucket yyy created inside bucket xxx
listcontents(store, "xxx")       # Bucket xxx contains the object myobject and the bucket yyy
listcontents(store, "yyy")       # Empty vector...bucket exists and is empty

deletebucket!(store, "xxx")      # Failed (returns false) because the bucket is not empty
delete!(store, "xxx/myobject")   # Success (returns true)
deletebucket!(store, "xxx/yyy")  # Success (returns true)
deletebucket!(store, "xxx")      # Success (returns true) because the bucket was empty (and the bucket was created by the store)
listcontents(store, "/var")
```

### Unlimited write permission

```julia
using LocalDiskStores

store = LocalDiskStore(:unlimited, "/tmp/rootbucket")  # /tmp/rootbucket is created if it doesn't already exist

# Deleting a bucket that was not created by the store is permitted if write permission is :unlimited
mkdir("/tmp/rootbucket/xxx")
isbucket(store, "xxx")        # True, bucket exists
hasbucket(store, "xxx")       # False, bucket was not created by the store
listcontents(store)           # Bucket xxx exists
deletebucket!(store, "xxx")   # Success (returns true)
listcontents(store)           # Bucket xxx no longer exists

# Similarly, objects not created by the store can be updated or deleted
write("/tmp/rootbucket/myobject", "My first object")
isobject(store, "myobject")           # True, object exists
hasobject(store, "myobject")          # False, object was not created by the store
String(store["myobject"])             # Reading is permitted
store["myobject"] = "Some new value"  # Success (returns true), objects that were not created by the store can be updated
String(store["myobject"])             # Value has changed to "Somoe new value"
delete!(store, "myobject")            # Success (returns true), objects that were not created by the store can be deleted
```
