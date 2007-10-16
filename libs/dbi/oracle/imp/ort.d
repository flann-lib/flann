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
module dbi.oracle.imp.ort;

private import dbi.oracle.imp.oci, dbi.oracle.imp.oratypes, dbi.oracle.imp.oro;

/**
 * OCI Type Description
 *
 * The contents of an 'OCIType' is private/opaque to clients.  Clients just
 * need to declare and pass 'OCIType' pointers in to the type manage
 * functions.
 *
 * The pointer points to the type in the object cache.  Thus, clients don't
 * need to allocate space for this type and must never free the pointer to the
 * 'OCIType.'
 */
struct OCIType {
}

/**
 * OCI Type Element
 *
 * The contents of an 'OCITypeElem' is private/opaque to clients. Clients just
 * need to declare and pass 'OCITypeElem' pointers in to the type manager
 * functions.
 *
 * 'OCITypeElem' objects contains type element information such as the numeric
 * precision, for number objects, and the number of elements for arrays.
 *
 * These are used to describe type attributes, collection elements,
 * method parameters, and method results. Hence these are pass in or returned
 * by attribute, collection, and method parameter/result accessors.
 */
struct OCITypeElem {
}

/**
 * OCI Method Description
 *
 * The contents of an 'OCITypeMethod' is private/opaque to clients.  Clients
 * just need to declare and pass 'OCITypeMethod' pointers in to the type
 * manager functions.
 *
 * The pointer points to the method in the object cache.  Thus, clients don't
 * need to allocate space for this type and must never free the pointer to
 * the 'OCITypeMethod.'
 */
struct OCITypeMethod {
}

/**
 * OCI Type Iterator
 *
 * The contents of an 'OCITypeIter' is private/opaque to clients.  Clients
 * just need to declare and pass 'OCITypeIter' pointers in to the type
 * manager functions.
 *
 * The iterator is used to retreive MDO's and ADO's that belong to the TDO
 * one at a time.  It needs to be allocated by the 'OCITypeIterNew()' function
 * call and deallocated with the 'OCITypeIterFree()' function call.
 */
struct OCITypeIter {
}

/**
 * Create a new OCITypeIter.
 *
 * Deprecated:
 *	Unknown reason, but Oracle says so!
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	tdo = Pointer to the pinned type in the object cache to initialize the iterator with.
 *	iterator_ort = Pointer to the pointer to the new iterator.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
deprecated extern (C) sword OCITypeIterNew (OCIEnv* env, OCIError* err, OCIType* tdo, OCITypeIter** iterator_ort);

/**
 * Initialize a OCITypeIter.
 *
 * Deprecated:
 *	Unknown reason, but Oracle says so!
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	tdo = Pointer to the pinned type in the object cache to initialize the iterator with.
 *	iterator_ort = Pointer to the new iterator.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
deprecated extern (C) sword OCITypeIterSet (OCIEnv* env, OCIError* err, OCIType* tdo, OCITypeIter* iterator_ort);

/**
 * Free the space used by a OCITypeIter.
 *
 * Deprecated:
 *	Unknown reason, but Oracle says so!
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	iterator_ort = Pointer to the iterator.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
deprecated extern (C) sword OCITypeIterFree (OCIEnv* env, OCIError* err, OCITypeIter* iterator_ort);

/**
 * Get a type by name.
 *
 * The schema and type name are case sensitive.  If you made them with SQL, use uppercase letters.
 *
 * Deprecated:
 *	Unknown reason, but Oracle says so!
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	svc = OCI service handle.
 *	schema_name = Name of the schema associated with the type.  Defaults to the user's schema name.
 *	s_length = Length of schema_name.
 *	type_name = Name of the type to get.
 *	t_length = Length of type_name.
 *	version_name = User readable name of the version.  Use null for the most current version.
 *	v_length = Length of version_name.  Use 0 for the most current version.
 *	pin_duration = The pin duration.
 *	get_option = Options for loading the type.  See OCITypeGetOpt for details.
 *	tdo = Pointer to the pinned type in the object cache.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
deprecated extern (C) sword OCITypeByName (OCIEnv* env, OCIError* err, OCISvcCtx* svc, oratext* schema_name, ub4 s_length, oratext* type_name, ub4 t_length, oratext* version_name, ub4 v_length, OCIDuration pin_duration, OCITypeGetOpt get_option, OCIType** tdo);

/**
 * Get an array of types by name.
 *
 * The schema and type names are case sensitive.  If you made them with SQL, use uppercase letters.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	svc = OCI service handle.
 *	array_len = Number of entries to retrieve.
 *	schema_name = Names of the schemas associated with the type.  Must be null or of length array_len.  Defaults to the user's schema name.
 *	s_length = Length of each element of schema_name.  Must be null or of length array_len.  Use 0 for null values.
 *	type_name = Names of the types to get.  Must be of length array_len.
 *	t_length = Length of each element of type_name.  Must be of length array_len.
 *	version_name = User readable names of the versions.  Must be null or of length array_len.  Use null for the most current version.
 *	v_length = Length of each element of version_name.  Use 0 for null values.
 *	pin_duration = The pin duration.
 *	get_option = Options for loading the type.  See OCITypeGetOpt for details.
 *	tdo = Pointer to memory allocated for the pinned type in the object cache.  It must have space for array_len pointers.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCITypeArrayByName (OCIEnv* env, OCIError* err, OCISvcCtx* svc, ub4 array_len, oratext*[] schema_name, ub4[] s_length, oratext*[] type_name, ub4[] t_length, oratext*[] version_name, ub4[] v_length, OCIDuration pin_duration, OCITypeGetOpt get_option, OCIType** tdo);

/**
 * Get a type by reference.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	type_ref = Reference to the type.
 *	pin_duration = The pin duration.
 *	get_option = Options for loading the type.  See OCITypeGetOpt for details.
 *	tdo = Pointer to the pinned type in the object cache.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCITypeByRef (OCIEnv* env, OCIError* err, OCIRef* type_ref, OCIDuration pin_duration, OCITypeGetOpt get_option, OCIType** tdo);

/**
 * Get an array of types by reference.
 *
 * Params:
 *	env = OCI environment handle initialized in object mode.
 *	err = OCI error handle.
 *	array_len = Number of entries to retrieve.
 *	type_ref = References to the types to get.  Must be of length array_len.
 *	pin_duration = The pin duration.
 *	get_option = Options for loading the type.  See OCITypeGetOpt for details.
 *	tdo = Pointer to memory allocated for the pinned type in the object cache.  It must have space for array_len pointers.
 *
 * Returns:
 *	OCI_SUCCESS on success, OCI_INVALID_HANDLE on invalid parameters, or OCI_ERROR on error.
 */
extern (C) sword OCITypeArrayByRef (OCIEnv* env, OCIError* err, ub4 array_len, OCIRef** type_ref, OCIDuration pin_duration, OCITypeGetOpt get_option, OCIType** tdo);






























deprecated extern (C) oratext* OCITypeName (OCIEnv* env, OCIError* err, OCIType* tdo, ub4* n_length);
/*
   NAME: OCITypeName -  ORT Get a Type's naME.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
        n_length (OUT) - length (in bytes) of the returned type name.  The
               caller must allocate space for the ub4 before calling this
               routine.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
        3) 'n_length' must point to an allocated ub4.
   DESCRIPTION:
        Get the name of the type.
   RETURNS:
        the name of the type
   NOTES:
        The type descriptor, 'tdo', must be unpinned when the accessed
        information is no longer needed.
 */


deprecated extern (C) oratext* OCITypeSchema (OCIEnv* env, OCIError* err, OCIType* tdo, ub4* n_length);
/*
   NAME: OCITypeSchema -  ORT Get a Type's SCHema name.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
        n_length (OUT) - length (in bytes) of the returned schema name.  The
               caller must allocate space for the ub4 before calling this
               routine.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
        3) 'n_length' must point to an allocated ub4.
   DESCRIPTION:
        Get the schema name of the type.
   RETURNS:
        the schema name of the type
   NOTES:
        The type descriptor, 'tdo', must be unpinned when the accessed
        information is no longer needed.
 */


deprecated extern (C) OCITypeCode OCITypeTypeCode (OCIEnv* env, OCIError* err, OCIType* tdo);
/*
   NAME: OCITypeTypeCode - OCI Get a Type's Type Code.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the type code of the type.
   RETURNS:
        The type code of the type.
   NOTES:
        The type descriptor, 'tdo', must be unpinned when the accessed
        information is no longer needed.
 */


deprecated extern (C) OCITypeCode OCITypeCollTypeCode (OCIEnv* env, OCIError* err, OCIType* tdo);
/*
   NAME: OCITypeCollTypeCode - OCI Get a Domain Type's Type Code.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
        3) 'tdo' MUST point to a named collection type.
   DESCRIPTION:
        Get the type code of the named collection type. For V8.0, named
        collection types can only be variable length arrays and nested tables.
   RETURNS:
        OCI_TYPECODE_VARRAY for variable length array, and
        OCI_TYPECODE_TABLE for nested tables.
   NOTES:
        The type descriptor, 'tdo', should be unpinned when the accessed
        information is no longer needed.
 */


deprecated extern (C) oratext* OCITypeVersion (OCIEnv* env, OCIError* err, OCIType* tdo, ub4* v_length);
/*
   NAME: OCITypeVersion - OCI Get a Type's user-readable VersioN.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
        v_length (OUT) - length (in bytes) of the returned user-readable
               version.  The caller must allocate space for the ub4 before
               calling this routine.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
        3) 'v_length' must point to an allocated ub4.
   DESCRIPTION:
        Get the user-readable version of the type.
   RETURNS:
        The user-readable version of the type
   NOTES:
        The type descriptor, 'tdo', must be unpinned when the accessed
        information is no longer needed.
 */


deprecated extern (C) ub4 OCITypeAttrs (OCIEnv* env, OCIError* err, OCIType* tdo);
/*
   NAME: OCITypeAttrs - OCI Get a Type's Number of Attributes.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the number of attributes in the type.
   RETURNS:
        The number of attributes in the type. 0 for ALL non-ADTs.
   NOTES:
        The type descriptor, 'tdo', must be unpinned when the accessed
        information is no longer needed.
 */


deprecated extern (C) ub4 OCITypeMethods (OCIEnv* env, OCIError* err, OCIType* tdo);
/*
   NAME: OCITypeMethods - OCI Get a Type's Number of Methods.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the number of methods in a type.
   RETURNS:
        The number of methods in the type
   NOTES:
        The type descriptor, 'tdo', must be unpinned when the accessed
        information is no longer needed.
 */


deprecated extern (C) oratext* OCITypeElemName (OCIEnv* env, OCIError* err, OCITypeElem* elem, ub4 n_length);
/*
   NAME: OCITypeElemName - OCI Get an Attribute's NaMe.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the type element descriptor in the object cache
        n_length (OUT) - length (in bytes) of the returned attribute name.
               The caller must allocate space for the ub4 before calling this
               routine.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
        3) 'n_length' must point to an allocated ub4.
   DESCRIPTION:
        Get the name of the attribute.
   RETURNS:
        the name of the attribute and the length in n_length
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) OCITypeCode OCITypeElemTypeCode (OCIEnv* env, OCIError* err, OCITypeElem* elem);
/*
   NAME: OCITypeElemTypeCode - OCI Get an Attribute's TypeCode.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the type element descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the typecode of an attribute's type.
   RETURNS:
        the typecode of the attribute's type.  If this is a scalar type, the
        typecode sufficiently describes the scalar type and no further calls
        need to be made.  Valid scalar types include: OCI_TYPECODE_SIGNED8,
        OCI_TYPECODE_UNSIGNED8, OCI_TYPECODE_SIGNED16, OCI_TYPECODE_UNSIGNED16,
        OCI_TYPECODE_SIGNED32, OCI_TYPECODE_UNSIGNED32, OCI_TYPECODE_REAL,
        OCI_TYPECODE_DOUBLE, OCI_TYPECODE_DATE,
        OCI_TYPECODE_MLSLABEL, OROTCOID, OCI_TYPECODE_OCTET, or OROTCLOB.
        This function converts the CREF (stored in the attribute) into a
        typecode.
   NOTES:
       The type must be unpinned when the accessed information is no
       longer needed.
 */


deprecated extern (C) sword OCITypeElemType (OCIEnv* env, OCIError* err, OCITypeElem* elem, OCIType** elem_tdo);
/*
  PARAMETERS
     env (IN/OUT) - OCI environment handle initialized in object mode
     err (IN/OUT) - error handle. If there is an error, it is
             recorded in 'err' and this function returns OCI_ERROR.
             The error recorded in 'err' can be retrieved by calling
             OCIErrorGet().
     elem (IN) - pointer to the type element descriptor in the object cache
     elem_tdo (OUT) - If the function completes successfully, 'elem_tdo'
            points to the type descriptor (in the object cache) of the type of
            the element.

  REQUIRES
     1) All type accessors require that the type be pinned before calling
        any accessor.  This can be done by calling 'OCITypeByName()'.
     2) if 'elem' is not null, it must point to a valid type element descriptor
        in the object cache.

  DESCRIPTION
     Get the type tdo of the type of this element.
  RETURNS
     OCI_SUCCESS if the function completes successfully.
     OCI_INVALID_HANDLE if 'env' or 'err' is null.
     OCI_ERROR if
         1) any of the parameters is null.

  NOTES
     The type must be unpinned when the accessed information is no
     longer needed.  This can be done by calling 'OCIObjectUnpin()'.
 */


deprecated extern (C) ub4 OCITypeElemFlags (OCIEnv* env, OCIError* err, OCITypeElem* elem);
/*
   NAME: OCITypeElemFlags - OCI Get a Elem's FLags
                              (inline, constant, virtual, constructor,
                              destructor).
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the type element descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the flags of a type element (attribute, parameter).
   RETURNS:
        The flags of the type element.
   NOTES:
        The flag bits are not externally documented. Use only the macros
        in the last section (ie. OCI_TYPEPARAM_IS_REQUIRED, and
        OCI_TYPEELEM_IS_REF) to test for them only. The type must be unpinned
        when the accessed information is no longer needed.
 */


deprecated extern (C) ub1 OCITypeElemNumPrec (OCIEnv* env, OCIError* err, OCITypeElem* elem);
/*
   NAME: OCITypeElemNumPrec - Get a Number's Precision.  This includes float,
                              decimal, real, double, and oracle number.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the type element descriptor in the object cache
   REQUIRES:
        All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the precision of a float, decimal, long, unsigned long, real,
        double, or Oracle number type.
   RETURNS:
        the precision of the float, decimal, long, unsigned long, real, double,
        or Oracle number
 */


deprecated extern (C) sb1 OCITypeElemNumScale (OCIEnv* env, OCIError* err, OCITypeElem* elem);
/*
   NAME: OCITypeElemNumScale - Get a decimal or oracle Number's Scale
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the type element descriptor in the object cache
   REQUIRES:
        All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the scale of a decimal, or Oracle number type.
   RETURNS:
        the scale of the decimal, or Oracle number
 */


deprecated extern (C) ub4 OCITypeElemLength (OCIEnv* env, OCIError* err, OCITypeElem* elem);
/*
   NAME: OCITypeElemLength - Get a raw, fixed or variable length String's
                             length in bytes.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the type element descriptor in the object cache
   REQUIRES:
        All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the length of a raw, fixed or variable length string type.
   RETURNS:
        length of the raw, fixed or variable length string
 */


deprecated extern (C) ub2 OCITypeElemCharSetID (OCIEnv* env, OCIError* err, OCITypeElem* elem);
/*
   NAME: OCITypeElemCharSetID - Get a fixed or variable length String's
                                character set ID
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the type element descriptor in the object cache
   REQUIRES:
        All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the character set ID of a fixed or variable length string type.
   RETURNS:
        character set ID of the fixed or variable length string
 */


deprecated extern (C) ub2 OCITypeElemCharSetForm (OCIEnv* env, OCIError* err, OCITypeElem* elem);
/*
   NAME: OCITypeElemCharSetForm - Get a fixed or variable length String's
                                  character set specification form.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the attribute information in the object cache
   REQUIRES:
        All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the character form of a fixed or variable length string type.
        The character form is an enumerated value that can be one of the
        4 values below:
               SQLCS_IMPLICIT for CHAR, VARCHAR2, CLOB w/o a specified set
               SQLCS_NCHAR    for NCHAR, NCHAR VARYING, NCLOB
               SQLCS_EXPLICIT for CHAR, etc, with "CHARACTER SET ..." syntax
               SQLCS_FLEXIBLE for PL/SQL "flexible" parameters
   RETURNS:
        character form of the fixed or variable string
 */


deprecated extern (C) sword OCITypeElemParameterizedType (OCIEnv* env, OCIError* err, OCITypeElem* elem, OCIType** type_stored);
/*
   NAME: OCITypeElemParameterizedType
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the type element descriptor in the object cache
        type_stored (OUT) - If the function completes successfully,
               and the parameterized type is complex, 'type_stored' is NULL.
               Otherwise, 'type_stored' points to the type descriptor (in the
               object cache) of the type that is stored in the parameterized
               type.  The caller must allocate space for the OCIType*
               before calling this routine and must not write into the space.
   REQUIRES:
        All input parameters must be valid.
   DESCRIPTION:
        Get a descriptor to the parameter type of a parameterized type.
        Parameterized types are types of the form:
          REF T
          VARRAY (n) OF T
        etc, where T is the parameter in the parameterized type.
        Additionally is_ref is set if the parameter is a PTR or REF.
        For example, it is set for REF T or VARRAY(n) OF REF T.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the parameters is null.
            2) 'type_stored' is not NULL but points to NULL data.
   NOTES:
        Complex parameterized types will be in a future release (once
        typedefs are supported.  When setting the parameterized type
        information, the user must typedef the contents if it's a
        complex parameterized type.  Ex. for varray<varray<car>>, use
        'typedef varray<car> varcar' and then use varray<varcar>.
 */


deprecated extern (C) OCITypeCode OCITypeElemExtTypeCode (OCIEnv* env, OCIError* err, OCITypeElem* elem);
/*
   NAME: OCITypeElemExtTypeCode - OCI Get an element's SQLT constant.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the type element descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the internal Oracle typecode associated with an attribute's type.
        This is the actual typecode for the attribute when it gets mapped
        to a column in the Oracle database.
   RETURNS:
        The Oracle typecode associated with the attribute's type.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) sword OCITypeAttrByName (OCIEnv* env, OCIError* err, OCIType* tdo, oratext* name, ub4 n_length, OCITypeElem** elem);
/*
   NAME: OCITypeAttrByName - OCI Get an Attribute By Name.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
        name (IN) - the attribute's name
        n_length (IN) - length (in bytes) of the 'name' parameter
        elem (OUT) - If this function completes successfully, 'elem' points to
               the selected type element descriptor pertaining to the
               attributein the object cache.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) if 'tdo' is not null, it must point to a valid type descriptor
           in the object cache.
   DESCRIPTION:
        Get an attribute given its name.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the required parameters is null.
            2) the type does not contain an attribute with the input 'name'.
            3) 'name' is NULL.
   NOTES:
        The type descriptor, 'tdo', must be unpinned when the accessed
        information is no longer needed.
        Schema and type names are CASE-SENSITIVE. If they have been created
        via SQL, you need to use uppercase names.
 */


deprecated extern (C) sword OCITypeAttrNext (OCIEnv* env, OCIError* err, OCITypeIter* iterator_ort, OCITypeElem** elem);
/*
   NAME: OCITypeAttrNext - OCI Get an Attribute By Iteration.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        iterator_ort (IN/OUT) - iterator for retrieving the next attribute;
               see OCITypeIterNew() to initialize iterator.
        elem (OUT) - If this function completes successfully, 'elem' points to
               the selected type element descriptor pertaining to the
               attributein the object cache.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
            any accessor.
        2) if 'tdo' is not null, it must point to a valid type descriptor
           in the object cache.
   DESCRIPTION:
        Iterate to the next attribute to retrieve.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_NO_DATA if there are no more attributes to iterate on; use
            OCITypeIterSet() to reset the iterator if necessary.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the required parameters is null.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) sword OCITypeCollElem (OCIEnv* env, OCIError* err, OCIType* tdo, OCITypeElem** element);
/*
   NAME: OCITypeCollElem
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to the type descriptor in the object cache
        element (IN/OUT) - If the function completes successfully, this
               points to the descriptor for the collection's element.
               It is stored in the same format as an ADT attribute's
               descriptor.
               If *element is NULL, OCITypeCollElem() implicitly allocates a
               new instance of OCITypeElem in the object cache. This instance
               will be
               automatically freed at the end of the session, and does not have
               to be freed explicitly.
               If *element is not NULL, OCITypeCollElem() assumes that it
               points to a valid OCITypeElem descriptor and will copy the
               results into it.
   REQUIRES:
        All input parameters must be valid.
   DESCRIPTION:
        Get a pointer to the descriptor (OCITypeElem) of the element of an
        array or the rowtype of a nested table.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the parameters is null.
            2) the type TDO does not point to a valid collection's type.
   NOTES:
        Complex parameterized types will be in a future release (once
        typedefs are supported.  When setting the parameterized type
        information, the user must typedef the contents if it's a
        complex parameterized type.  Ex. for varray<varray<car>>, use
        'typedef varray<car> varcar' and then use varray<varcar>.
 */


deprecated extern (C) sword OCITypeCollSize (OCIEnv* env, OCIError* err, OCIType* tdo, ub4* num_elems);
/*
   NAME: OCITypeCollSize - OCI Get a Collection's Number of Elements.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to the type descriptor in the object cache
        num_elems (OUT) - number of elements in collection
   REQUIRES:
        All input parameters must be valid. tdo points to an array type
        defined as a domain.
   DESCRIPTION:
        Get the number of elements stored in a fixed array or the maximum
        number of elements in a variable array.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the parameters is null.
            2) 'tdo' does not point to a domain with a collection type.
   NOTES:
        Complex parameterized types will be in a future release (once
        typedefs are supported.  When setting the parameterized type
        information, the user must typedef the contents if it's a
        complex parameterized type.  Ex. for varray<varray<car>>, use
        'typedef varray<car> varcar' and then use varray<varcar>.
 */


extern (C) sword OCITypeCollExtTypeCode (OCIEnv* env, OCIError* err, OCIType* tdo, OCITypeCode* sqt_code);
/*
   NAME: ortcsqt - OCI Get a Collection element's DTY constant.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to the type descriptor in the object cache
        sqt_code (OUT) - SQLT code of type element.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the SQLT constant associated with an domain's element type.
        The SQLT codes are defined in <sqldef.h> and are needed for OCI/OOCI
        use.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the parameters is null.
            2) 'tdo' does not point to a domain with a collection type.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) ub4 OCITypeMethodOverload (OCIEnv* env, OCIError* err, OCIType* tdo, oratext method_name, ub4 m_length);
/*
   NAME: OCITypeMethodOverload - OCI Get type's Number of Overloaded names
                                 for the given method name.
   PARAMETERS:
        gp (IN/OUT) - pga environment handle.  Any errors are recorded here.
        tdo (IN) - pointer to to the type descriptor in the object cache
        method_name (IN) - the method's name
        m_length (IN) - length (in bytes) of the 'method_name' parameter
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) if 'tdo' is not null, it must point to a valid type descriptor
           in the object cache.
   DESCRIPTION:
        Overloading of methods implies that more than one method may have the
        same method name.  This routine returns the number of methods that
        have the given method name.  If there are no methods with the input
        method name, 'num_methods' is 0.  The caller uses this information when
        allocating space for the array of mdo and/or position pointers before
        calling 'OCITypeMethodByName()' or 'ortgmps()'.
   RETURNS:
        The number of methods with the given name. 0 if none contains the
        name.
   NOTES:
        Schema and type names are CASE-SENSITIVE. If they have been created
        via SQL, you need to use uppercase names.
 */


deprecated extern (C) sword OCITypeMethodByName (OCIEnv* env, OCIError* err, OCIType* tdo, oratext* method_name, ub4 m_length, OCITypeMethod** mdos);
/*
   NAME: OCITypeMethodByName - OCI Get one or more Methods with Name.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
        method_name (IN) - the methods' name
        m_length (IN) - length (in bytes) of the 'name' parameter
        mdos (OUT) - If this function completes successfully, 'mdos' points to
                the selected methods in the object cache.  The caller must
                allocate space for the array of OCITypeMethod pointers before
                calling this routine and must not write into the space.
                The number of OCITypeMethod pointers that will be returned can
                be obtained by calling 'OCITypeMethodOverload()'.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) if 'tdo' is not null, it must point to a valid type descriptor
           in the object cache.
   DESCRIPTION:
        Get one or more methods given the name.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the required parameters is null.
            2) No methods in type has name 'name'.
            3) 'mdos' is not NULL but points to NULL data.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
        Schema and type names are CASE-SENSITIVE. If they have been created
        via SQL, you need to use uppercase names.
 */


deprecated extern (C) sword OCITypeMethodNext (OCIEnv* env, OCIError* err, OCITypeIter* iterator_ort, OCITypeMethod** mdo);
/*
   NAME: OCITypeMethodNext - OCI Get a Method By Iteration.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        iterator_ort (IN/OUT) - iterator for retrieving the next method;
               see OCITypeIterNew() to set iterator.
        mdo (OUT) - If this function completes successfully, 'mdo' points to
               the selected method descriptor in the object cache.  Positions
               start at 1.  The caller must allocate space for the
               OCITypeMethod* before calling this routine and must not write
               nto the space.
   REQUIRES:
         1) All type accessors require that the type be pinned before calling
            any accessor.
        2) if 'tdo' is not null, it must point to a valid type descriptor
           in the object cache.
   DESCRIPTION:
        Iterate to the next method to retrieve.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_NO_DATA if there are no more attributes to iterate on; use
            OCITypeIterSet() to reset the iterator if necessary.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the required parameters is null.
            2) 'mdo' is not NULL but points to NULL data.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) oratext* OCITypeMethodName (OCIEnv* env, OCIError* err, OCITypeMethod* mdo, ub4* n_length);
/*
   NAME: OCITypeMethodName - OCI Get a Method's NaMe.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        mdo (IN) - pointer to the method descriptor in the object cache
        n_length (OUT) - length (in bytes) of the 'name' parameter.  The caller
               must allocate space for the ub4 before calling this routine.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the (non-unique) real name of the method.
   RETURNS:
        the non-unique name of the method or NULL if there is an error.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) OCITypeEncap OCITypeMethodEncap (OCIEnv* env, OCIError* err, OCITypeMethod* mdo);
/*
   NAME: OCITypeMethodEncap - Get a Method's ENcapsulation (private/public).
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        mdo (IN) - pointer to the method descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the encapsulation (private, or public) of a method.
   RETURNS:
        the encapsulation (private, or public) of the method
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) OCITypeMethodFlag OCITypeMethodFlags (OCIEnv* env, OCIError* err, OCITypeMethod* mdo);
/*
   NAME: OCITypeMethodFlags - OCI Get a Method's FLags
                              (inline, constant, virtual, constructor,
                              destructor).
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        mdo (IN) - pointer to the method descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the flags (inline, constant, virutal, constructor, destructor) of
        a method.
   RETURNS:
        the flags (inline, constant, virutal, constructor, destructor) of
        the method
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) sword OCITypeMethodMap (OCIEnv* env, OCIError* err, OCIType* tdo, OCITypeMethod** mdo);
/*
   NAME: OCITypeMethodMap - OCI Get the Method's MAP function.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
        mdo (OUT) - If this function completes successfully, and there is a
               map function for this type, 'mdo' points to the selected method
               descriptor in the object cache.  Otherwise, 'mdo' is null.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All required input parameters must not be NULL and must be valid.
   DESCRIPTION:
        A type may have only one map function.  'OCITypeMethodMap()' finds
        this function, if it exists, and returns a reference and a pointer to
        the method descriptor in the object cache.  If the type does not have a
        map (relative ordering) function, then 'mdo_ref' and 'mdo' are set
        to null and an error is returned.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            the type does not contain a map function.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) sword OCITypeMethodOrder (OCIEnv* env, OCIError* err, OCIType* tdo, OCITypeMethod ** mdo);
/*
   NAME: OCITypeMethodOrder - OCI Get the Method's ORder function.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        tdo (IN) - pointer to to the type descriptor in the object cache
        mdo (OUT) - If this function completes successfully, and there is a
               map function for this type, 'mdo' points to the selected method
               descriptor in the object cache.  Otherwise, 'mdo' is null.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All required input parameters must not be NULL and must be valid.
   DESCRIPTION:
        A type may have only one ORder or MAP function. 'OCITypeMethodOrder()'
        finds this function, if it exists, and returns a ref and a pointer
        to the method descriptor in the object cache.  If the type does not
        have a map (relative ordering) function, then 'mdo_ref' and 'mdo' are
        set to null and an error is returned.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            the type does not contain a map function.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) ub4 OCITypeMethodParams (OCIEnv* env, OCIError* err, OCITypeMethod* mdo);
/*
   NAME: OCITypeMethodParams - OCI Get a Method's Number of Parameters.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        mdo (IN) - pointer to the method descriptor in the object cache
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the number of parameters in a method.
   RETURNS:
        the number of parameters in the method
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) sword OCITypeResult (OCIEnv* env, OCIError* err, OCITypeMethod* mdo, OCITypeElem ** elem);
/*
   NAME: OCITypeResult - OCI Get a method's result type descriptor.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        mdo (IN) - pointer to the method descriptor in the object cache
        elem (OUT) - If this function completes successfully, 'rdo' points to
               the selected result (parameter) descriptor in the object cache.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) 'elem' MUST be the address of an OCITypeElem pointer.
   DESCRIPTION:
        Get the result of a method.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the required parameters is null.
            2) method returns no results.
   NOTES:
        The method must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) sword OCITypeParamByPos (OCIEnv* env, OCIError* err, OCITypeMethod* mdo, ub4 position, OCITypeElem** elem);
/*
   NAME: OCITypeParamByPos - OCI Get a Parameter in a method By Position.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        mdo (IN) - pointer to the method descriptor in the object cache
        position (IN) - the parameter's position.  Positions start at 1.
        elem (OUT) - If this function completes successfully, 'elem' points to
               the selected parameter descriptor in the object cache.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
   DESCRIPTION:
        Get a parameter given its position in the method.  Positions start
        at 1.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the required parameters is null.
            2) 'position' is not >= 1 and <= the number of parameters in the
               method.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) sword OCITypeParamByName (OCIEnv* env, OCIError* err, OCITypeMethod* mdo, oratext* name, ub4 n_length, OCITypeElem** elem);
/*
   NAME: OCITypeParamByName - OCI Get a Parameter in a method By Name.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        mdo (IN) - pointer to the method descriptor in the object cache
        name (IN) - the parameter's name
        n_length (IN) - length (in bytes) of the 'name' parameter
        elem (OUT) - If this function completes successfully, 'elem' points to
               the selected parameter descriptor in the object cache.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) if 'mdo' is not null, it must point to a valid method descriptor
           in the object cache.
   DESCRIPTION:
        Get a parameter given its name.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the required parameters is null.
            2) the method does not contain a parameter with the input 'name'.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) sword OCITypeParamPos (OCIEnv* env, OCIError* err, OCITypeMethod* mdo, oratext* name, ub4 n_length, ub4* position, OCITypeElem** elem);
/*
   NAME: OCITypeParamPos - OCI Get a parameter's position in a method
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        mdo (IN) - pointer to the method descriptor in the object cache
        name (IN) - the parameter's name
        n_length (IN) - length (in bytes) of the 'name' parameter
        position (OUT) - If this function completes successfully, 'position'
               points to the position of the parameter in the method starting
               at position 1. position MUST point to space for a ub4.
        elem (OUT) - If this function completes successfully, and
               the input 'elem' is not NULL, 'elem' points to the selected
               parameter descriptor in the object cache.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) if 'mdo' is not null, it must point to a valid method descriptor
           in the object cache.
   DESCRIPTION:
        Get the position of a parameter in a method.  Positions start at 1.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the parameters is null.
            2) the method does not contain a parameter with the input 'name'.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) OCITypeParamMode OCITypeElemParamMode (OCIEnv* env, OCIError* err, OCITypeElem* elem);
/*
   NAME: OCITypeElemParamMode - OCI Get a parameter's mode
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the parameter descriptor in the object cache
                (represented by an OCITypeElem)
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the mode (in, out, or in/out) of the parameter.
   RETURNS:
        the mode (in, out, or in/out) of the parameter
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) oratext* OCITypeElemDefaultValue (OCIEnv* env, OCIError* err, OCITypeElem* elem, ub4* d_v_length);
/*
   NAME: OCITypeElemDefaultValue - OCI Get the element's Default Value.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        elem (IN) - pointer to the parameter descriptor in the object cache
                (represented by an OCITypeElem)
        d_v_length (OUT) - length (in bytes) of the returned default value.
               The caller must allocate space for the ub4 before calling this
               routine.
   REQUIRES:
        1) All type accessors require that the type be pinned before calling
           any accessor.
        2) All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Get the default value in text form (PL/SQL) of an element. For V8.0,
        this only makes sense for a method parameter.
   RETURNS:
        The default value (text) of the parameter.
   NOTES:
        The type must be unpinned when the accessed information is no
        longer needed.
 */


deprecated extern (C) sword OCITypeVTInit (OCIEnv* env, OCIError* err);
/*
   NAME: OCITypeVTInit - OCI type Version table INItialize
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
   REQUIRES:
        none
   DESCRIPTION:
        Allocate space for and initialize the type version table and the type
        version table's index.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if internal errors occurrs during initialization.
 */


deprecated extern (C) sword OCITypeVTInsert (OCIEnv* env, OCIError* err, oratext* schema_name, ub4 s_n_length, oratext* type_name, ub4 t_n_length, oratext* user_version, ub4 u_v_length);
/*
   NAME: OCITypeVTInsert - OCI type Version table INSert entry.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        schema_name (IN, optional) - name of schema associated with the
                  type.  By default, the user's schema name is used.
        s_n_length (IN) - length of the 'schema_name' parameter
        type_name (IN) - type name to insert
        t_n_length (IN) - length (in bytes) of the 'type_name' parameter
        user_version (IN) - user readable version of the type
        u_v_length (IN) - length (in bytes) of the 'user_version' parameter
   REQUIRES:
        none
   DESCRIPTION:
        Insert an entry into the type version table and the type version
        table's index.  The entry's type name and user readable version
        fields are updated with the input values.  All other fields are
        initialized to null.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the parameters is invalid.
            2) an entry for 'type_name' has already been registered in the
               type version table.
 */


deprecated extern (C) sword OCITypeVTSelect (OCIEnv* env, OCIError* err, oratext* schema_name, ub4 s_n_length, oratext* type_name, ub4 t_n_length, oratext** user_version, ub4* u_v_length, ub2* s_version);
/*
   NAME: OCITypeVTSelect - OCI type Version table SELect entry.
   PARAMETERS:
        env (IN/OUT) - OCI environment handle initialized in object mode
        err (IN/OUT) - error handle. If there is an error, it is
                recorded in 'err' and this function returns OCI_ERROR.
                The error recorded in 'err' can be retrieved by calling
                OCIErrorGet().
        schema_name (IN, optional) - name of schema associated with the
                  type.  By default, the user's schema name is used.
        s_n_length (IN) - length of the 'schema_name' parameter
        type_name (IN) - type name to select
        t_n_length (IN) - length (in bytes) of the 'type_name' parameter
        user_version (OUT, optional) - pointer to user readable version of the
                 type
        u_v_length (OUT, optional) - length (in bytes) of the 'user_version'
                 parameter
        version (OUT, optional) - internal type version
   REQUIRES:
        All input parameters must not be NULL and must be valid.
   DESCRIPTION:
        Select an entry in the type version table by name.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_INVALID_HANDLE if 'env' or 'err' is null.
        OCI_ERROR if
            1) any of the parameters is invalid.
            2) an entry with 'type_name' does not exist.
 */


deprecated extern (C) sword ortgcty (OCIEnv* env, OCIError* err, OCIType* coll_tdo, OCIType** collelem_tdo);


extern (C) sword OCITypeBeginCreate (OCISvcCtx* svchp, OCIError* errhp, OCITypeCode tc, OCIDuration dur, OCIType** type);
/*
   NAME: OCITypeBeginCreate - OCI Type Begin Creation of a transient type.
   REMARKS
       Begins the construction process for a transient type. The type will be
       anonymous (no name). To create a persistent named type, the CREATE TYPE
       statement should be used from SQL. Transient types have no identity.
       They are pure values.
   PARAMETERS:
       svchp (IN)       - The OCI Service Context.
       errhp (IN/OUT)   - The OCI error handle. If there is an error, it is
                          recorded in errhp and this function returns
                          OCI_ERROR. Diagnostic information can be obtained by
                          calling OCIErrorGet().
       tc               - The TypeCode for the type. The Typecode could
                          correspond to a User Defined Type or a Built-in type.
                          Currently, the permissible values for User Defined
                          Types are OCI_TYPECODE_OBJECT for an Object Type
                          (structured), OCI_TYPECODE_VARRAY for a VARRAY
                          collection type or OCI_TYPECODE_TABLE for a nested
                          table collection type. For Object types,
                          OCITypeAddAttr() needs to be called to add each of
                          the attribute types. For Collection types,
                          OCITypeSetCollection() needs to be called.
                          Subsequently, OCITypeEndCreate() needs to be called
                          to finish the creation process.
                          The permissible values for Built-in type codes are
                          specified in the user manual. Additional information
                          on built-ins if any (like precision, scale for
                          numbers, character set info for VARCHAR2s etc.) must
                          be set with a subsequent call to OCITypeSetBuiltin().
                          Subsequently OCITypeEndCreate() needs to be called
                          to finish the creation process.
       dur              - The allocation duration for the Type. Could be a
                          predefined or a user defined duration.
       type(OUT)        - The OCIType (Type Descriptor) that is being
                          constructed.
  RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_ERROR on error.
*/


extern (C) sword OCITypeSetCollection (OCISvcCtx* svchp, OCIError* errhp, OCIType* type, OCIParam* collelem_info, ub4 coll_count);
/*
   NAME: OCITypeSetCollection - OCI Type Set Collection information
   REMARKS :
       Set Collection type information. This call can be called only if the
       OCIType has been constructed with a collection typecode.
   PARAMETERS:
       svchp (IN)      -  The OCI Service Context.
       errhp (IN/OUT)  -  The OCI error handle. If there is an error, it is
                          recorded in errhp and this function returns
                          OCI_ERROR. Diagnostic information can be obtained by
                          calling OCIErrorGet().
       type(IN OUT)    -  The OCIType (Type Descriptor) that is being
                          constructed.
       collelem_info   -  collelem_info provides information on the collection
                          element. It is obtained by allocating an OCIParam
                          (parameter handle) and setting type information in
                          the OCIParam using OCIAttrSet() calls.
       coll_count      -  The count of elements in the collection. Pass 0 for
                          a nested table (unbounded).
  RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_ERROR on error.
*/


extern (C) sword OCITypeSetBuiltin (OCISvcCtx* svchp, OCIError* errhp, OCIType* type, OCIParam* builtin_info);
/*
   NAME: OCITypeSetBuiltin - OCI Type Set Builtin information.
   REMARKS:
       Set Built-in type information. This call can be called only if the
       OCIType has been constructed with a built-in typecode
       (OCI_TYPECODE_NUMBER etc.).
   PARAMETERS:
       svchp (IN)       - The OCI Service Context.
       errhp (IN/OUT)   - The OCI error handle. If there is an error, it is
                          recorded in errhp and this function returns
                          OCI_ERROR. Diagnostic information can be obtained by
                          calling OCIErrorGet().
       type(IN OUT)     - The OCIType (Type Descriptor) that is being
                          constructed.
       builtin_info     - builtin_info provides information on the built-in
                          (like precision, scale, charater set etc.). It is
                          obtained by allocating an OCIParam (parameter handle)
                          and setting type information in the OCIParam using
                           OCIAttrSet() calls.
  RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_ERROR on error.
*/


extern (C) sword OCITypeAddAttr (OCISvcCtx* svchp, OCIError* errhp, OCIType* type, oratext* a_name, ub4 a_length, OCIParam* attr_info);
/*
   NAME: OCITypeAddAttr - OCI Type Add Attribute to an Object Type.
   REMARKS:
       Adds an attribute to an Object type (that was constructed earlier with
       typecode OCI_TYPECODE_OBJECT).
   PARAMETERS:
       svchp (IN)       - The OCI Service Context
       errhp (IN/OUT)   - The OCI error handle. If there is an error, it is
                          recorded in errhp and this function returns
                          OCI_ERROR. Diagnostic information can be obtained by
                          calling OCIErrorGet().
       type (IN/OUT)    - The Type description that is being constructed.
       a_name(IN)       - Optional. gives the name of the attribute.
       a_length         - Optional. gives length of attribute name.
       attr_info        - Information on the attribute. It is obtained by
                          allocating an OCIParam (parameter handle) and setting
                          type information in the OCIParam using OCIAttrSet()
                          calls.
  RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_ERROR on error.
*/


extern (C) sword OCITypeEndCreate (OCISvcCtx* svchp, OCIError* errhp, OCIType* type);
/*
   NAME: OCITypeEndCreate - OCI Type End Creation
   REMARKS:
       Finishes construction of a type description.Subsequently, only access
       will be allowed.
   PARAMETERS:
       svchp (IN)       - The OCI Service Context
       errhp (IN/OUT)   - The OCI error handle. If there is an error, it is
                          recorded in errhp and this function returns
                          OCI_ERROR. Diagnostic information can be obtained by
                          calling OCIErrorGet().
       type (IN/OUT)    - The Type description that is being constructed.
   RETURNS:
        OCI_SUCCESS if the function completes successfully.
        OCI_ERROR on error.
*/

const uint OCI_TYPEELEM_REF		= 0x8000;	/// Element is a reference.
const uint OCI_TYPEPARAM_REQUIRED	= 0x0800;	/// Parameter is required.

/**
 *
 */
bool OCI_TYPEELEM_IS_REF (uint elem_flag) {
	return elem_flag && OCI_TYPEELEM_REF;
}

/**
 *
 */
bool OCI_TYPEPARAM_IS_REQUIRED (uint param_flag) {
	return param_flag && OCI_TYPEPARAM_REQUIRED;
}