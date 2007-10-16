/**
 * Oracle import library.
 *
 * Part of the D DBI project.
 *
 * Version:
 *	Oracle 10g revision 2
 *
 *	Import library version 0.04
 *
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.oracle.imp.ori;

private import dbi.oracle.imp.oci, dbi.oracle.imp.oratypes, dbi.oracle.imp.oro, dbi.oracle.imp.ort;

/**
 * Create an instance of an object.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	svc = OCI service handle.
 *	typecode =
 *	tdo =
 *	table =
 *	duration =
 *	value = Use TRUE for a value or. FALSE for an object.  Ignored if the instance isn't an object.
 *	instance = A pointer to the pointer to the new object.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCIObjectNew (OCIEnv* env, OCIError* err, OCISvcCtx* svc, OCITypeCode typecode, OCIType* tdo, dvoid* table, OCIDuration duration, boolean value, dvoid** instance);
/*
        typecode (IN) - the typecode of the type of the instance.
        tdo      (IN, optional) - pointer to the type descriptor object. The
                        TDO describes the type of the instance that is to be
                        created. Refer to OCITypeByName() for obtaining a TDO.
                        The TDO is required for creating a named type (e.g. an
                        object or a collection).
        table (IN, optional) - pointer to a table object which specifies a
                        table in the server.  This parameter can be set to NULL
                        if no table is given. See the description below to find
                        out how the table object and the TDO are used together
                        to determine the kind of instances (persistent,
                        transient, value) to be created. Also see
                        OCIObjectPinTable() for retrieving a table object.
        duration (IN) - this is an overloaded parameter. The use of this
                        parameter is based on the kind of the instance that is
                        to be created.
                        a) persistent object. This parameter specifies the
                           pin duration.
                        b) transient object. This parameter specififes the
                           allocation duration and pin duration.
                        c) value. This parameter specifies the allocation
                           duration.

   DESCRIPTION:
        This function creates a new instance of the type specified by the
        typecode or the TDO. Based on the parameters 'typecode' (or 'tdo'),
        'value' and 'table', different kinds of instances can be created:

                                     The parameter 'table' is not NULL?

                                               yes              no
             ----------------------------------------------------------------
             | object type (value=TRUE)   |   value         |   value       |
             ----------------------------------------------------------------
             | object type (value=FALSE)  | persistent obj  | transient obj |
       type  ----------------------------------------------------------------
             | built-in type              |   value         |   value       |
             ----------------------------------------------------------------
             | collection type            |   value         |   value       |
             ----------------------------------------------------------------

        This function allocates the top level memory chunk of an OTS instance.
        The attributes in the top level memory are initialized (e.g. an
        attribute of varchar2 is initialized to a vstring of 0 length).

        If the instance is an object, the object is marked existed but is
        atomically null.

        FOR PERSISTENT OBJECTS:
        The object is marked dirty and existed.  The allocation duration for
        the object is session. The object is pinned and the pin duration is
        specified by the given parameter 'duration'.

        FOR TRANSIENT OBJECTS:
        The object is pinned. The allocation duration and the pin duration are
        specified by the given parameter 'duration'.

        FOR VALUES:
        The allocation duration is specified by the given parameter 'duration'.
 */

extern (C) sword OCIObjectPin (OCIEnv* env, OCIError* err, OCIRef* object_ref, OCIComplexObject* corhdl, OCIPinOpt pin_option, OCIDuration pin_duration, OCILockOpt lock_option, dvoid** object);
/*
   NAME: OCIObjectPin - OCI pin a referenceable object
   PARAMETERS:
        env        (IN/OUT) - OCI environment handle initialized in object mode
        err        (IN/OUT) - error handle. If there is an error, it is
                              recorded in 'err' and this function returns
                              OCI_ERROR. The error recorded in 'err' can be
                              retrieved by calling OCIErrorGet().
        object_ref     (IN) - the reference to the object.
        corhdl         (IN) - handle for complex object retrieval.
        pin_option     (IN) - See description below.
        pin_duration   (IN) - The duration of which the object is being accesed
                              by a client. The object is implicitly unpinned at
                              the end of the pin duration.
                              If OCI_DURATION_NULL is passed, there is no pin
                              promotion if the object is already loaded into
                              the cache. If the object is not yet loaded, then
                              the pin duration is set to OCI_DURATION_DEFAULT.
        lock_option    (IN) - lock option (e.g., exclusive). If a lock option
                              is specified, the object is locked in the server.
                              See 'oro.h' for description about lock option.
        object        (OUT) - the pointer to the pinned object.

   REQUIRES:
        - a valid OCI environment handle must be given.
   DESCRIPTION:

        This function pins a referenceable object instance given the object
        reference. The process of pinning serves three purposes:

        1) locate an object given its reference. This is done by the object
           cache which keeps track of the objects in the object heap.

        2) notify the object cache that an object is being in use. An object
           can be pinned many times. A pinned object will remain in memory
           until it is completely unpinned (see OCIObjectUnpin()).

        3) notify the object cache that a persistent object is being in use
           such that the persistent object cannot be aged out.  Since a
           persistent object can be loaded from the server whenever is needed,
           the memory utilization can be increased if a completely unpinned
           persistent object can be freed (aged out), even before the
           allocation duration is expired.

        Also see OCIObjectUnpin() for more information about unpinning.

        FOR PERSISTENT OBJECTS:

        When pinning a persistent object, if it is not in the cache, the object
        will be fetched from the persistent store. The allocation duration of
        the object is session. If the object is already in the cache, it is
        returned to the client.  The object will be locked in the server if a
        lock option is specified.

        This function will return an error for a non-existent object.

        A pin option is used to specify the copy of the object that is to be
        retrieved:

        1) If option is OCI_PIN_ANY (pin any), if the object is already
           in the environment heap, return this object. Otherwise, the object
           is retrieved from the database.  This option is useful when the
           client knows that he has the exclusive access to the data in a
           session.

        2) If option is OCI_PIN_LATEST (pin latest), if the object is
           not cached, it is retrieved from the database.  If the object is
           cached, it is refreshed with the latest version. See
           OCIObjectRefresh() for more information about refreshing.

        3) If option is OCI_PIN_RECENT (pin recent), if the object is loaded
           into the cache in the current transaction, the object is returned.
           If the object is not loaded in the current transaction, the object
           is refreshed from the server.

        FOR TRANSIENT OBJECTS:

        This function will return an error if the transient object has already
        been freed. This function does not return an error if an exclusive
        lock is specified in the lock option.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectUnpin (OCIEnv* env, OCIError* err, dvoid* object);
/*
   NAME: OCIObjectUnpin - OCI unpin a referenceable object
   PARAMETERS:
        env   (IN/OUT) - OCI environment handle initialized in object mode
        err   (IN/OUT) - error handle. If there is an error, it is
                         recorded in 'err' and this function returns OCI_ERROR.
                         The error recorded in 'err' can be retrieved by
                         calling OCIErrorGet().
        object    (IN) - pointer to an object
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
   DESCRIPTION:
        This function unpins an object.  An object is completely unpinned when
          1) the object was unpinned N times after it has been pinned N times
             (by calling OCIObjectPin()).
          2) it is the end of the pin duration
          3) the function OCIObjectPinCountReset() is called

        There is a pin count associated with each object which is incremented
        whenever an object is pinned. When the pin count of the object is zero,
        the object is said to be completely unpinned. An unpinned object can
        be freed without error.

        FOR PERSISTENT OBJECTS:
        When a persistent object is completely unpinned, it becomes a candidate
        for aging. The memory of an object is freed when it is aged out. Aging
        is used to maximize the utilization of memory.  An dirty object cannot
        be aged out unless it is flushed.

        FOR TRANSIENT OBJECTS:
        The pin count of the object is decremented. A transient can be freed
        only at the end of its allocation duration or when it is explicitly
        deleted by calling OCIObjectFree().

        FOR VALUE:
        This function will return an error for value.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectPinCountReset (OCIEnv* env, OCIError* err, dvoid* object);
/*
   NAME: OCIObjectPinCountReset - OCI resets the pin count of a referenceable
                                  object
   PARAMETERS:
        env   (IN/OUT) - OCI environment handle initialized in object mode
        err   (IN/OUT) - error handle. If there is an error, it is
                         recorded in 'err' and this function returns OCI_ERROR.
                         The error recorded in 'err' can be retrieved by
                         calling OCIErrorGet().
        object    (IN) - pointer to an object
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
   DESCRIPTION:
        This function completely unpins an object.  When an object is
        completely unpinned, it can be freed without error.

        FOR PERSISTENT OBJECTS:
        When a persistent object is completely unpinned, it becomes a candidate
        for aging. The memory of an object is freed when it is aged out. Aging
        is used to maximize the utilization of memory.  An dirty object cannot
        be aged out unless it is flushed.

        FOR TRANSIENT OBJECTS:
        The pin count of the object is decremented. A transient can be freed
        only at the end of its allocation duration or when it is explicitly
        freed by calling OCIObjectFree().

        FOR VALUE:
        This function will return an error for value.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectLock (OCIEnv* env, OCIError* err, dvoid* object);
/*
   NAME: OCIObjectLock - OCI lock a persistent object
   PARAMETERS:
        env   (IN/OUT) - OCI environment handle initialized in object mode
        err   (IN/OUT) - error handle. If there is an error, it is
                         recorded in 'err' and this function returns OCI_ERROR.
                         The error recorded in 'err' can be retrieved by
                         calling OCIErrorGet().
        object    (IN) - pointer to the persistent object
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
   DESCRIPTION:
        This function locks a persistent object at the server. Unlike
        OCIObjectLockNoWait() this function waits if another user currently
        holds a lock on the desired object. This function
        returns an error if:
          1) the object is non-existent.

        This function will return an error for transient objects and values.
        The lock of an object is released at the end of a transaction.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
*/

extern (C) sword OCIObjectLockNoWait (OCIEnv* env, OCIError* err, dvoid* object);
/*
   NAME: OCIObjectLockNoWait - OCI lock a persistent object, do not wait for
                               the lock, return error if lock not available
   PARAMETERS:
        env   (IN/OUT) - OCI environment handle initialized in object mode
        err   (IN/OUT) - error handle. If there is an error, it is
                         recorded in 'err' and this function returns OCI_ERROR.
                         The error recorded in 'err' can be retrieved by
                         calling OCIErrorGet().
        object    (IN) - pointer to the persistent object
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
   DESCRIPTION:
        This function locks a persistent object at the server. Unlike
        OCIObjectLock() this function will not wait if another user holds
        the lock on the desired object. This function returns an error if:
          1) the object is non-existent.
          2) the object is currently locked by another user in which
             case this function returns with an error.

        This function will return an error for transient objects and values.
        The lock of an object is released at the end of a transaction.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
*/

extern (C) sword OCIObjectMarkUpdate (OCIEnv* env, OCIError* err, dvoid* object);
/*
   NAME: OCIObjectMarkUpdate - OCI marks an object as updated
   PARAMETERS:
        env   (IN/OUT) - OCI environment handle initialized in object mode
        err   (IN/OUT) - error handle. If there is an error, it is
                         recorded in 'err' and this function returns OCI_ERROR.
                         The error recorded in 'err' can be retrieved by
                         calling OCIErrorGet().
        object    (IN) - pointer to the persistent object
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
   DESCRIPTION:
        FOR PERSISTENT OBJECTS:
        This function marks the specified persistent object as updated. The
        persistent objects will be written to the server when the object cache
        is flushed.  The object is not locked or flushed by this function. It
        is an error to update a deleted object.

        After an object is marked updated and flushed, this function must be
        called again to mark the object as updated if it has been dirtied
        after it is being flushed.

        FOR TRANSIENT OBJECTS:
        This function marks the specified transient object as updated. The
        transient objects will NOT be written to the server. It is an error
        to update a deleted object.

        FOR VALUES:
        It is an no-op for values.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectUnmark (OCIEnv* env, OCIError* err, dvoid* object);
/*
   NAME: OCIObjectUnmark - OCI unmarks an object
   PARAMETERS:
        env   (IN/OUT) - OCI environment handle initialized in object mode
        err   (IN/OUT) - error handle. If there is an error, it is
                         recorded in 'err' and this function returns OCI_ERROR.
                         The error recorded in 'err' can be retrieved by
                         calling OCIErrorGet().
        object    (IN) - pointer to the persistent object
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
   DESCRIPTION:
        FOR PERSISTENT OBJECTS AND TRANSIENT OBJECTS:
        This function unmarks the specified persistent object as dirty. Changes
        that are made to the object will not be written to the server. If the
        object is marked locked, it remains marked locked.  The changes that
        have already made to the object will not be undone implicitly.

        FOR VALUES:
        It is an no-op for values.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectUnmarkByRef (OCIEnv* env, OCIError* err, OCIRef* ref);
/*
   NAME: OCIObjectUnmarkByRef - OCI unmarks an object by Ref
   PARAMETERS:
        env   (IN/OUT) - OCI environment handle initialized in object mode
        err   (IN/OUT) - error handle. If there is an error, it is
                         recorded in 'err' and this function returns OCI_ERROR.
                         The error recorded in 'err' can be retrieved by
                         calling OCIErrorGet().
        ref   (IN) - reference of the object
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
   DESCRIPTION:
        FOR PERSISTENT OBJECTS AND TRANSIENT OBJECTS:
        This function unmarks the specified persistent object as dirty. Changes
        that are made to the object will not be written to the server. If the
        object is marked locked, it remains marked locked.  The changes that
        have already made to the object will not be undone implicitly.

        FOR VALUES:
        It is an no-op for values.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectFree (OCIEnv* env, OCIError* err, dvoid* instance, ub2 flags);
/*
   NAME: OCIObjectFree - OCI free (and unpin) an standalone instance
   PARAMETERS:
        env    (IN/OUT) - OCI environment handle initialized in object mode
        err    (IN/OUT) - error handle. If there is an error, it is
                          recorded in 'err' and this function returns
                          OCI_ERROR.  The error recorded in 'err' can be
                          retrieved by calling OCIErrorGet().
        instance   (IN) - pointer to a standalone instance.
        flags      (IN) - If OCI_OBJECT_FREE_FORCE is set, free the object
                          even if it is pinned or dirty.
                          If OCI_OBJECT_FREE_NONULL is set, the null
                          structure will not be freed.
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The instance to be freed must be standalone.
        - If the instance is a referenceable object, the object must be pinned.
   DESCRIPTION:
        This function deallocates all the memory allocated for an OTS instance,
        including the null structure.

        FOR PERSISTENT OBJECTS:
        This function will return an error if the client is attempting to free
        a dirty persistent object that has not been flushed. The client should
        either flush the persistent object or set the parameter 'flag' to
        OCI_OBJECT_FREE_FORCE.

        This function will call OCIObjectUnpin() once to check if the object
        can be completely unpin. If it succeeds, the rest of the function will
        proceed to free the object.  If it fails, then an error is returned
        unless the parameter 'flag' is set to OCI_OBJECT_FREE_FORCE.

        Freeing a persistent object in memory will not change the persistent
        state of that object at the server.  For example, the object will
        remain locked after the object is freed.

        FOR TRANSIENT OBJECTS:

        This function will call OCIObjectUnpin() once to check if the object
        can be completely unpin. If it succeeds, the rest of the function will
        proceed to free the object.  If it fails, then an error is returned
        unless the parameter 'flag' is set to OCI_OBJECT_FREE_FORCE.

        FOR VALUES:
        The memory of the object is freed immediately.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
*/

extern (C) sword OCIObjectMarkDeleteByRef (OCIEnv* env, OCIError* err, OCIRef* object_ref);
/*
   NAME: OCIObjectMarkDeleteByRef - OCI "delete" (and unpin) an object given
                                    a reference
   PARAMETERS:
        env     (IN/OUT) - OCI environment handle initialized in object mode
        err     (IN/OUT) - error handle. If there is an error, it is
                           recorded in 'err' and this function returns
                           OCI_ERROR.  The error recorded in 'err' can be
                           retrieved by calling OCIErrorGet().
        object_ref  (IN) - ref of the object to be deleted

   REQUIRES:
        - a valid OCI environment handle must be given.
   DESCRIPTION:
        This function marks the object designated by 'object_ref' as deleted.

        FOR PERSISTENT OBJECTS:
        If the object is not loaded, then a temporary object is created and is
        marked deleted. Otherwise, the object is marked deleted.

        The object is deleted in the server when the object is flushed.

        FOR TRANSIENT OBJECTS:
        The object is marked deleted.  The object is not freed until it is
        unpinned.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectMarkDelete (OCIEnv* env, OCIError* err, dvoid* instance);
/*
   NAME: OCIObjectMarkDelete - OCI "delete" an instance given a Pointer
   PARAMETERS:
        env    (IN/OUT) - OCI environment handle initialized in object mode
        err    (IN/OUT) - error handle. If there is an error, it is
                          recorded in 'err' and this function returns
                          OCI_ERROR.  The error recorded in 'err' can be
                          retrieved by calling OCIErrorGet().
        instance   (IN) - pointer to the instance
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The instance must be standalone.
        - If the instance is a referenceable object, then it must be pinned.
   DESCRIPTION:

        FOR PERSISTENT OBJECTS:
        The object is marked deleted.  The memory of the object is not freed.
        The object is deleted in the server when the object is flushed.

        FOR TRANSIENT OBJECTS:
        The object is marked deleted.  The memory of the object is not freed.

        FOR VALUES:
        This function frees a value immediately.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectFlush (OCIEnv* env, OCIError* err, dvoid* object);
/*
   NAME: OCIObjectFlush - OCI flush a persistent object
   PARAMETERS:
        env    (IN/OUT) - OCI environment handle initialized in object mode
        err    (IN/OUT) - error handle. If there is an error, it is
                          recorded in 'err' and this function returns
                          OCI_ERROR.  The error recorded in 'err' can be
                          retrieved by calling OCIErrorGet().
        object     (IN) - pointer to the persistent object
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
   DESCRIPTION:
        This function flushes a modified persistent object to the server.
        An exclusive lock is obtained implicitly for the object when flushed.

        When the object is written to the server, triggers may be fired.
        Objects can be modified by the triggers at the server.  To keep the
        objects in the object cache being coherent with the database, the
        clients can free or refresh the objects in the cache.

        This function will return an error for transient objects and values.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectRefresh (OCIEnv* env, OCIError* err, dvoid* object);
/*
   NAME: OCIObjectRefresh - OCI refresh a persistent object
   PARAMETERS:
        env    (IN/OUT) - OCI environment handle initialized in object mode
        err    (IN/OUT) - error handle. If there is an error, it is
                          recorded in 'err' and this function returns
                          OCI_ERROR.  The error recorded in 'err' can be
                          retrieved by calling OCIErrorGet().
        object     (IN) - pointer to the persistent object
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
   DESCRIPTION:
        This function refreshes an unmarked object with data retrieved from the
        latest snapshot in the server. An object should be refreshed when the
        objects in the cache are inconsistent with the objects at
        the server:
        1) When an object is flushed to the server, triggers can be fired to
           modify more objects in the server.  The same objects (modified by
           the triggers) in the object cache become obsolete.
        2) When the user issues a SQL or executes a PL/SQL procedure to modify
           any object in the server, the same object in the cache becomes
           obsolete.

        The object that is refreshed will be 'replaced-in-place'. When an
        object is 'replaced-in-place', the top level memory of the object will
        be reused so that new data can be loaded into the same memory address.
        The top level memory of the null structre is also reused. Unlike the
        top level memory chunk, the secondary memory chunks may be resized and
        reallocated.  The client should be careful when holding onto a pointer
        to the secondary memory chunk (e.g. assigning the address of a
        secondary memory to a local variable), since this pointer can become
        invalid after the object is refreshed.

        The object state will be modified as followed after being refreshed:
          - existent : set to appropriate value
          - pinned   : unchanged
          - allocation duration : unchanged
          - pin duration : unchanged

        This function is an no-op for transient objects or values.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectCopy (OCIEnv* env, OCIError* err, OCISvcCtx* svc, dvoid* source, dvoid* null_source, dvoid* target, dvoid* null_target, OCIType* tdo, OCIDuration duration, ub1 option);
/*
   NAME: OCIObjectCopy - OCI copy one instance to another
   PARAMETERS:
        env     (IN/OUT) - OCI environment handle initialized in object mode
        err     (IN/OUT) - error handle. If there is an error, it is
                           recorded in 'err' and this function returns
                           OCI_ERROR.  The error recorded in 'err' can be
                           retrieved by calling OCIErrorGet().
        svc         (IN) - OCI service context handle
        source      (IN) - pointer to the source instance
        null_source (IN) - pointer to the null structure of the source
        target      (IN) - pointer to the target instance
        null_target (IN) - pointer to the null structure of the target
        tdo         (IN) - the TDO for both source and target
        duration    (IN) - allocation duration of the target memory
        option      (IN) - specify the copy option:
                        OROOCOSFN - Set Reference to Null. All references
                        in the source will not be copied to the target. The
                        references in the target are set to null.
   REQUIRES:
        - a valid OCI environment handle must be given.
        - If source or target is referenceable, it must be pinned.
        - The target or the containing instance of the target must be already
          be instantiated (e.g. created by OCIObjectNew()).
        - The source and target instances must be of the same type. If the
          source and target are located in a different databases, then the
          same type must exist in both databases.
   DESCRIPTION:
        This function copies the contents of the 'source' instance to the
        'target' instance. This function performs a deep-copy such that the
        data that is copied/duplicated include:
        a) all the top level attributes (see the exceptions below)
        b) all the secondary memory (of the source) that is reachable from the
           top level attributes.
        c) the null structure of the instance

        Memory is allocated with the specified allocation duration.

        Certain data items are not copied:
        a) If the option OCI_OBJECTCOPY_NOREF is specified, then all references
           in the source are not copied. Instead, the references in the target
           are set to null.
        b) If the attribute is a LOB, then it is set to null.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectGetTypeRef (OCIEnv* env, OCIError* err, dvoid* instance, OCIRef* type_ref);
/*
   NAME: OCIObjectGetTypeRef - get the type reference of a standalone object
   PARAMETERS:
        env   (IN/OUT) - OCI environment handle initialized in object mode
        err   (IN/OUT) - error handle. If there is an error, it is
                         recorded in 'err' and this function returns
                         OCI_ERROR.  The error recorded in 'err' can be
                         retrieved by calling OCIErrorGet().
        instance  (IN) - pointer to an standalone instance
        type_ref (OUT) - reference to the type of the object.  The reference
                         must already be allocated.
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The instance must be standalone.
        - If the object is referenceable, the specified object must be pinned.
        - The reference must already be allocated.
   DESCRIPTION:
        This function returns a reference to the TDO of a standalone instance.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectGetObjectRef (OCIEnv* env, OCIError* err, dvoid* object, OCIRef* object_ref);
/*
   NAME: OCIObjectGetObjectRef - OCI get the object reference of an
                                 referenceable object
   PARAMETERS:
        env     (IN/OUT) - OCI environment handle initialized in object mode
        err     (IN/OUT) - error handle. If there is an error, it is
                           recorded in 'err' and this function returns
                           OCI_ERROR.  The error recorded in 'err' can be
                           retrieved by calling OCIErrorGet().
        object      (IN) - pointer to a persistent object
        object_ref (OUT) - reference of the given object. The reference must
                           already be allocated.
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified object must be pinned.
        - The reference must already be allocated.
   DESCRIPTION:
        This function returns a reference to the given object.  It returns an
        error for values.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectMakeObjectRef (OCIEnv* env, OCIError* err, OCISvcCtx* svc, dvoid* table, dvoid** values, ub4 array_len, OCIRef* object_ref);
/*
   NAME: OCIObjectMakeObjectRef - OCI Create an object reference to a
                                 referenceable object.
   PARAMETERS:
        env     (IN/OUT) - OCI environment handle initialized in object mode
        err     (IN/OUT) - error handle. If there is an error, it is
                           recorded in 'err' and this function returns
                           OCI_ERROR.  The error recorded in 'err' can be
                           retrieved by calling OCIErrorGet().
        svc         (IN) - the service context
        table       (IN) - A pointer to the table object (must be pinned)
        attrlist    (IN) - A list of values (OCI type values) from which
                           the ref is to be created.
        attrcnt     (IN)  - The length of the attrlist array.
        object_ref (OUT) - reference of the given object. The reference must
                           already be allocated.
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified table object must be pinned.
        - The reference must already be allocated.
   DESCRIPTION:
        This function creates a reference given the values that make up the
        reference and also a pointer to the table object.
        Based on the table's OID property, whether it is a pk based OID or
        a system generated OID, the function creates a sys-generated REF or
        a pk based REF.
        In case of system generated REFs pass in a OCIRaw which is 16 bytes
        long contatining the sys generated OID.
        In case of PK refs pass in the OCI equivalent for numbers, chars etc..
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectGetPrimaryKeyTypeRef (OCIEnv* env, OCIError* err, OCISvcCtx* svc, dvoid* table, OCIRef* type_ref );
/*
   NAME: OCIObjectGetPrimaryKeyTypeRef - OCI get the REF to the pk OID type
   PARAMETERS:
        env     (IN/OUT) - OCI environment handle initialized in object mode
        err     (IN/OUT) - error handle. If there is an error, it is
                           recorded in 'err' and this function returns
                           OCI_ERROR.  The error recorded in 'err' can be
                           retrieved by calling OCIErrorGet().
        svc     (IN)     - the service context
        table   (IN)     - pointer to the table object
        type_ref   (OUT) - reference of the pk type. The reference must
                           already be allocated.
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The specified table object must be pinned.
        - The reference must already be allocated.
   DESCRIPTION:
        This function returns a reference to the pk type.  It returns an
        error for values.  If the table is not a Pk oid table/view, then
        it returns error.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectGetInd (OCIEnv* env, OCIError* err, dvoid* instance, dvoid** null_struct);
/*
   NAME: OCIObjectGetInd - OCI get the null structure of a standalone object
   PARAMETERS:
        env     (IN/OUT) - OCI environment handle initialized in object mode
        err     (IN/OUT) - error handle. If there is an error, it is
                           recorded in 'err' and this function returns
                           OCI_ERROR.  The error recorded in 'err' can be
                           retrieved by calling OCIErrorGet().
        instance      (IN) - pointer to the instance
        null_struct (OUT) - null structure
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The object must be standalone.
        - If the object is referenceable, the specified object must be pinned.
   DESCRIPTION:
        This function returns the null structure of an instance. This function
        will allocate the top level memory of the null structure if it is not
        already allocated. If an null structure cannot be allocated for the
        instance, then an error is returned. This function only works for
        ADT or row type instance.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectExists (OCIEnv* env, OCIError* err, dvoid* ins, boolean* exist);
/*
   NAME: OCIObjectExist - OCI checks if the object exists
   PARAMETERS:
        env       (IN/OUT) - OCI environment handle initialized in object mode
        err       (IN/OUT) - error handle. If there is an error, it is
                             recorded in 'err' and this function returns
                             OCI_ERROR.  The error recorded in 'err' can be
                             retrieved by calling OCIErrorGet().
        ins           (IN) - pointer to an instance
        exist        (OUT) - return TRUE if the object exists
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The object must be standalone.
        - if object is a referenceable, it must be pinned.
   DESCRIPTION:
        This function returns the existence of an instance. If the instance
        is a value, this function always returns TRUE.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectGetProperty (OCIEnv* envh, OCIError* errh, dvoid* obj, OCIObjectPropId propertyId, dvoid *property, ub4* size );
/*
   NAME: OCIObjectGetProperty - OCIObject Get Property of given object
   PARAMETERS:
        env       (IN/OUT) - OCI environment handle initialized in object mode
        err       (IN/OUT) - error handle. If there is an error, it is
                             recorded in 'err' and this function returns
                             OCI_ERROR.  The error recorded in 'err' can be
                             retrieved by calling OCIErrorGet().
        obj           (IN) - object whose property is returned
        propertyId    (IN) - id which identifies the desired property
        property     (OUT) - buffer into which the desired property is
                             copied
        size      (IN/OUT) - on input specifies the size of the property buffer
                             passed by caller, on output will contain the
                             size in bytes of the property returned.
                             This parameter is required for string type
                             properties only (e.g OCI_OBJECTPROP_SCHEMA,
                             OCI_OBJECTPROP_TABLE). For non-string
                             properties this parameter is ignored since
                             the size is fixed.
   DESCRIPTION:
        This function returns the specified property of the object.
        The desired property is identified by 'propertyId'. The property
        value is copied into 'property' and for string typed properties
        the string size is returned via 'size'.

        Objects are classified as persistent, transient and value
        depending upon the lifetime and referenceability of the object.
        Some of the properties are applicable only to persistent
        objects and some others only apply to persistent and
        transient objects. An error is returned if the user tries to
        get a property which in not applicable to the given object.
        To avoid such an error, the user should first check whether
        the object is persistent or transient or value
        (OCI_OBJECTPROP_LIFETIME property) and then appropriately
        query for other properties.

        The different property ids and the corresponding type of
        'property' argument is given below.

          OCI_OBJECTPROP_LIFETIME
            This identifies whether the given object is a persistent
            object (OCI_OBJECT_PERSISTENT) or a
            transient object (OCI_OBJECT_TRANSIENT) or a
            value instance (OCI_OBJECT_VALUE).
            'property' argument must be a pointer to a variable of
            type OCIObjectLifetime.

          OCI_OBJECTPROP_SCHEMA
            This returns the schema name of the table in which the
            object exists. An error is returned if the given object
            points to a transient instance or a value. If the input
            buffer is not big enough to hold the schema name an error
            is returned, the error message will communicate the
            required size. Upon success, the size of the returned
            schema name in bytes is returned via 'size'.
            'property' argument must be an array of type text and 'size'
            should be set to size of array in bytes by the caller.

          OCI_OBJECTPROP_TABLE
            This returns the table name in which the object exists. An
            error is returned if the given object points to a
            transient instance or a value. If the input buffer is not
            big enough to hold the table name an error is returned,
            the error message will communicate the required size. Upon
            success, the size of the returned table name in bytes is
            returned via 'size'. 'property' argument must be an array
            of type text and 'size' should be set to size of array in
            bytes by the caller.

          OCI_OBJECTPROP_PIN_DURATION
            This returns the pin duration of the object.
            An error is returned if the given object points to a value
            instance. Valid pin durations are: OCI_DURATION_SESSION and
            OCI_DURATION_TRANS.
            'property' argument must be a pointer to a variable of type
            OCIDuration.

          OCI_OBJECTPROP_ALLOC_DURATION
            This returns the allocation duration of the object.
            Valid allocation durations are: OCI_DURATION_SESSION and
            OCI_DURATION_TRANS.
            'property' argument must be a pointer to a variable of type
            OCIDuration.

          OCI_OBJECTPROP_LOCK
            This returns the lock status of the
            object. The possible lock status is enumerated by OCILockOpt.
            An error is returned if the given object points to a transient
            or value instance.
            'property' argument must be a pointer to a variable of
            type OCILockOpt.
            Note, the lock status of an object can also be retrieved by
            calling OCIObjectIsLocked().

          OCI_OBJECTPROP_MARKSTATUS
            This returns the status flag which indicates whether the
            object is a new object, updated object and/or deleted object.
            The following macros can be used to test the mark status
            flag:

              OCI_OBJECT_IS_UPDATED(flag)
              OCI_OBJECT_IS_DELETED(flag)
              OCI_OBJECT_IS_NEW(flag)
              OCI_OBJECT_IS_DIRTY(flag)

            An object is dirty if it is a new object or marked deleted or
            marked updated.
            An error is returned if the given object points to a transient
            or value instance. 'property' argument must be of type
            OCIObjectMarkStatus.

          OCI_OBJECTPROP_VIEW
            This identifies whether the specified object is a view object
            or not. If property value returned is TRUE, it indicates the
            object is a view otherwise it is not.
            'property' argument must be of type boolean.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR. Possible errors are TBD
 */

extern (C) sword OCIObjectIsLocked (OCIEnv* env, OCIError* err, dvoid* ins, boolean* lock);
/*
   NAME: OCIObjectIsLocked - OCI get the lock status of a standalone object
   PARAMETERS:
        env       (IN/OUT) - OCI environment handle initialized in object mode
        err       (IN/OUT) - error handle. If there is an error, it is
                             recorded in 'err' and this function returns
                             OCI_ERROR.  The error recorded in 'err' can be
                             retrieved by calling OCIErrorGet().
        ins           (IN) - pointer to an instance
        lock         (OUT) - return value for the lock status.
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The instance must be standalone.
        - If the object is referenceable, the specified object must be pinned.
   DESCRIPTION:
        This function returns the lock status of an instance. If the instance
        is a value, this function always returns FALSE.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectIsDirty (OCIEnv* env, OCIError* err, dvoid* ins, boolean* dirty);
/*
   NAME: OCIObjectIsDirty - OCI get the dirty status of a standalone object
   PARAMETERS:
        env       (IN/OUT) - OCI environment handle initialized in object mode
        err       (IN/OUT) - error handle. If there is an error, it is
                             recorded in 'err' and this function returns
                             OCI_ERROR.  The error recorded in 'err' can be
                             retrieved by calling OCIErrorGet().
        ins           (IN) - pointer to an instance
        dirty        (OUT) - return value for the dirty status.
   REQUIRES:
        - a valid OCI environment handle must be given.
        - The instance must be standalone.
        - if instance is an object, the instance must be pinned.
   DESCRIPTION:
        This function returns the dirty status of an instance. If the instance
        is a value, this function always returns FALSE.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectPinTable (OCIEnv* env, OCIError* err, OCISvcCtx* svc, oratext* schema_name, ub4 s_n_length, oratext* object_name, ub4 o_n_length, OCIRef* scope_obj_ref, OCIDuration pin_duration, dvoid** object);
/*
   NAME: OCIObjectPinTable - OCI get table object
   PARAMETERS:
        env       (IN/OUT) - OCI environment handle initialized in object mode
        err       (IN/OUT) - error handle. If there is an error, it is
                             recorded in 'err' and this function returns
                             OCI_ERROR.  The error recorded in 'err' can be
                             retrieved by calling OCIErrorGet().
        svc                     (IN) - OCI service context handle
        schema_name   (IN, optional) - schema name of the table
        s_n_length    (IN, optional) - length of the schema name
        object_name   (IN) - name of the table
        o_n_length    (IN) - length of the table name
        scope_obj_ref (IN, optional) - reference of the scoping object
        pin_duration  (IN) - pin duration. See description in OCIObjectPin().
        object       (OUT) - the pinned table object
   REQUIRES:
        - a valid OCI environment handle must be given.
   DESCRIPTION:
        This function pin a table object with the specified pin duration.
        The client can unpin the object by calling OCIObjectUnpin(). See
        OCIObjectPin() and OCIObjectUnpin() for more information about pinning
        and unpinning.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIObjectArrayPin (OCIEnv* env, OCIError* err, OCIRef** ref_array, ub4 array_size, OCIComplexObject** cor_array, ub4 cor_array_size, OCIPinOpt pin_option, OCIDuration pin_duration, OCILockOpt lock, dvoid** obj_array, ub4* pos);
/*
   NAME: OCIObjectArrayPin - ORIO array pin
   PARAMETERS:
        env       (IN/OUT) - OCI environment handle initialized in object mode
        err       (IN/OUT) - error handle. If there is an error, it is
                             recorded in 'err' and this function returns
                             OCI_ERROR.  The error recorded in 'err' can be
                             retrieved by calling OCIErrorGet().
        ref_array     (IN) - array of references to be pinned
        array_size    (IN) - number of elements in the array of references
        pin_option    (IN) - pin option. See OCIObjectPin().
        pin_duration  (IN) - pin duration. See OCIObjectPin().
        lock_option   (IN) - lock option. See OCIObjectPin().
        obj_array    (OUT) - If this argument is not NULL, the pinned objects
                             will be returned in the array. The user must
                             allocate this array with element type being
                             'dvoid *'. The size of this array is identical to
                             'array'.
        pos          (OUT) - If there is an error, this argument will contain
                             the element that is causing the error.  Note that
                             this argument is set to 1 for the first element in
                             the ref_array.
   REQUIRE:
        - a valid OCI environment handle must be given.
        - If 'obj_array' is not NULL, then it must already be allocated and
             the size of 'obj_array' is 'array_size'.
   DESCRIPTION:
        This function pin an array of references.  All the pinned objects are
        retrieved from the database in one network roundtrip.  If the user
        specifies an output array ('obj_array'), then the address of the
        pinned objects will be assigned to the elements in the array. See
        OCIObjectPin() for more information about pinning.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCICacheFlush (OCIEnv* env, OCIError* err, OCISvcCtx* svc, dvoid* context, OCIRef* function(dvoid* context, ub1* last) get, OCIRef** ref);
/*
   NAME: OCICacheFlush - OCI flush persistent objects
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                      recorded in 'err' and this function returns
                      OCI_ERROR.  The error recorded in 'err' can be
                      retrieved by calling OCIErrorGet().
        svc      (IN) [optional] - OCI service context.  If null pointer is
                      specified, then the dirty objects in all connections
                      will be flushed.
        context  (IN) [optional] - specifies an user context that is an
                      argument to the client callback function 'get'. This
                      parameter is set to NULL if there is no user context.
        get      (IN) [optional] - an client-defined function which acts an
                      iterator to retrieve a batch of dirty objects that need
                      to be flushed. If the function is not NULL, this function
                      will be called to get a reference of a dirty object.
                      This is repeated until a null reference is returned by
                      the client function or the parameter 'last' is set to
                      TRUE. The parameter 'context' is passed to get()
                      for each invocation of the client function.  This
                      parameter should be NULL if user callback is not given.
                      If the object that is returned by the client function is
                      not a dirtied persistent object, the object is ignored.
                      All the objects that are returned from the client
                      function must be from newed or pinned the same service
                      context, otherwise, an error is signalled. Note that the
                      returned objects are flushed in the order in which they
                      are marked dirty.
        ref     (OUT) [optional] - if there is an error in flushing the
                      objects, (*ref) will point to the object that
                      is causing the error.  If 'ref' is NULL, then the object
                      will not be returned.  If '*ref' is NULL, then a
                      reference will be allocated and set to point to the
                      object.  If '*ref' is not NULL, then the reference of
                      the object is copied into the given space. If the
                      error is not caused by any of the dirtied object,
                      the given ref is initalized to be a NULL reference
                      (OCIRefIsNull(*ref) is TRUE).
   REQUIRES:
        - a valid OCI environment handle must be given.
   DESCRIPTION:
        This function flushes the modified persistent objects from the
        environment heap to the server. The objects are flushed in the order
        that they are marked updated or deleted.

        See OCIObjectFlush() for more information about flushing.

   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCICacheRefresh (OCIEnv* env, OCIError* err, OCISvcCtx* svc, OCIRefreshOpt option, dvoid* context, OCIRef* function(dvoid* context) get, OCIRef** ref);
/*
   NAME: OCICacheRefresh - OCI ReFreSh persistent objects
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                       recorded in 'err' and this function returns
                       OCI_ERROR.  The error recorded in 'err' can be
                       retrieved by calling OCIErrorGet().
        svc     (IN) [optional] - OCI service context.  If null pointer is
                      specified, then the persistent objects in all connections
                      will be refreshed.
        option   (IN) [optional] - if OCI_REFRESH_LOAD is specified, all
                      objects that is loaded within the transaction are
                      refreshed. If the option is OCI_REFERSH_LOAD and the
                      parameter 'get' is not NULL, this function will ignore
                      the parameter.
        context  (IN) [optional] - specifies an user context that is an
                      argument to the client callback function 'get'. This
                      parameter is set to NULL if there is no user context.
        get      (IN) [optional] - an client-defined function which acts an
                      iterator to retrieve a batch of objects that need to be
                      refreshed. If the function is not NULL, this function
                      will be called to get a reference of an object.  If
                      the reference is not NULL, then the object will be
                      refreshed.  These steps are repeated until a null
                      reference is returned by this function.  The parameter
                      'context' is passed to get() for each invocation of the
                      client function.  This parameter should be NULL if user
                      callback is not given.
        ref     (OUT) [optional] - if there is an error in refreshing the
                      objects, (*ref) will point to the object that
                      is causing the error.  If 'ref' is NULL, then the object
                      will not be returned.  If '*ref' is NULL, then a
                      reference will be allocated and set to point to the
                      object.  If '*ref' is not NULL, then the reference of
                      the object is copied into the given space. If the
                      error is not caused by any of the object,
                      the given ref is initalized to be a NULL reference
                      (OCIRefIsNull(*ref) is TRUE).
   REQUIRES:
        - a valid OCI environment handle must be given.
   DESCRIPTION:
        This function refreshes all pinned persistent objects. All unpinned
        persistent objects are freed.  See OCIObjectRefresh() for more
        information about refreshing.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCICacheUnpin (OCIEnv* env, OCIError* err, OCISvcCtx* svc);
/*
   NAME: OCICacheUnpin - OCI UNPin objects
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                       recorded in 'err' and this function returns
                       OCI_ERROR.  The error recorded in 'err' can be
                       retrieved by calling OCIErrorGet().
        svc     (IN) [optional] - OCI service context. If null pointer is
                       specified, then the objects in all connections
                       will be unpinned.
   REQUIRES:
        - a valid OCI environment handle must be given.
   DESCRIPTION:
        If a connection is specified, this function completely unpins the
        persistent objects in that connection. Otherwise, all persistent
        objects in the heap are completely unpinned. All transient objects in
        the heap are also completely unpinned. See OCIObjectUnpin() for more
        information about unpinning.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCICacheFree (OCIEnv* env, OCIError* err, OCISvcCtx* svc);
/*
   NAME: OCICacheFree - OCI FREe instances
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                       recorded in 'err' and this function returns
                       OCI_ERROR.  The error recorded in 'err' can be
                       retrieved by calling OCIErrorGet().
        svc     (IN) [optional] - OCI service context. If null pointer is
                       specified, then the objects in all connections
                       will be freed.
   REQUIRES:
        - a valid OCI environment handle must be given.
   DESCRIPTION:
        If a connection is specified, this function frees the persistent
        objects, transient objects and values allocated for that connection.
        Otherwise, all persistent objects, transient objects and values in the
        heap are freed. Objects are freed regardless of their pin count.  See
        OCIObjectFree() for more information about freeing an instance.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
*/

extern (C) sword OCICacheUnmark (OCIEnv* env, OCIError* err, OCISvcCtx* svc);
/*
   NAME: OCICacheUnmark - OCI Unmark all dirty objects
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                       recorded in 'err' and this function returns
                       OCI_ERROR.  The error recorded in 'err' can be
                       retrieved by calling OCIErrorGet().
        svc     (IN) [optional] - OCI service context. If null pointer is
                       specified, then the objects in all connections
                       will be unmarked.
   REQUIRES:
        - a valid OCI environment handle must be given.
   DESCRIPTION:
        If a connection is specified, this function unmarks all dirty objects
        in that connection.  Otherwise, all dirty objects in the cache are
        unmarked. See OCIObjectUnmark() for more information about unmarking
        an object.
   RETURNS:
        if environment handle or error handle is null, return
        OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIDurationBegin (OCIEnv* env, OCIError* err, OCISvcCtx* svc, OCIDuration parent, OCIDuration* dur);
/*
   NAME: OCIDurationBegin - OCI DURATION BEGIN
   PARAMETERS:
        env  (IN/OUT) - OCI environment handle initialized in object mode
                        This should be passed NULL, when cartridge services
                        are to be used.
        err  (IN/OUT) - error handle. If there is an error, it is
                        recorded in 'err' and this function returns OCI_ERROR.
                        The error recorded in 'err' can be retrieved by calling
                       OCIErrorGet().
        svc  (IN/OUT) - OCI service handle.
        parent   (IN) - parent for the duration to be started.
        dur     (OUT) - newly created user duration
   REQUIRES:
        - a valid OCI environment handle must be given for non-cartridge
          services.
        - For cartridge services, NULL should be given for environment handle
        - A valid service handle must be given in all cases.
   DESCRIPTION:
        This function starts a new user duration.  A user can have multiple
        active user durations simultaneously. The user durations do not have
        to be nested.

        The object subsystem predefines 3 durations :
          1) session     - memory allocated with session duration comes from
                           the UGA heap (OCI_DURATION_SESSION). A session
                           duration terminates at the end of the user session.
          2) transaction - memory allocated with transaction duration comes
                           from the UGA heap (OCI_DURATION_TRANS). A trans-
                           action duration terminates at the end of the user
                           transaction.
          3) call        - memory allocated with call duration comes from PGA
                           heap (OCI_DURATION_CALL). A call duration terminates
                           at the end of the user call.

        Each user duration has a parent duration.  A parent duration can be a
        predefined duration or another user duration.  The relationship between
        a user duration and its parent duration (child duration) are:

         1) An user duration is nested within the parent duration. When its
             parent duration terminates, the user duration will also terminate.
         2) The memory allocated with an user duration comes from the heap of
             its parent duration. For example, if the parent duration of an
             user duration is call, then the memory allocated with the user
             duration will also come from the PGA heap.

        This function can be used as both part of cartridge services as well
        as without cartridge services.
        The difference in the function in the case of cartridge and
        non-cartridge services is:
                In case of cartridge services, as descibed above a new user
        duration is created as a child of the "parent" duration.
                But when used for non-cartridge purposes, when a pre-defined
        duration is passed in as parent, it is mapped to the cache duration
        for that connection (which is created if not already present) and
        the new user duration will be child of the cache duration.

   RETURNS:
        if environment handle and service handle is null or if error
        handle is null return OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

extern (C) sword OCIDurationEnd (OCIEnv* env, OCIError* err, OCISvcCtx* svc, OCIDuration duration);
/*
   NAME: OCIDurationEnd - OCI DURATION END
   PARAMETERS:
        env  (IN/OUT) - OCI environment handle initialized in object mode
                        This should be passed NULL, when cartridge services
                        are to be used.
        err  (IN/OUT) - error handle. If there is an error, it is
                        recorded in 'err' and this function returns OCI_ERROR.
                        The error recorded in 'err' can be retrieved by calling
                       OCIErrorGet().
        svc  (IN/OUT) - OCI service handle.
        dur     (OUT) - a previously created user duration using
                        OCIDurationBegin()
   REQUIRES:
        - a valid OCI environment handle must be given for non-cartridge
          services.
        - For cartridge services, NULL should be given for environment handle
        - A valid service handle must be given in all cases.
   DESCRIPTION:
        This function terminates a user duration.  All memory allocated for
        this duration is freed.

        This function can be used as both part of cartridge services as well
        as without cartridge services.  In both cased, the heap duration
        is freed and all the allocated memory for that duration is freed.
        The difference in the function in the case of cartridge and
        non-cartridge services is:
                In case of non-cartridge services, if the duration is pre-
        defined, the associated cache duration (see OCIDurationBegin())
        is also terminated and the following is done.
          1) The child durations are terminated.
          2) All objects pinned for this duration are unpinned.
          3) All instances allocated for this duration are freed.

                In case of cartridge services, only the heap duration is
        freed.  All the context entries allocated for that duration are
        freed from the context hash table..

   RETURNS:
        if environment handle and service handle is null or if error
        handle is null return OCI_INVALID_HANDLE.
        if operation suceeds, return OCI_SUCCESS.
        if operation fails, return OCI_ERROR.
 */

/**
 *
 */
deprecated extern (C) sword OCIDurationGetParent (OCIEnv* env, OCIError* err, OCIDuration duration, OCIDuration* parent);

/**
 *
 */
deprecated extern (C) sword OCIObjectAlwaysLatest (OCIEnv* env, OCIError* err, dvoid* object);

/**
 *
 */
deprecated extern (C) sword OCIObjectNotAlwaysLatest (OCIEnv* env, OCIError* err, dvoid* object);

/**
 *
 */
deprecated extern (C) sword OCIObjectFlushRefresh (OCIEnv* env, OCIError* err, dvoid* object);

/**
 *
 */
deprecated extern (C) sword OCIObjectIsLoaded (OCIEnv* env, OCIError* err, dvoid* ins, boolean* load);

/**
 *
 */
deprecated extern (C) sword OCIObjectIsDirtied (OCIEnv* env, OCIError* err, dvoid* ins, boolean* dirty);

/**
 *
 */
deprecated extern (C) sword OCICacheGetObjects (OCIEnv* env, OCIError* err, OCISvcCtx* svc, OCIObjectProperty property, dvoid* client_context, void function(dvoid* client_context, dvoid* object) client_callback);

/**
 *
 */
deprecated extern (C) sword OCICacheRegister (OCIEnv* env, OCIError* err, OCIObjectEvent event, dvoid* client_context, void function(dvoid* client_context, OCIObjectEvent event, dvoid* object) client_callback);

/**
 *
 */
deprecated extern (C) sword OCICacheFlushRefresh (OCIEnv* env, OCIError* err, OCISvcCtx* svc, dvoid* context, OCIRef* function(dvoid* context, ub1* last) get, OCIRef** ref);

/**
 *
 */
deprecated extern (C) sword OCIObjectSetData (OCIEnv* env, OCIError* err, dvoid* obj_hdr, dvoid* data);

/**
 *
 */
deprecated extern (C) sword OCIObjectGetNewOID(OCIEnv* env, OCIError* err, OCISvcCtx* svc, ub1* oid);