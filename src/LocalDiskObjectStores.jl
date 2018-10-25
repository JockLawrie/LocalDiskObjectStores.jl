module LocalDiskObjectStores

using ObjectStores:  ObjectStoreClient
using ObjectStores:  @add_required_fields_storageclient
using Authorization: AbstractResource
using Authorization: @add_required_fields_resource


################################################################################
# Types

struct Bucket <: AbstractResource
    @add_required_fields_resource  # id
end

struct Object <: AbstractResource
    @add_required_fields_resource  # id
end

struct Client <: ObjectStoreClient
    @add_required_fields_storageclient  # :bucket_type, :object_type

    function Client(bucket_type, object_type)
        !(bucket_type == Bucket) && error("LocalDiskStore.bucket_type must be Bucket.")
        !(object_type == Object) && error("LocalDiskStore.object_type must be Object.")
        new(bucket_type, object_type)
    end
end

Client() = Client(Bucket, Object)


################################################################################
# Buckets

"Create bucket. If successful return nothing, else return an error message as a String."
function _create!(bucket::Bucket)
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
function _read(bucket::Bucket)
    _isobject(bucket.id)  && return (false, "Bucket ID refers to an object")
    !_isbucket(bucket.id) && return (false, "Bucket doesn't exist")
    try
        return (true, readdir(bucket.id))
    catch e
        return (false, e.prefix)  # Assumes e is a SystemError
    end
end


"Delete bucket. If successful return nothing, else return an error message as a String."
function _delete!(bucket::Bucket)
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
function _create!(object::Object, v)
    try
        resourceid = object.id
        _isbucket(resourceid) && return "$(resourceid) is a bucket, not an object"
        cb, shortname = splitdir(resourceid)
        !_isbucket(cb) && return "Cannot create object $(resourceid) inside a non-existent bucket."
        write(object.id, v)
        return nothing
    catch e
        return e.prefix  # Assumes e is a SystemError
    end
end


"Read object. If successful return (true, value), else return (false, errormessage::String)."
function _read(object::Object)
    !_isobject(object.id) && return (false, "Object ID does not refer to an existing object")
    try
        true, read(object.id)
    catch e
        return false, e.prefix  # Assumes e is a SystemError
    end
end


"Delete object. If successful return nothing, else return an error message as a String."
function _delete!(object::Object)
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

_islocal(backend::Client) = true

_isbucket(resourceid::String) = isdir(resourceid)

_isobject(resourceid::String) = isfile(resourceid)

end
