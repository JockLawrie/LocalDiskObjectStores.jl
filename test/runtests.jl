using Test
using LocalDiskStores

################################################################################
# Permission == :readonly

store = LocalDiskStore(:readonly, "/var")

@test typeof(listcontents(store)) == Vector{String}  # Lists the contents of the root bucket (non-recursively)
@test listcontents(store, "zzz") == nothing          # True because the bucket does not exist

@test isbucket(store, "local") == true               # True, bucket exists.

@test hasbucket(store, "local")  == false            # False, bucket exists but was not created by the store.
                                                     # Bucket can be read but not updated or deleted unless permission is :unlimited.

@test isobject(store, "local") == false              # False, "local" is a bucket not an object.

@test createbucket!(store, "mybucket") == false      # Failed (returns false), cannot create a bucket because permission is :readonly

store["myobject"] = "My first object"  # No-op, cannot create an object because permission is :readonly
@test hasobject(store, "myobject") == false


################################################################################
# Permission == :limited

store = LocalDiskStore(:limited, "/tmp/rootbucket")  # /tmp/rootbucket is created if it doesn't already exist

@test isempty(listcontents(store))          # Lists the contents of the root bucket (non-recursively)

# Deleting a bucket that was not created by the store is not permitted if write permission is :limited.
mkdir("/tmp/rootbucket/xxx")
@test isbucket(store, "xxx") == true        # True, bucket exists
@test hasbucket(store, "xxx") == false      # False, bucket was not created by the store
@test length(listcontents(store)) == 1      # Bucket xxx exists
@test deletebucket!(store, "xxx") == false  # Failed (returns false) because the bucket was not created by the store
@test length(listcontents(store)) == 1      # Bucket xxx still exists
rm("/tmp/rootbucket/xxx")
@test isempty(listcontents(store))          # Bucket xxx no longer exists

# Similarly, objects not created by the store cannot be updated or deleted
write("/tmp/rootbucket/myobject", "My first object")
@test isobject(store, "myobject")  == true   # True, object exists
@test hasobject(store, "myobject") == false  # False, object was not created by the store
@test String(store["myobject"]) == "My first object"  # Reading is permitted
store["myobject"] = "Some new value"  # No-op, cannot update object that was not created by the store
@test String(store["myobject"]) == "My first object"  # Value hasn't changed
@test delete!(store, "myobject") == false    # Failed (returns false), cannot delete an object that was not created by the store
rm("/tmp/rootbucket/myobject")        # Cleaning up...leave it how we found it

# Buckets and objects created by the store can be updated and deleted
@test createbucket!(store, "xxx") == true   # Success (returns true)
@test listcontents(store) == ["xxx"]        # Lists the contents of the root bucket
@test createbucket!(store, "xxx") == false  # Failed (returns false) because the bucket already exists
store["xxx/myobject"] = "My first object"   # Success (returns true)
@test listcontents(store, "xxx") == ["myobject"]     # Lists the contents of the xxx bucket
@test listcontents(store, "xxx/myobject") == false   # Failed (returns false) because we can only list the contents of buckets, not objects
@test String(store["xxx/myobject"]) == "My first object"  # Get myobject's value
@test store["xxx/my_nonexistent_object"] == nothing  # True because the object does not exist

@test createbucket!(store, "xxx/yyy") == true   # Success (returns true), bucket yyy created inside bucket xxx
@test listcontents(store, "xxx") == ["myobject", "yyy"]  # Bucket xxx contains the object myobject and the bucket yyy
@test isempty(listcontents(store, "xxx/yyy"))   # Empty vector...bucket exists and is empty

@test deletebucket!(store, "xxx") == false     # Failed (returns false) because the bucket is not empty
@test delete!(store, "xxx/myobject") == true   # Success (returns true)
@test deletebucket!(store, "xxx/yyy") == true  # Success (returns true)
@test deletebucket!(store, "xxx") == true      # Success (returns true) because the bucket was empty (and the bucket was created by the store)
@test isempty(listcontents(store))
rm("/tmp/rootbucket")


################################################################################
# Permission == :unlimited
#=
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
=#
