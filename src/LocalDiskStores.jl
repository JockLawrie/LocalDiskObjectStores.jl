module LocalDiskStores


export LocalDiskStore,
       listcontents, createbucket!, deletebucket!,  # Buckets (re-exported from AbstractBucketStores)
       getindex, setindex!, delete!,                # Objects (re-exported from AbstractBucketStores)
       islocal, isbucket, isobject,                 # Conveniences (re-exported from AbstractBucketStores)
       hasbucket, hasobject                         # More conveniences (re-exported from AbstractBucketStores)


using AbstractBucketStores


struct LocalDiskStore <: AbstractBucketStore
    @add_BucketStore_common_fields
end


################################################################################
# Buckets

"If fullpath is a bucket, return a list of the bucket's contents, else return nothing."
function _listcontents(store::LocalDiskStore, fullpath::String)
    _isobject(store, fullpath)  && return false    # Cannot list the contents of an object
    !_isbucket(store, fullpath) && return nothing  # Bucket doesn't exist
    readdir(fullpath)
end


"""
Returns true if bucket is successfully created, false otherwise.

Create bucket if:
1. It doesn't already exist (as either a bucket or an object), and
2. The containing bucket exists.
"""
function _createbucket!(store::LocalDiskStore, fullpath::String)
    _isbucket(store, fullpath) && return false  # Bucket already exists
    cb, bktname = splitdir(fullpath)
    !_isbucket(store, cb) && return false       # Containing bucket doesn't exist
    mkdir(fullpath)
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

_islocal(store::LocalDiskStore) = true

_isbucket(store::LocalDiskStore, fullpath::String) = isdir(fullpath)

_isobject(store::LocalDiskStore, fullpath::String) = isfile(fullpath)

end
