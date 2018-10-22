module LocalDiskStores


export LocalDiskStore


using AbstractBucketStores
using Authorization: AbstractResource
using Authorization: @add_required_fields_resource


################################################################################
# Types

struct LocalDiskBucket <: AbstractResource
    @add_required_fields_resource  # id
end

struct LocalDiskObject <: AbstractResource
    @add_required_fields_resource  # id
end

struct LocalDiskStore <: AbstractStorageBackend
    bucket_type::DataType
    object_type::DataType

    function LocalDiskStore(bucket_type, object_type)
        !(bucket_type == LocalDiskBucket) && error("LocalDiskStore.bucket_type must be LocalDiskBucket.")
        !(object_type == LocalDiskObject) && error("LocalDiskStore.object_type must be LocalDiskObject.")
        new(bucket_type, object_type)
    end
end

LocalDiskStore() = LocalDiskStore(LocalDiskBucket, LocalDiskObject)


################################################################################
# Buckets

"Create bucket. If successful return nothing, else return an error message as a String."
function _create!(bucket::LocalDiskBucket)
    _isbucket(bucket.id) && return "Bucket already exists. Cannot create it again."
    cb, bktname = splitdir(bucket.id)
    !_isbucket(cb) && return "Cannot create bucket within a non-existent bucket."
    try
        mkdir(bucket.id)
        return nothing
    catch e
        return e.prefix  # Assumes e is a SystemError
    end
end


"Read bucket. If successful return (true, value), else return (false, errormessage::String)."
function _read(bucket::LocalDiskBucket)
    _isobject(bucket.id)  && return (false, "Bucket ID refers to an object")
    !_isbucket(bucket.id) && return (false, "Bucket doesn't exist")
    try
        return (true, readdir(bucket.id))
    catch e
        return (false, e.prefix)  # Assumes e is a SystemError
    end
end


"Delete bucket. If successful return nothing, else return an error message as a String."
function _delete!(bucket::LocalDiskBucket)
    ok, contents = _read(bucket)
    contents == nothing && return "Resource is not a bucket. Cannot delete it with this function."
    !isempty(contents)  && return "Bucket is not empty. Cannot delete it."
    try
        rm(bucket.id)
        return nothing
    catch e
        return e.prefix  # Assumes e is a SystemError
    end
end


################################################################################
# Objects

"Create object. If successful return nothing, else return an error message as a String."
function _create!(object::LocalDiskObject, v)
    try
        write(object.id, v)
        return nothing
    catch e
        return e.prefix  # Assumes e is a SystemError
    end
end


"Read object. If successful return (true, value), else return (false, errormessage::String)."
function _read(object::LocalDiskObject)
    !_isobject(object.id) && return (false, "Object ID does not refer to an existing object")
    try
        true, read(object.id)
    catch e
        return false, e.prefix  # Assumes e is a SystemError
    end
end


"Delete object. If successful return nothing, else return an error message as a String."
function _delete!(object::LocalDiskObject)
    !_isobject(object.id) && return "Object ID does not refer to an existing object. Cannot delete a non-existent object."
    try
        rm(object.id)
        return nothing
    catch e
        return e.prefix  # Assumes e is a SystemError
    end
end


################################################################################
# Conveniences

_islocal(backend::LocalDiskStore) = true

_isbucket(resourceid::String) = isdir(resourceid)

_isobject(resourceid::String) = isfile(resourceid)

end
