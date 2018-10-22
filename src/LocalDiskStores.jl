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
    bucket_type::DataType
    object_type::DataType

    function LocalDiskStorage(bucket_type, object_type)
        !(bucket_type == LocalDiskBucket) && error("LocalDiskStorage.bucket_type must be LocalDiskBucket.")
        !(object_type == LocalDiskObject) && error("LocalDiskStorage.object_type must be LocalDiskObject.")
        new(bucket_type, object_type)
    end
end

LocalDiskStorage() = LocalDiskStorage(LocalDiskBucket, LocalDiskObject)


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
function _delete!(bucket::LocalDiskBucket)
    contents = _read(bucket)
    contents == nothing && return false  # Resource is not a bucket
    !isempty(contents)  && return false  # Bucket is not empty
    rm(bucket.id)
    true
end


################################################################################
# Objects

"Return object if fullpath refers to an object, else return nothing."
function _read(object::LocalDiskObject)
    !_isobject(object.id) && return nothing
    read(fullpath)
end


"If fullpath is an object, set fullpath = v and return true, else return false."
function _create!(object::LocalDiskObject, v)
    write(object.id, v)
    true
end


"If object exists, delete it and return true, else return false."
function _delete!(object::LocalDiskObject)
    !_isobject(object.id) && return false
    rm(object.id)
    true
end


################################################################################
# Conveniences

_islocal(backend::LocalDiskStorage) = true

_isbucket(resourceid::String) = isdir(resourceid)

_isobject(resourceid::String) = isfile(resourceid)

end
