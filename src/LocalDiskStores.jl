module LocalDiskStores


export LocalDiskStorage


using AbstractBucketStores
using Authorization: AbstractResource


struct LocalDiskBucket <: AbstractResource
    @add_required_fields_resource  # id
end


struct LocalDiskObject <: AbstractResource
    @add_required_fields_resource  # id
end


struct LocalDiskStorage <: AbstractStorageBackend
    bucket_type::LocalDiskBucket
    object_type::LocalDiskObject
end


################################################################################
# Buckets

"If fullpath is a bucket, return a list of the bucket's contents, else return nothing."
function _read(bucket::LocalDiskBucket)
    _isobject(bucket.id)  && return false    # Cannot list the contents of an object
    !_isbucket(bucket.id) && return nothing  # Bucket doesn't exist
    readdir(bucket.id)
end


"""
Returns true if bucket is successfully created, false otherwise.

Create bucket if:
1. It doesn't already exist (as either a bucket or an object), and
2. The containing bucket exists.
"""
function _create!(bucket::LocalDiskBucket)
    _isbucket(bucket.id) && return false  # Bucket already exists
    cb, bktname = splitdir(bucket.id)
    !_isbucket(cb) && return false  # Containing bucket doesn't exist
    mkdir(bucket.id)
    true
end


"""
Returns true if bucket is successfully deleted, false otherwise.

Delete bucket if:
1. fullpath is a bucket name (the bucket exists), and
2. The bucket is empty.
"""
function _deletebucket!(store::LocalDiskStore, fullpath::String)
    contents = _listcontents(store, fullpath)
    contents == nothing && return false  # fullpath is not a bucket
    !isempty(contents)  && return false  # Bucket is not empty
    rm(fullpath)
    true
end


################################################################################
# Objects

"Return object if fullpath refers to an object, else return nothing."
function _getindex(store::LocalDiskStore, fullpath::String) 
    !_isobject(store, fullpath) && return nothing
    read(fullpath)
end


"If fullpath is an object, set fullpath = v and return true, else return false."
function _setindex!(store::LocalDiskStore, v, fullpath::String)
    write(fullpath, v)
    true
end


"If object exists, delete it and return true, else return false."
function _delete!(store::LocalDiskStore, fullpath::String)
    !_isobject(store, fullpath) && return false
    rm(fullpath)
    true
end


################################################################################
# Conveniences

_islocal(backend::LocalDiskStorage) = true

_isbucket(resourceid::String) = isdir(resourceid)

_isobject(resourceid::String) = isfile(resourceid)

end
