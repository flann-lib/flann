FLANN - Fast Library for Approximate Nearest Neighbors
======================================================

FLANN is a library for performing fast approximate nearest neighbor searches in high dimensional spaces. It contains a collection of algorithms we found to work best for nearest neighbor search and a system for automatically choosing the best algorithm and optimum parameters depending on the dataset.
FLANN is written in C++ and contains bindings for the following languages: C, MATLAB and Python.


Documentation
-------------

Check FLANN web page [here](http://www.cs.ubc.ca/~mariusm/flann).

Documentation on how to use the library can be found in the doc/manual.pdf file included in the release archives.

More information and experimental results can be found in the following paper:

  * Marius Muja and David G. Lowe, "Fast Approximate Nearest Neighbors with Automatic Algorithm Configuration", in International Conference on Computer Vision Theory and Applications (VISAPP'09), 2009 [(PDF)](http://people.cs.ubc.ca/~mariusm/uploads/FLANN/flann_visapp09.pdf) [(BibTex)](http://people.cs.ubc.ca/~mariusm/index.php/FLANN/BibTex)


Getting FLANN
-------------

The latest version of FLANN can be downloaded from here:

 *  Version 1.6.11 (26 June 2011)
    [flann-1.6.11-src.zip](http://people.cs.ubc.ca/~mariusm/uploads/FLANN/flann-1.6.11-src.zip) (Source code)  
    [User manual](http://people.cs.ubc.ca/~mariusm/uploads/FLANN/flann_manual-1.6.11.pdf)  
    [Changelog](https://github.com/mariusmuja/flann/blob/master/ChangeLog)  

If you want to try out the latest changes or contribute to FLANN, then it's recommended that you checkout the git source repository: `git clone git://github.com/mariusmuja/flann.git`

If you just want to browse the repository, you can do so by going [here](https://github.com/mariusmuja/flann).


Compiling FLANN with multithreading support
------------------------------------------

Make sure you have Intel Threading Building Blocks installed. You can get the latest version from www.threadingbuildingblocks.org. Alternatively you can also get it from package manager (this will probably not be the latest version, e.g. on Ubuntu 10.04 LTS only version 2.2 is found this way).

For CMake to be able to detect the installation of Intel TBB, you need to have a tbb.pc in one of the directories of your PKG_CONFIG_PATH, it should look somewhat like this:
    _________________________________________________

    tbb.pc
    _________________________________________________

    prefix=/usr
    exec_prefix=${prefix}
    libdir=${exec_prefix}/lib
    includedir=${prefix}/include

    Name: Threading Building Blocks
    Description: Intel's parallelism library for C++
    URL: http://www.threadingbuildingblocks.org/
    Version: 3.0update7
    Libs: -L${libdir} -ltbb
    Cflags: -I${includedir} 
    _________________________________________________


Using multithreaded FLANN in your project
-----------------------------------------

When multithreaded FLANN is compiled and installed, all you need to do now is compile your project with the -DTBB compiler flag to enable multithreading support. For example; in CMake you can achieve this by stating "ADD_DEFINITIONS(-DTBB)" for your target.

Have a look at the "flann::Index::knnSearch" section in the manual on how to specify the number of cores for knn- and radiussearch.


Conditions of use
-----------------

FLANN is distributed under the terms of the [BSD License](https://github.com/mariusmuja/flann/blob/master/COPYING).

Bug reporting
-------------

Please report bugs or feature requests using [github's issue tracker](http://github.com/mariusmuja/flann/issues).
