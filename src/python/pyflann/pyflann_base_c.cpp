#ifdef __CPLUSPLUS__
extern "C" {
#endif

#ifndef __GNUC__
#pragma warning(disable: 4275)
#pragma warning(disable: 4101)

#endif
#include "Python.h"
#include "compile.h"
#include "frameobject.h"
#include <complex>
#include <math.h>
#include <string>
#include "scxx/object.h"
#include "scxx/list.h"
#include "scxx/tuple.h"
#include "scxx/dict.h"
#include <iostream>
#include <stdio.h>
#include "numpy/arrayobject.h"
#include "flann.h"




// global None value for use in functions.
namespace py {
object None = object(Py_None);
}

char* find_type(PyObject* py_obj)
{
    if(py_obj == NULL) return "C NULL value";
    if(PyCallable_Check(py_obj)) return "callable";
    if(PyString_Check(py_obj)) return "string";
    if(PyInt_Check(py_obj)) return "int";
    if(PyFloat_Check(py_obj)) return "float";
    if(PyDict_Check(py_obj)) return "dict";
    if(PyList_Check(py_obj)) return "list";
    if(PyTuple_Check(py_obj)) return "tuple";
    if(PyFile_Check(py_obj)) return "file";
    if(PyModule_Check(py_obj)) return "module";

    //should probably do more intergation (and thinking) on these.
    if(PyCallable_Check(py_obj) && PyInstance_Check(py_obj)) return "callable";
    if(PyInstance_Check(py_obj)) return "instance";
    if(PyCallable_Check(py_obj)) return "callable";
    return "unkown type";
}

void throw_error(PyObject* exc, const char* msg)
{
 //printf("setting python error: %s\n",msg);
  PyErr_SetString(exc, msg);
  //printf("throwing error\n");
  throw 1;
}

void handle_bad_type(PyObject* py_obj, const char* good_type, const char* var_name)
{
    char msg[500];
    sprintf(msg,"received '%s' type instead of '%s' for variable '%s'",
            find_type(py_obj),good_type,var_name);
    throw_error(PyExc_TypeError,msg);
}

void handle_conversion_error(PyObject* py_obj, const char* good_type, const char* var_name)
{
    char msg[500];
    sprintf(msg,"Conversion Error:, received '%s' type instead of '%s' for variable '%s'",
            find_type(py_obj),good_type,var_name);
    throw_error(PyExc_TypeError,msg);
}


class int_handler
{
public:
    int convert_to_int(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        
        if (!py_obj || !PyInt_Check(py_obj))
            handle_conversion_error(py_obj,"int", name);
        return (int) PyInt_AsLong(py_obj);
    }

    int py_to_int(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyInt_Check(py_obj))
            handle_bad_type(py_obj,"int", name);
        
        return (int) PyInt_AsLong(py_obj);
    }
};

int_handler x__int_handler = int_handler();
#define convert_to_int(py_obj,name) \
        x__int_handler.convert_to_int(py_obj,name)
#define py_to_int(py_obj,name) \
        x__int_handler.py_to_int(py_obj,name)


PyObject* int_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


class float_handler
{
public:
    double convert_to_float(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        
        if (!py_obj || !PyFloat_Check(py_obj))
            handle_conversion_error(py_obj,"float", name);
        return PyFloat_AsDouble(py_obj);
    }

    double py_to_float(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyFloat_Check(py_obj))
            handle_bad_type(py_obj,"float", name);
        
        return PyFloat_AsDouble(py_obj);
    }
};

float_handler x__float_handler = float_handler();
#define convert_to_float(py_obj,name) \
        x__float_handler.convert_to_float(py_obj,name)
#define py_to_float(py_obj,name) \
        x__float_handler.py_to_float(py_obj,name)


PyObject* float_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


class complex_handler
{
public:
    std::complex<double> convert_to_complex(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        
        if (!py_obj || !PyComplex_Check(py_obj))
            handle_conversion_error(py_obj,"complex", name);
        return std::complex<double>(PyComplex_RealAsDouble(py_obj),PyComplex_ImagAsDouble(py_obj));
    }

    std::complex<double> py_to_complex(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyComplex_Check(py_obj))
            handle_bad_type(py_obj,"complex", name);
        
        return std::complex<double>(PyComplex_RealAsDouble(py_obj),PyComplex_ImagAsDouble(py_obj));
    }
};

complex_handler x__complex_handler = complex_handler();
#define convert_to_complex(py_obj,name) \
        x__complex_handler.convert_to_complex(py_obj,name)
#define py_to_complex(py_obj,name) \
        x__complex_handler.py_to_complex(py_obj,name)


PyObject* complex_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


class unicode_handler
{
public:
    Py_UNICODE* convert_to_unicode(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        Py_XINCREF(py_obj);
        if (!py_obj || !PyUnicode_Check(py_obj))
            handle_conversion_error(py_obj,"unicode", name);
        return PyUnicode_AS_UNICODE(py_obj);
    }

    Py_UNICODE* py_to_unicode(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyUnicode_Check(py_obj))
            handle_bad_type(py_obj,"unicode", name);
        Py_XINCREF(py_obj);
        return PyUnicode_AS_UNICODE(py_obj);
    }
};

unicode_handler x__unicode_handler = unicode_handler();
#define convert_to_unicode(py_obj,name) \
        x__unicode_handler.convert_to_unicode(py_obj,name)
#define py_to_unicode(py_obj,name) \
        x__unicode_handler.py_to_unicode(py_obj,name)


PyObject* unicode_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


class string_handler
{
public:
    std::string convert_to_string(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        Py_XINCREF(py_obj);
        if (!py_obj || !PyString_Check(py_obj))
            handle_conversion_error(py_obj,"string", name);
        return std::string(PyString_AsString(py_obj));
    }

    std::string py_to_string(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyString_Check(py_obj))
            handle_bad_type(py_obj,"string", name);
        Py_XINCREF(py_obj);
        return std::string(PyString_AsString(py_obj));
    }
};

string_handler x__string_handler = string_handler();
#define convert_to_string(py_obj,name) \
        x__string_handler.convert_to_string(py_obj,name)
#define py_to_string(py_obj,name) \
        x__string_handler.py_to_string(py_obj,name)


               PyObject* string_to_py(std::string s)
               {
                   return PyString_FromString(s.c_str());
               }
               
class list_handler
{
public:
    py::list convert_to_list(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        
        if (!py_obj || !PyList_Check(py_obj))
            handle_conversion_error(py_obj,"list", name);
        return py::list(py_obj);
    }

    py::list py_to_list(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyList_Check(py_obj))
            handle_bad_type(py_obj,"list", name);
        
        return py::list(py_obj);
    }
};

list_handler x__list_handler = list_handler();
#define convert_to_list(py_obj,name) \
        x__list_handler.convert_to_list(py_obj,name)
#define py_to_list(py_obj,name) \
        x__list_handler.py_to_list(py_obj,name)


PyObject* list_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


class dict_handler
{
public:
    py::dict convert_to_dict(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        
        if (!py_obj || !PyDict_Check(py_obj))
            handle_conversion_error(py_obj,"dict", name);
        return py::dict(py_obj);
    }

    py::dict py_to_dict(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyDict_Check(py_obj))
            handle_bad_type(py_obj,"dict", name);
        
        return py::dict(py_obj);
    }
};

dict_handler x__dict_handler = dict_handler();
#define convert_to_dict(py_obj,name) \
        x__dict_handler.convert_to_dict(py_obj,name)
#define py_to_dict(py_obj,name) \
        x__dict_handler.py_to_dict(py_obj,name)


PyObject* dict_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


class tuple_handler
{
public:
    py::tuple convert_to_tuple(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        
        if (!py_obj || !PyTuple_Check(py_obj))
            handle_conversion_error(py_obj,"tuple", name);
        return py::tuple(py_obj);
    }

    py::tuple py_to_tuple(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyTuple_Check(py_obj))
            handle_bad_type(py_obj,"tuple", name);
        
        return py::tuple(py_obj);
    }
};

tuple_handler x__tuple_handler = tuple_handler();
#define convert_to_tuple(py_obj,name) \
        x__tuple_handler.convert_to_tuple(py_obj,name)
#define py_to_tuple(py_obj,name) \
        x__tuple_handler.py_to_tuple(py_obj,name)


PyObject* tuple_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


class file_handler
{
public:
    FILE* convert_to_file(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        Py_XINCREF(py_obj);
        if (!py_obj || !PyFile_Check(py_obj))
            handle_conversion_error(py_obj,"file", name);
        return PyFile_AsFile(py_obj);
    }

    FILE* py_to_file(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyFile_Check(py_obj))
            handle_bad_type(py_obj,"file", name);
        Py_XINCREF(py_obj);
        return PyFile_AsFile(py_obj);
    }
};

file_handler x__file_handler = file_handler();
#define convert_to_file(py_obj,name) \
        x__file_handler.convert_to_file(py_obj,name)
#define py_to_file(py_obj,name) \
        x__file_handler.py_to_file(py_obj,name)


               PyObject* file_to_py(FILE* file, char* name, char* mode)
               {
                   return (PyObject*) PyFile_FromFile(file, name, mode, fclose);
               }
               
class instance_handler
{
public:
    py::object convert_to_instance(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        
        if (!py_obj || !PyInstance_Check(py_obj))
            handle_conversion_error(py_obj,"instance", name);
        return py::object(py_obj);
    }

    py::object py_to_instance(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyInstance_Check(py_obj))
            handle_bad_type(py_obj,"instance", name);
        
        return py::object(py_obj);
    }
};

instance_handler x__instance_handler = instance_handler();
#define convert_to_instance(py_obj,name) \
        x__instance_handler.convert_to_instance(py_obj,name)
#define py_to_instance(py_obj,name) \
        x__instance_handler.py_to_instance(py_obj,name)


PyObject* instance_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


class numpy_size_handler
{
public:
    void conversion_numpy_check_size(PyArrayObject* arr_obj, int Ndims,
                                     const char* name)
    {
        if (arr_obj->nd != Ndims)
        {
            char msg[500];
            sprintf(msg,"Conversion Error: received '%d' dimensional array instead of '%d' dimensional array for variable '%s'",
                    arr_obj->nd,Ndims,name);
            throw_error(PyExc_TypeError,msg);
        }
    }

    void numpy_check_size(PyArrayObject* arr_obj, int Ndims, const char* name)
    {
        if (arr_obj->nd != Ndims)
        {
            char msg[500];
            sprintf(msg,"received '%d' dimensional array instead of '%d' dimensional array for variable '%s'",
                    arr_obj->nd,Ndims,name);
            throw_error(PyExc_TypeError,msg);
        }
    }
};

numpy_size_handler x__numpy_size_handler = numpy_size_handler();
#define conversion_numpy_check_size x__numpy_size_handler.conversion_numpy_check_size
#define numpy_check_size x__numpy_size_handler.numpy_check_size


class numpy_type_handler
{
public:
    void conversion_numpy_check_type(PyArrayObject* arr_obj, int numeric_type,
                                     const char* name)
    {
        // Make sure input has correct numeric type.
        int arr_type = arr_obj->descr->type_num;
        if (PyTypeNum_ISEXTENDED(numeric_type))
        {
        char msg[80];
        sprintf(msg, "Conversion Error: extended types not supported for variable '%s'",
                name);
        throw_error(PyExc_TypeError, msg);
        }
        if (!PyArray_EquivTypenums(arr_type, numeric_type))
        {

        char* type_names[23] = {"bool", "byte", "ubyte","short", "ushort",
                                "int", "uint", "long", "ulong", "longlong", "ulonglong",
                                "float", "double", "longdouble", "cfloat", "cdouble",
                                "clongdouble", "object", "string", "unicode", "void", "ntype",
                                "unknown"};
        char msg[500];
        sprintf(msg,"Conversion Error: received '%s' typed array instead of '%s' typed array for variable '%s'",
                type_names[arr_type],type_names[numeric_type],name);
        throw_error(PyExc_TypeError,msg);
        }
    }

    void numpy_check_type(PyArrayObject* arr_obj, int numeric_type, const char* name)
    {
        // Make sure input has correct numeric type.
        int arr_type = arr_obj->descr->type_num;
        if (PyTypeNum_ISEXTENDED(numeric_type))
        {
        char msg[80];
        sprintf(msg, "Conversion Error: extended types not supported for variable '%s'",
                name);
        throw_error(PyExc_TypeError, msg);
        }
        if (!PyArray_EquivTypenums(arr_type, numeric_type))
        {
            char* type_names[23] = {"bool", "byte", "ubyte","short", "ushort",
                                    "int", "uint", "long", "ulong", "longlong", "ulonglong",
                                    "float", "double", "longdouble", "cfloat", "cdouble",
                                    "clongdouble", "object", "string", "unicode", "void", "ntype",
                                    "unknown"};
            char msg[500];
            sprintf(msg,"received '%s' typed array instead of '%s' typed array for variable '%s'",
                    type_names[arr_type],type_names[numeric_type],name);
            throw_error(PyExc_TypeError,msg);
        }
    }
};

numpy_type_handler x__numpy_type_handler = numpy_type_handler();
#define conversion_numpy_check_type x__numpy_type_handler.conversion_numpy_check_type
#define numpy_check_type x__numpy_type_handler.numpy_check_type


class numpy_handler
{
public:
    PyArrayObject* convert_to_numpy(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        Py_XINCREF(py_obj);
        if (!py_obj || !PyArray_Check(py_obj))
            handle_conversion_error(py_obj,"numpy", name);
        return (PyArrayObject*) py_obj;
    }

    PyArrayObject* py_to_numpy(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !PyArray_Check(py_obj))
            handle_bad_type(py_obj,"numpy", name);
        Py_XINCREF(py_obj);
        return (PyArrayObject*) py_obj;
    }
};

numpy_handler x__numpy_handler = numpy_handler();
#define convert_to_numpy(py_obj,name) \
        x__numpy_handler.convert_to_numpy(py_obj,name)
#define py_to_numpy(py_obj,name) \
        x__numpy_handler.py_to_numpy(py_obj,name)


PyObject* numpy_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


class catchall_handler
{
public:
    py::object convert_to_catchall(PyObject* py_obj, const char* name)
    {
        // Incref occurs even if conversion fails so that
        // the decref in cleanup_code has a matching incref.
        
        if (!py_obj || !(py_obj))
            handle_conversion_error(py_obj,"catchall", name);
        return py::object(py_obj);
    }

    py::object py_to_catchall(PyObject* py_obj, const char* name)
    {
        // !! Pretty sure INCREF should only be called on success since
        // !! py_to_xxx is used by the user -- not the code generator.
        if (!py_obj || !(py_obj))
            handle_bad_type(py_obj,"catchall", name);
        
        return py::object(py_obj);
    }
};

catchall_handler x__catchall_handler = catchall_handler();
#define convert_to_catchall(py_obj,name) \
        x__catchall_handler.convert_to_catchall(py_obj,name)
#define py_to_catchall(py_obj,name) \
        x__catchall_handler.py_to_catchall(py_obj,name)


PyObject* catchall_to_py(PyObject* obj)
{
    return (PyObject*) obj;
}


template <typename S>
S* py_to_struct(PyObject* obj)
{
    S* ptr;
    int length;
    PyString_AsStringAndSize(obj,(char**)&ptr,&length);
    return ptr;
}


static PyObject* flatten_double2float(PyObject*self, PyObject* args, PyObject* kywds)
{
    py::object return_val;
    int exception_occured = 0;
    PyObject *py_local_dict = NULL;
    static char *kwlist[] = {"pts","pts_flat","local_dict", NULL};
    PyObject *py_pts, *py_pts_flat;
    int pts_used, pts_flat_used;
    py_pts = py_pts_flat = NULL;
    pts_used= pts_flat_used = 0;
    
    if(!PyArg_ParseTupleAndKeywords(args,kywds,"OO|O:flatten_double2float",kwlist,&py_pts, &py_pts_flat, &py_local_dict))
       return NULL;
    try                              
    {                                
        py_pts = py_pts;
        PyArrayObject* pts_array = convert_to_numpy(py_pts,"pts");
        conversion_numpy_check_type(pts_array,PyArray_DOUBLE,"pts");
        #define PTS1(i) (*((double*)(pts_array->data + (i)*Spts[0])))
        #define PTS2(i,j) (*((double*)(pts_array->data + (i)*Spts[0] + (j)*Spts[1])))
        #define PTS3(i,j,k) (*((double*)(pts_array->data + (i)*Spts[0] + (j)*Spts[1] + (k)*Spts[2])))
        #define PTS4(i,j,k,l) (*((double*)(pts_array->data + (i)*Spts[0] + (j)*Spts[1] + (k)*Spts[2] + (l)*Spts[3])))
        npy_intp* Npts = pts_array->dimensions;
        npy_intp* Spts = pts_array->strides;
        int Dpts = pts_array->nd;
        double* pts = (double*) pts_array->data;
        pts_used = 1;
        py_pts_flat = py_pts_flat;
        PyArrayObject* pts_flat_array = convert_to_numpy(py_pts_flat,"pts_flat");
        conversion_numpy_check_type(pts_flat_array,PyArray_FLOAT,"pts_flat");
        #define PTS_FLAT1(i) (*((float*)(pts_flat_array->data + (i)*Spts_flat[0])))
        #define PTS_FLAT2(i,j) (*((float*)(pts_flat_array->data + (i)*Spts_flat[0] + (j)*Spts_flat[1])))
        #define PTS_FLAT3(i,j,k) (*((float*)(pts_flat_array->data + (i)*Spts_flat[0] + (j)*Spts_flat[1] + (k)*Spts_flat[2])))
        #define PTS_FLAT4(i,j,k,l) (*((float*)(pts_flat_array->data + (i)*Spts_flat[0] + (j)*Spts_flat[1] + (k)*Spts_flat[2] + (l)*Spts_flat[3])))
        npy_intp* Npts_flat = pts_flat_array->dimensions;
        npy_intp* Spts_flat = pts_flat_array->strides;
        int Dpts_flat = pts_flat_array->nd;
        float* pts_flat = (float*) pts_flat_array->data;
        pts_flat_used = 1;
        /*<function call here>*/     
        #line 57 "/home/marius/ubc/flann/src/python/pyflann/pyflann_base.py"
        
            size_t loc = 0;
            for(int i = 0; i < Npts[0]; ++i)
            {
                for(int p = 0; p < Npts[1]; ++p)
                {
                pts_flat[loc] = float( PTS2(i,p) );
                ++loc;
                }
            }
        if(py_local_dict)                                  
        {                                                  
            py::dict local_dict = py::dict(py_local_dict); 
        }                                                  
    
    }                                
    catch(...)                       
    {                                
        return_val =  py::object();      
        exception_occured = 1;       
    }                                
    /*cleanup code*/                     
    if(pts_used)
    {
        Py_XDECREF(py_pts);
        #undef PTS1
        #undef PTS2
        #undef PTS3
        #undef PTS4
    }
    if(pts_flat_used)
    {
        Py_XDECREF(py_pts_flat);
        #undef PTS_FLAT1
        #undef PTS_FLAT2
        #undef PTS_FLAT3
        #undef PTS_FLAT4
    }
    if(!(PyObject*)return_val && !exception_occured)
    {
                                  
        return_val = Py_None;            
    }
                                  
    return return_val.disown();           
}                                
static PyObject* pyflann_build_index(PyObject*self, PyObject* args, PyObject* kywds)
{
    py::object return_val;
    int exception_occured = 0;
    PyObject *py_local_dict = NULL;
    static char *kwlist[] = {"dataset","npts","dim","log_level","random_seed","algorithm","checks","cb_index","trees","branching","iterations","target_precision","centers_init","build_weight","memory_weight","sample_fraction","local_dict", NULL};
    PyObject *py_dataset, *py_npts, *py_dim, *py_log_level, *py_random_seed, *py_algorithm, *py_checks, *py_cb_index, *py_trees, *py_branching, *py_iterations, *py_target_precision, *py_centers_init, *py_build_weight, *py_memory_weight, *py_sample_fraction;
    int dataset_used, npts_used, dim_used, log_level_used, random_seed_used, algorithm_used, checks_used, cb_index_used, trees_used, branching_used, iterations_used, target_precision_used, centers_init_used, build_weight_used, memory_weight_used, sample_fraction_used;
    py_dataset = py_npts = py_dim = py_log_level = py_random_seed = py_algorithm = py_checks = py_cb_index = py_trees = py_branching = py_iterations = py_target_precision = py_centers_init = py_build_weight = py_memory_weight = py_sample_fraction = NULL;
    dataset_used= npts_used= dim_used= log_level_used= random_seed_used= algorithm_used= checks_used= cb_index_used= trees_used= branching_used= iterations_used= target_precision_used= centers_init_used= build_weight_used= memory_weight_used= sample_fraction_used = 0;
    
    if(!PyArg_ParseTupleAndKeywords(args,kywds,"OOOOOOOOOOOOOOOO|O:pyflann_build_index",kwlist,&py_dataset, &py_npts, &py_dim, &py_log_level, &py_random_seed, &py_algorithm, &py_checks, &py_cb_index, &py_trees, &py_branching, &py_iterations, &py_target_precision, &py_centers_init, &py_build_weight, &py_memory_weight, &py_sample_fraction, &py_local_dict))
       return NULL;
    try                              
    {                                
        py_dataset = py_dataset;
        PyArrayObject* dataset_array = convert_to_numpy(py_dataset,"dataset");
        conversion_numpy_check_type(dataset_array,PyArray_FLOAT,"dataset");
        #define DATASET1(i) (*((float*)(dataset_array->data + (i)*Sdataset[0])))
        #define DATASET2(i,j) (*((float*)(dataset_array->data + (i)*Sdataset[0] + (j)*Sdataset[1])))
        #define DATASET3(i,j,k) (*((float*)(dataset_array->data + (i)*Sdataset[0] + (j)*Sdataset[1] + (k)*Sdataset[2])))
        #define DATASET4(i,j,k,l) (*((float*)(dataset_array->data + (i)*Sdataset[0] + (j)*Sdataset[1] + (k)*Sdataset[2] + (l)*Sdataset[3])))
        npy_intp* Ndataset = dataset_array->dimensions;
        npy_intp* Sdataset = dataset_array->strides;
        int Ddataset = dataset_array->nd;
        float* dataset = (float*) dataset_array->data;
        dataset_used = 1;
        py_npts = py_npts;
        int npts = convert_to_int(py_npts,"npts");
        npts_used = 1;
        py_dim = py_dim;
        int dim = convert_to_int(py_dim,"dim");
        dim_used = 1;
        py_log_level = py_log_level;
        int log_level = convert_to_int(py_log_level,"log_level");
        log_level_used = 1;
        py_random_seed = py_random_seed;
        int random_seed = convert_to_int(py_random_seed,"random_seed");
        random_seed_used = 1;
        py_algorithm = py_algorithm;
        int algorithm = convert_to_int(py_algorithm,"algorithm");
        algorithm_used = 1;
        py_checks = py_checks;
        int checks = convert_to_int(py_checks,"checks");
        checks_used = 1;
        py_cb_index = py_cb_index;
        double cb_index = convert_to_float(py_cb_index,"cb_index");
        cb_index_used = 1;
        py_trees = py_trees;
        int trees = convert_to_int(py_trees,"trees");
        trees_used = 1;
        py_branching = py_branching;
        int branching = convert_to_int(py_branching,"branching");
        branching_used = 1;
        py_iterations = py_iterations;
        int iterations = convert_to_int(py_iterations,"iterations");
        iterations_used = 1;
        py_target_precision = py_target_precision;
        double target_precision = convert_to_float(py_target_precision,"target_precision");
        target_precision_used = 1;
        py_centers_init = py_centers_init;
        int centers_init = convert_to_int(py_centers_init,"centers_init");
        centers_init_used = 1;
        py_build_weight = py_build_weight;
        double build_weight = convert_to_float(py_build_weight,"build_weight");
        build_weight_used = 1;
        py_memory_weight = py_memory_weight;
        double memory_weight = convert_to_float(py_memory_weight,"memory_weight");
        memory_weight_used = 1;
        py_sample_fraction = py_sample_fraction;
        double sample_fraction = convert_to_float(py_sample_fraction,"sample_fraction");
        sample_fraction_used = 1;
        /*<function call here>*/     
        #line 71 "/home/marius/ubc/flann/src/python/pyflann/pyflann_base.py"
        FLANNParameters flannparams;
        flannparams.log_level = log_level; 
        flannparams.random_seed = random_seed; 
        flannparams.log_destination = NULL;IndexParameters idxparams;
        idxparams.algorithm = algorithm; 
        idxparams.checks = checks; 
        idxparams.cb_index = cb_index; 
        idxparams.trees = trees; 
        idxparams.branching = branching; 
        idxparams.iterations = iterations; 
        idxparams.target_precision = target_precision; 
        idxparams.centers_init = centers_init; 
        idxparams.build_weight = build_weight; 
        idxparams.memory_weight = memory_weight; 
        idxparams.sample_fraction = sample_fraction; 
        
                    float speedup = 1;
                    py::tuple result(2);
                    result[0] = flann_build_index(dataset, npts, dim, &speedup, &idxparams, &flannparams);
                    py::dict ret_params;
        ret_params["algorithm"] = idxparams.algorithm; 
        ret_params["checks"] = idxparams.checks; 
        ret_params["cb_index"] = idxparams.cb_index; 
        ret_params["trees"] = idxparams.trees; 
        ret_params["branching"] = idxparams.branching; 
        ret_params["iterations"] = idxparams.iterations; 
        ret_params["target_precision"] = idxparams.target_precision; 
        ret_params["centers_init"] = idxparams.centers_init; 
        ret_params["build_weight"] = idxparams.build_weight; 
        ret_params["memory_weight"] = idxparams.memory_weight; 
        ret_params["sample_fraction"] = idxparams.sample_fraction; 
        
                    ret_params["speedup"] = speedup;
                    result[1] = ret_params;
                    return_val = result;
        if(py_local_dict)                                  
        {                                                  
            py::dict local_dict = py::dict(py_local_dict); 
        }                                                  
    
    }                                
    catch(...)                       
    {                                
        return_val =  py::object();      
        exception_occured = 1;       
    }                                
    /*cleanup code*/                     
    if(dataset_used)
    {
        Py_XDECREF(py_dataset);
        #undef DATASET1
        #undef DATASET2
        #undef DATASET3
        #undef DATASET4
    }
    if(!(PyObject*)return_val && !exception_occured)
    {
                                  
        return_val = Py_None;            
    }
                                  
    return return_val.disown();           
}                                
static PyObject* pyflann_free_index(PyObject*self, PyObject* args, PyObject* kywds)
{
    py::object return_val;
    int exception_occured = 0;
    PyObject *py_local_dict = NULL;
    static char *kwlist[] = {"index","log_level","random_seed","local_dict", NULL};
    PyObject *py_index, *py_log_level, *py_random_seed;
    int index_used, log_level_used, random_seed_used;
    py_index = py_log_level = py_random_seed = NULL;
    index_used= log_level_used= random_seed_used = 0;
    
    if(!PyArg_ParseTupleAndKeywords(args,kywds,"OOO|O:pyflann_free_index",kwlist,&py_index, &py_log_level, &py_random_seed, &py_local_dict))
       return NULL;
    try                              
    {                                
        py_index = py_index;
        int index = convert_to_int(py_index,"index");
        index_used = 1;
        py_log_level = py_log_level;
        int log_level = convert_to_int(py_log_level,"log_level");
        log_level_used = 1;
        py_random_seed = py_random_seed;
        int random_seed = convert_to_int(py_random_seed,"random_seed");
        random_seed_used = 1;
        /*<function call here>*/     
        #line 84 "/home/marius/ubc/flann/src/python/pyflann/pyflann_base.py"
        FLANNParameters flannparams;
        flannparams.log_level = log_level; 
        flannparams.random_seed = random_seed; 
        flannparams.log_destination = NULL;
                    flann_free_index(FLANN_INDEX(index), &flannparams);
        if(py_local_dict)                                  
        {                                                  
            py::dict local_dict = py::dict(py_local_dict); 
        }                                                  
    
    }                                
    catch(...)                       
    {                                
        return_val =  py::object();      
        exception_occured = 1;       
    }                                
    /*cleanup code*/                     
    if(!(PyObject*)return_val && !exception_occured)
    {
                                  
        return_val = Py_None;            
    }
                                  
    return return_val.disown();           
}                                
static PyObject* pyflann_find_nearest_neighbors(PyObject*self, PyObject* args, PyObject* kywds)
{
    py::object return_val;
    int exception_occured = 0;
    PyObject *py_local_dict = NULL;
    static char *kwlist[] = {"dataset","npts","dim","testset","tcount","result","num_neighbors","log_level","random_seed","algorithm","checks","cb_index","trees","branching","iterations","target_precision","centers_init","build_weight","memory_weight","sample_fraction","local_dict", NULL};
    PyObject *py_dataset, *py_npts, *py_dim, *py_testset, *py_tcount, *py_result, *py_num_neighbors, *py_log_level, *py_random_seed, *py_algorithm, *py_checks, *py_cb_index, *py_trees, *py_branching, *py_iterations, *py_target_precision, *py_centers_init, *py_build_weight, *py_memory_weight, *py_sample_fraction;
    int dataset_used, npts_used, dim_used, testset_used, tcount_used, result_used, num_neighbors_used, log_level_used, random_seed_used, algorithm_used, checks_used, cb_index_used, trees_used, branching_used, iterations_used, target_precision_used, centers_init_used, build_weight_used, memory_weight_used, sample_fraction_used;
    py_dataset = py_npts = py_dim = py_testset = py_tcount = py_result = py_num_neighbors = py_log_level = py_random_seed = py_algorithm = py_checks = py_cb_index = py_trees = py_branching = py_iterations = py_target_precision = py_centers_init = py_build_weight = py_memory_weight = py_sample_fraction = NULL;
    dataset_used= npts_used= dim_used= testset_used= tcount_used= result_used= num_neighbors_used= log_level_used= random_seed_used= algorithm_used= checks_used= cb_index_used= trees_used= branching_used= iterations_used= target_precision_used= centers_init_used= build_weight_used= memory_weight_used= sample_fraction_used = 0;
    
    if(!PyArg_ParseTupleAndKeywords(args,kywds,"OOOOOOOOOOOOOOOOOOOO|O:pyflann_find_nearest_neighbors",kwlist,&py_dataset, &py_npts, &py_dim, &py_testset, &py_tcount, &py_result, &py_num_neighbors, &py_log_level, &py_random_seed, &py_algorithm, &py_checks, &py_cb_index, &py_trees, &py_branching, &py_iterations, &py_target_precision, &py_centers_init, &py_build_weight, &py_memory_weight, &py_sample_fraction, &py_local_dict))
       return NULL;
    try                              
    {                                
        py_dataset = py_dataset;
        PyArrayObject* dataset_array = convert_to_numpy(py_dataset,"dataset");
        conversion_numpy_check_type(dataset_array,PyArray_FLOAT,"dataset");
        #define DATASET1(i) (*((float*)(dataset_array->data + (i)*Sdataset[0])))
        #define DATASET2(i,j) (*((float*)(dataset_array->data + (i)*Sdataset[0] + (j)*Sdataset[1])))
        #define DATASET3(i,j,k) (*((float*)(dataset_array->data + (i)*Sdataset[0] + (j)*Sdataset[1] + (k)*Sdataset[2])))
        #define DATASET4(i,j,k,l) (*((float*)(dataset_array->data + (i)*Sdataset[0] + (j)*Sdataset[1] + (k)*Sdataset[2] + (l)*Sdataset[3])))
        npy_intp* Ndataset = dataset_array->dimensions;
        npy_intp* Sdataset = dataset_array->strides;
        int Ddataset = dataset_array->nd;
        float* dataset = (float*) dataset_array->data;
        dataset_used = 1;
        py_npts = py_npts;
        int npts = convert_to_int(py_npts,"npts");
        npts_used = 1;
        py_dim = py_dim;
        int dim = convert_to_int(py_dim,"dim");
        dim_used = 1;
        py_testset = py_testset;
        PyArrayObject* testset_array = convert_to_numpy(py_testset,"testset");
        conversion_numpy_check_type(testset_array,PyArray_FLOAT,"testset");
        #define TESTSET1(i) (*((float*)(testset_array->data + (i)*Stestset[0])))
        #define TESTSET2(i,j) (*((float*)(testset_array->data + (i)*Stestset[0] + (j)*Stestset[1])))
        #define TESTSET3(i,j,k) (*((float*)(testset_array->data + (i)*Stestset[0] + (j)*Stestset[1] + (k)*Stestset[2])))
        #define TESTSET4(i,j,k,l) (*((float*)(testset_array->data + (i)*Stestset[0] + (j)*Stestset[1] + (k)*Stestset[2] + (l)*Stestset[3])))
        npy_intp* Ntestset = testset_array->dimensions;
        npy_intp* Stestset = testset_array->strides;
        int Dtestset = testset_array->nd;
        float* testset = (float*) testset_array->data;
        testset_used = 1;
        py_tcount = py_tcount;
        int tcount = convert_to_int(py_tcount,"tcount");
        tcount_used = 1;
        py_result = py_result;
        PyArrayObject* result_array = convert_to_numpy(py_result,"result");
        conversion_numpy_check_type(result_array,PyArray_LONG,"result");
        #define RESULT1(i) (*((long*)(result_array->data + (i)*Sresult[0])))
        #define RESULT2(i,j) (*((long*)(result_array->data + (i)*Sresult[0] + (j)*Sresult[1])))
        #define RESULT3(i,j,k) (*((long*)(result_array->data + (i)*Sresult[0] + (j)*Sresult[1] + (k)*Sresult[2])))
        #define RESULT4(i,j,k,l) (*((long*)(result_array->data + (i)*Sresult[0] + (j)*Sresult[1] + (k)*Sresult[2] + (l)*Sresult[3])))
        npy_intp* Nresult = result_array->dimensions;
        npy_intp* Sresult = result_array->strides;
        int Dresult = result_array->nd;
        long* result = (long*) result_array->data;
        result_used = 1;
        py_num_neighbors = py_num_neighbors;
        int num_neighbors = convert_to_int(py_num_neighbors,"num_neighbors");
        num_neighbors_used = 1;
        py_log_level = py_log_level;
        int log_level = convert_to_int(py_log_level,"log_level");
        log_level_used = 1;
        py_random_seed = py_random_seed;
        int random_seed = convert_to_int(py_random_seed,"random_seed");
        random_seed_used = 1;
        py_algorithm = py_algorithm;
        int algorithm = convert_to_int(py_algorithm,"algorithm");
        algorithm_used = 1;
        py_checks = py_checks;
        int checks = convert_to_int(py_checks,"checks");
        checks_used = 1;
        py_cb_index = py_cb_index;
        double cb_index = convert_to_float(py_cb_index,"cb_index");
        cb_index_used = 1;
        py_trees = py_trees;
        int trees = convert_to_int(py_trees,"trees");
        trees_used = 1;
        py_branching = py_branching;
        int branching = convert_to_int(py_branching,"branching");
        branching_used = 1;
        py_iterations = py_iterations;
        int iterations = convert_to_int(py_iterations,"iterations");
        iterations_used = 1;
        py_target_precision = py_target_precision;
        double target_precision = convert_to_float(py_target_precision,"target_precision");
        target_precision_used = 1;
        py_centers_init = py_centers_init;
        int centers_init = convert_to_int(py_centers_init,"centers_init");
        centers_init_used = 1;
        py_build_weight = py_build_weight;
        double build_weight = convert_to_float(py_build_weight,"build_weight");
        build_weight_used = 1;
        py_memory_weight = py_memory_weight;
        double memory_weight = convert_to_float(py_memory_weight,"memory_weight");
        memory_weight_used = 1;
        py_sample_fraction = py_sample_fraction;
        double sample_fraction = convert_to_float(py_sample_fraction,"sample_fraction");
        sample_fraction_used = 1;
        /*<function call here>*/     
        #line 91 "/home/marius/ubc/flann/src/python/pyflann/pyflann_base.py"
        FLANNParameters flannparams;
        flannparams.log_level = log_level; 
        flannparams.random_seed = random_seed; 
        flannparams.log_destination = NULL;IndexParameters idxparams;
        idxparams.algorithm = algorithm; 
        idxparams.checks = checks; 
        idxparams.cb_index = cb_index; 
        idxparams.trees = trees; 
        idxparams.branching = branching; 
        idxparams.iterations = iterations; 
        idxparams.target_precision = target_precision; 
        idxparams.centers_init = centers_init; 
        idxparams.build_weight = build_weight; 
        idxparams.memory_weight = memory_weight; 
        idxparams.sample_fraction = sample_fraction; 
        
                    //printf("npts = %d, dim = %d, tcount = %d\n", npts, dim, tcount);
                    flann_find_nearest_neighbors(dataset, npts, dim, testset, tcount,
                    (int*)result, num_neighbors, &idxparams, &flannparams);
        if(py_local_dict)                                  
        {                                                  
            py::dict local_dict = py::dict(py_local_dict); 
        }                                                  
    
    }                                
    catch(...)                       
    {                                
        return_val =  py::object();      
        exception_occured = 1;       
    }                                
    /*cleanup code*/                     
    if(dataset_used)
    {
        Py_XDECREF(py_dataset);
        #undef DATASET1
        #undef DATASET2
        #undef DATASET3
        #undef DATASET4
    }
    if(testset_used)
    {
        Py_XDECREF(py_testset);
        #undef TESTSET1
        #undef TESTSET2
        #undef TESTSET3
        #undef TESTSET4
    }
    if(result_used)
    {
        Py_XDECREF(py_result);
        #undef RESULT1
        #undef RESULT2
        #undef RESULT3
        #undef RESULT4
    }
    if(!(PyObject*)return_val && !exception_occured)
    {
                                  
        return_val = Py_None;            
    }
                                  
    return return_val.disown();           
}                                
static PyObject* pyflann_find_nearest_neighbors_index(PyObject*self, PyObject* args, PyObject* kywds)
{
    py::object return_val;
    int exception_occured = 0;
    PyObject *py_local_dict = NULL;
    static char *kwlist[] = {"index","testset","tcount","result","num_neighbors","checks","log_level","random_seed","local_dict", NULL};
    PyObject *py_index, *py_testset, *py_tcount, *py_result, *py_num_neighbors, *py_checks, *py_log_level, *py_random_seed;
    int index_used, testset_used, tcount_used, result_used, num_neighbors_used, checks_used, log_level_used, random_seed_used;
    py_index = py_testset = py_tcount = py_result = py_num_neighbors = py_checks = py_log_level = py_random_seed = NULL;
    index_used= testset_used= tcount_used= result_used= num_neighbors_used= checks_used= log_level_used= random_seed_used = 0;
    
    if(!PyArg_ParseTupleAndKeywords(args,kywds,"OOOOOOOO|O:pyflann_find_nearest_neighbors_index",kwlist,&py_index, &py_testset, &py_tcount, &py_result, &py_num_neighbors, &py_checks, &py_log_level, &py_random_seed, &py_local_dict))
       return NULL;
    try                              
    {                                
        py_index = py_index;
        int index = convert_to_int(py_index,"index");
        index_used = 1;
        py_testset = py_testset;
        PyArrayObject* testset_array = convert_to_numpy(py_testset,"testset");
        conversion_numpy_check_type(testset_array,PyArray_FLOAT,"testset");
        #define TESTSET1(i) (*((float*)(testset_array->data + (i)*Stestset[0])))
        #define TESTSET2(i,j) (*((float*)(testset_array->data + (i)*Stestset[0] + (j)*Stestset[1])))
        #define TESTSET3(i,j,k) (*((float*)(testset_array->data + (i)*Stestset[0] + (j)*Stestset[1] + (k)*Stestset[2])))
        #define TESTSET4(i,j,k,l) (*((float*)(testset_array->data + (i)*Stestset[0] + (j)*Stestset[1] + (k)*Stestset[2] + (l)*Stestset[3])))
        npy_intp* Ntestset = testset_array->dimensions;
        npy_intp* Stestset = testset_array->strides;
        int Dtestset = testset_array->nd;
        float* testset = (float*) testset_array->data;
        testset_used = 1;
        py_tcount = py_tcount;
        int tcount = convert_to_int(py_tcount,"tcount");
        tcount_used = 1;
        py_result = py_result;
        PyArrayObject* result_array = convert_to_numpy(py_result,"result");
        conversion_numpy_check_type(result_array,PyArray_LONG,"result");
        #define RESULT1(i) (*((long*)(result_array->data + (i)*Sresult[0])))
        #define RESULT2(i,j) (*((long*)(result_array->data + (i)*Sresult[0] + (j)*Sresult[1])))
        #define RESULT3(i,j,k) (*((long*)(result_array->data + (i)*Sresult[0] + (j)*Sresult[1] + (k)*Sresult[2])))
        #define RESULT4(i,j,k,l) (*((long*)(result_array->data + (i)*Sresult[0] + (j)*Sresult[1] + (k)*Sresult[2] + (l)*Sresult[3])))
        npy_intp* Nresult = result_array->dimensions;
        npy_intp* Sresult = result_array->strides;
        int Dresult = result_array->nd;
        long* result = (long*) result_array->data;
        result_used = 1;
        py_num_neighbors = py_num_neighbors;
        int num_neighbors = convert_to_int(py_num_neighbors,"num_neighbors");
        num_neighbors_used = 1;
        py_checks = py_checks;
        int checks = convert_to_int(py_checks,"checks");
        checks_used = 1;
        py_log_level = py_log_level;
        int log_level = convert_to_int(py_log_level,"log_level");
        log_level_used = 1;
        py_random_seed = py_random_seed;
        int random_seed = convert_to_int(py_random_seed,"random_seed");
        random_seed_used = 1;
        /*<function call here>*/     
        #line 100 "/home/marius/ubc/flann/src/python/pyflann/pyflann_base.py"
        FLANNParameters flannparams;
        flannparams.log_level = log_level; 
        flannparams.random_seed = random_seed; 
        flannparams.log_destination = NULL;
                    flann_find_nearest_neighbors_index(FLANN_INDEX(index), testset, tcount,
                    (int*)result, num_neighbors, checks, &flannparams);
        if(py_local_dict)                                  
        {                                                  
            py::dict local_dict = py::dict(py_local_dict); 
        }                                                  
    
    }                                
    catch(...)                       
    {                                
        return_val =  py::object();      
        exception_occured = 1;       
    }                                
    /*cleanup code*/                     
    if(testset_used)
    {
        Py_XDECREF(py_testset);
        #undef TESTSET1
        #undef TESTSET2
        #undef TESTSET3
        #undef TESTSET4
    }
    if(result_used)
    {
        Py_XDECREF(py_result);
        #undef RESULT1
        #undef RESULT2
        #undef RESULT3
        #undef RESULT4
    }
    if(!(PyObject*)return_val && !exception_occured)
    {
                                  
        return_val = Py_None;            
    }
                                  
    return return_val.disown();           
}                                
static PyObject* run_kmeans(PyObject*self, PyObject* args, PyObject* kywds)
{
    py::object return_val;
    int exception_occured = 0;
    PyObject *py_local_dict = NULL;
    static char *kwlist[] = {"dataset","npts","dim","num_clusters","result","log_level","random_seed","algorithm","checks","cb_index","trees","branching","iterations","target_precision","centers_init","build_weight","memory_weight","sample_fraction","local_dict", NULL};
    PyObject *py_dataset, *py_npts, *py_dim, *py_num_clusters, *py_result, *py_log_level, *py_random_seed, *py_algorithm, *py_checks, *py_cb_index, *py_trees, *py_branching, *py_iterations, *py_target_precision, *py_centers_init, *py_build_weight, *py_memory_weight, *py_sample_fraction;
    int dataset_used, npts_used, dim_used, num_clusters_used, result_used, log_level_used, random_seed_used, algorithm_used, checks_used, cb_index_used, trees_used, branching_used, iterations_used, target_precision_used, centers_init_used, build_weight_used, memory_weight_used, sample_fraction_used;
    py_dataset = py_npts = py_dim = py_num_clusters = py_result = py_log_level = py_random_seed = py_algorithm = py_checks = py_cb_index = py_trees = py_branching = py_iterations = py_target_precision = py_centers_init = py_build_weight = py_memory_weight = py_sample_fraction = NULL;
    dataset_used= npts_used= dim_used= num_clusters_used= result_used= log_level_used= random_seed_used= algorithm_used= checks_used= cb_index_used= trees_used= branching_used= iterations_used= target_precision_used= centers_init_used= build_weight_used= memory_weight_used= sample_fraction_used = 0;
    
    if(!PyArg_ParseTupleAndKeywords(args,kywds,"OOOOOOOOOOOOOOOOOO|O:run_kmeans",kwlist,&py_dataset, &py_npts, &py_dim, &py_num_clusters, &py_result, &py_log_level, &py_random_seed, &py_algorithm, &py_checks, &py_cb_index, &py_trees, &py_branching, &py_iterations, &py_target_precision, &py_centers_init, &py_build_weight, &py_memory_weight, &py_sample_fraction, &py_local_dict))
       return NULL;
    try                              
    {                                
        py_dataset = py_dataset;
        PyArrayObject* dataset_array = convert_to_numpy(py_dataset,"dataset");
        conversion_numpy_check_type(dataset_array,PyArray_FLOAT,"dataset");
        #define DATASET1(i) (*((float*)(dataset_array->data + (i)*Sdataset[0])))
        #define DATASET2(i,j) (*((float*)(dataset_array->data + (i)*Sdataset[0] + (j)*Sdataset[1])))
        #define DATASET3(i,j,k) (*((float*)(dataset_array->data + (i)*Sdataset[0] + (j)*Sdataset[1] + (k)*Sdataset[2])))
        #define DATASET4(i,j,k,l) (*((float*)(dataset_array->data + (i)*Sdataset[0] + (j)*Sdataset[1] + (k)*Sdataset[2] + (l)*Sdataset[3])))
        npy_intp* Ndataset = dataset_array->dimensions;
        npy_intp* Sdataset = dataset_array->strides;
        int Ddataset = dataset_array->nd;
        float* dataset = (float*) dataset_array->data;
        dataset_used = 1;
        py_npts = py_npts;
        int npts = convert_to_int(py_npts,"npts");
        npts_used = 1;
        py_dim = py_dim;
        int dim = convert_to_int(py_dim,"dim");
        dim_used = 1;
        py_num_clusters = py_num_clusters;
        int num_clusters = convert_to_int(py_num_clusters,"num_clusters");
        num_clusters_used = 1;
        py_result = py_result;
        PyArrayObject* result_array = convert_to_numpy(py_result,"result");
        conversion_numpy_check_type(result_array,PyArray_FLOAT,"result");
        #define RESULT1(i) (*((float*)(result_array->data + (i)*Sresult[0])))
        #define RESULT2(i,j) (*((float*)(result_array->data + (i)*Sresult[0] + (j)*Sresult[1])))
        #define RESULT3(i,j,k) (*((float*)(result_array->data + (i)*Sresult[0] + (j)*Sresult[1] + (k)*Sresult[2])))
        #define RESULT4(i,j,k,l) (*((float*)(result_array->data + (i)*Sresult[0] + (j)*Sresult[1] + (k)*Sresult[2] + (l)*Sresult[3])))
        npy_intp* Nresult = result_array->dimensions;
        npy_intp* Sresult = result_array->strides;
        int Dresult = result_array->nd;
        float* result = (float*) result_array->data;
        result_used = 1;
        py_log_level = py_log_level;
        int log_level = convert_to_int(py_log_level,"log_level");
        log_level_used = 1;
        py_random_seed = py_random_seed;
        int random_seed = convert_to_int(py_random_seed,"random_seed");
        random_seed_used = 1;
        py_algorithm = py_algorithm;
        int algorithm = convert_to_int(py_algorithm,"algorithm");
        algorithm_used = 1;
        py_checks = py_checks;
        int checks = convert_to_int(py_checks,"checks");
        checks_used = 1;
        py_cb_index = py_cb_index;
        double cb_index = convert_to_float(py_cb_index,"cb_index");
        cb_index_used = 1;
        py_trees = py_trees;
        int trees = convert_to_int(py_trees,"trees");
        trees_used = 1;
        py_branching = py_branching;
        int branching = convert_to_int(py_branching,"branching");
        branching_used = 1;
        py_iterations = py_iterations;
        int iterations = convert_to_int(py_iterations,"iterations");
        iterations_used = 1;
        py_target_precision = py_target_precision;
        double target_precision = convert_to_float(py_target_precision,"target_precision");
        target_precision_used = 1;
        py_centers_init = py_centers_init;
        int centers_init = convert_to_int(py_centers_init,"centers_init");
        centers_init_used = 1;
        py_build_weight = py_build_weight;
        double build_weight = convert_to_float(py_build_weight,"build_weight");
        build_weight_used = 1;
        py_memory_weight = py_memory_weight;
        double memory_weight = convert_to_float(py_memory_weight,"memory_weight");
        memory_weight_used = 1;
        py_sample_fraction = py_sample_fraction;
        double sample_fraction = convert_to_float(py_sample_fraction,"sample_fraction");
        sample_fraction_used = 1;
        /*<function call here>*/     
        #line 107 "/home/marius/ubc/flann/src/python/pyflann/pyflann_base.py"
        FLANNParameters flannparams;
        flannparams.log_level = log_level; 
        flannparams.random_seed = random_seed; 
        flannparams.log_destination = NULL;IndexParameters idxparams;
        idxparams.algorithm = algorithm; 
        idxparams.checks = checks; 
        idxparams.cb_index = cb_index; 
        idxparams.trees = trees; 
        idxparams.branching = branching; 
        idxparams.iterations = iterations; 
        idxparams.target_precision = target_precision; 
        idxparams.centers_init = centers_init; 
        idxparams.build_weight = build_weight; 
        idxparams.memory_weight = memory_weight; 
        idxparams.sample_fraction = sample_fraction; 
        
                    return_val = flann_compute_cluster_centers(dataset, npts, dim, num_clusters, (float*)result, &idxparams, &flannparams);
        if(py_local_dict)                                  
        {                                                  
            py::dict local_dict = py::dict(py_local_dict); 
        }                                                  
    
    }                                
    catch(...)                       
    {                                
        return_val =  py::object();      
        exception_occured = 1;       
    }                                
    /*cleanup code*/                     
    if(dataset_used)
    {
        Py_XDECREF(py_dataset);
        #undef DATASET1
        #undef DATASET2
        #undef DATASET3
        #undef DATASET4
    }
    if(result_used)
    {
        Py_XDECREF(py_result);
        #undef RESULT1
        #undef RESULT2
        #undef RESULT3
        #undef RESULT4
    }
    if(!(PyObject*)return_val && !exception_occured)
    {
                                  
        return_val = Py_None;            
    }
                                  
    return return_val.disown();           
}                                


static PyMethodDef compiled_methods[] = 
{
    {"flatten_double2float",(PyCFunction)flatten_double2float , METH_VARARGS|METH_KEYWORDS},
    {"pyflann_build_index",(PyCFunction)pyflann_build_index , METH_VARARGS|METH_KEYWORDS},
    {"pyflann_free_index",(PyCFunction)pyflann_free_index , METH_VARARGS|METH_KEYWORDS},
    {"pyflann_find_nearest_neighbors",(PyCFunction)pyflann_find_nearest_neighbors , METH_VARARGS|METH_KEYWORDS},
    {"pyflann_find_nearest_neighbors_index",(PyCFunction)pyflann_find_nearest_neighbors_index , METH_VARARGS|METH_KEYWORDS},
    {"run_kmeans",(PyCFunction)run_kmeans , METH_VARARGS|METH_KEYWORDS},
    {NULL,      NULL}        /* Sentinel */
};

PyMODINIT_FUNC initpyflann_base_c(void)
{
    
    Py_Initialize();
    import_array();
    PyImport_ImportModule("numpy");
    (void) Py_InitModule("pyflann_base_c", compiled_methods);
}

#ifdef __CPLUSCPLUS__
}
#endif
