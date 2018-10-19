module LocalDiskStores


export LocalDiskStore,
       listcontents, createbucket!, deletebucket!,  # Buckets
       getindex, setindex!, delete!,                # Objects
       islocal, isbucket, isobject,                 # Conveniences
       BucketStore, hasbucket, hasobject            # Re-exported from BucketStores

import Base.setindex!, Base.getindex, Base.delete!

using BucketStores


struct LocalDiskStore <: AbstractBucketStore
    @add_BucketStore_common_fields
end


################################################################################
# Buckets

"If fullpath is a bucket, return a list of the bucket's contents, else return nothing."
function listcontents(store::LocalDiskStore, fullpath::String)
    !isbucket(store, fullpath) && return nothing
    readdir(fullpath)
end


"""
Returns true if bucket is successfully created, false otherwise.

Create bucket if:
1. It doesn't already exist (as either a bucket or an object), and
2. The containing bucket exists.
"""
function createbucket!(store::LocalDiskStore, fullpath::String)
    isbucket(store, fullpath) && return false  # Bucket already exists
    cb, bktname = splitdir(fullpath)
    !isbucket(store, cb) && return false       # Containing bucket doesn't exist
    mkdir(fullpath)
    true
end


"""
Returns true if bucket is successfully deleted, false otherwise.

Delete bucket if:
1. fullpath is a bucket name (the bucket exists), and
2. The bucket is empty.
"""
function deletebucket!(store::LocalDiskStore, fullpath::String)
    contents = listcontents(store, fullpath)
    contents == nothing && return false  # fullpath is not a bucket
    !isempty(contents)  && return false  # Bucket is not empty
    rmdir(fullpath)
    true
end


################################################################################
# Objects

"Return object if fullpath refers to an object, else return nothing."
function getindex(store::LocalDiskStore, fullpath::String) 
    !isobject(store, fullpath) && return nothing
    read(fullpath)
end


"If fullpath is an object, set fullpath = v and return true, else return false."
function setindex!(store::LocalDiskStore, v, fullpath::String)
    write(fullpath, v)
    true
end


"If object exists, delete it and return true, else return false."
function delete!(store::LocalDiskStore, fullpath::String)
    !isobject(store, fullpath) && return false
    rm(fullpath)
    true
end


################################################################################
# Conveniences

islocal(store::LocalDiskStore) = true

isbucket(store::LocalDiskStore, fullpath::String) = isdir(fullpath)

isobject(store::LocalDiskStore, fullpath::String) = isfile(fullpath)

end
