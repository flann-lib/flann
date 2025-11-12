# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FLANN (Fast Library for Approximate Nearest Neighbors) is a library for performing fast approximate nearest neighbor searches in high dimensional spaces. It contains a collection of optimized algorithms and a system for automatically choosing the best algorithm and parameters for a given dataset.

**Key Features:**
- Multiple search algorithms (KD-Tree, K-Means, LSH, Linear, Hierarchical, Composite, Autotuned)
- Template-based design with pluggable distance metrics
- Multi-language bindings (C++, C, Python, MATLAB, Ruby)
- Optional CUDA support for GPU acceleration
- Optional MPI support for distributed computing
- Index serialization/deserialization support

## Build System

This project uses CMake (minimum version 2.6).

### Basic Build Commands

```bash
# Standard build
mkdir build && cd build
cmake ..
make

# Build with specific options
cmake -DBUILD_PYTHON_BINDINGS=ON -DBUILD_CUDA_LIB=OFF ..
make
```

### Build Options (CMakeLists.txt:52-60)

- `BUILD_C_BINDINGS` - Build C bindings (default: ON)
- `BUILD_PYTHON_BINDINGS` - Build Python bindings (default: ON, requires C bindings)
- `BUILD_MATLAB_BINDINGS` - Build Matlab bindings (default: ON, requires C bindings)
- `BUILD_CUDA_LIB` - Build CUDA library (default: OFF)
- `BUILD_EXAMPLES` - Build examples (default: ON)
- `BUILD_TESTS` - Build tests (default: ON)
- `BUILD_DOC` - Build documentation (default: ON)
- `USE_OPENMP` - Use OpenMP multi-threading (default: ON)
- `USE_MPI` - Use MPI (default: OFF)

### Test Commands

```bash
# Run all tests
make test

# Run specific test types
make flann_gtests  # C++ Google Tests
make flann_ruby_spec  # Ruby tests (if C bindings enabled)

# Individual test executables are in test/ directory:
./test/flann_linear_test
./test/flann_kdtree_test
./test/flann_kmeans_test
./test/flann_kdtree_single_test
./test/flann_hierarchical_test
./test/flann_lsh_test
./test/flann_autotuned_test
./test/flann_multithreaded_test  # if OpenMP enabled
./test/flann_cuda_test  # if CUDA enabled

# Python tests (if Python bindings enabled)
python test/test_nn.py
python test/test_nn_index.py
python test/test_index_save.py
python test/test_nn_autotune.py
python test/test_clustering.py
```

**Note:** Tests require:
- GTest library for C++ tests
- HDF5 library for loading test data
- Test data files are auto-downloaded to test/ directory

## Architecture

### Core Design Pattern

FLANN uses a **template-based strategy pattern** where algorithms are templated on distance metrics:

```cpp
template<typename Distance>
class NNIndex {
    typedef typename Distance::ElementType ElementType;
    typedef typename Distance::ResultType DistanceType;
    // ...
};
```

All concrete index types (KDTreeIndex, KMeansIndex, etc.) inherit from `NNIndex<Distance>` in `src/cpp/flann/algorithms/nn_index.h`.

### Main Entry Point

The primary user-facing API is the `Index<Distance>` class in `src/cpp/flann/flann.hpp`:

- Facade over concrete algorithm implementations
- Factory pattern for algorithm selection via `create_index_by_type<Distance>()`
- Supports index persistence (save/load)
- Two main search operations: `knnSearch()` and `radiusSearch()`

### Algorithm Implementations

All algorithms are in `src/cpp/flann/algorithms/`:

| Algorithm | File | Use Case |
|-----------|------|----------|
| Linear Search | `linear_index.h` | Brute force, guaranteed exact results |
| KD-Tree | `kdtree_index.h` | Low-dimensional data (< 20 dims) |
| Single KD-Tree | `kdtree_single_index.h` | Low-dimensional, memory-efficient |
| K-Means Tree | `kmeans_index.h` | High-dimensional data |
| Hierarchical K-Means | `hierarchical_clustering_index.h` | Clustering and search |
| LSH | `lsh_index.h` | Very high-dimensional data, approximate |
| Composite | `composite_index.h` | Multiple KD-trees + k-means |
| Autotuned | `autotuned_index.h` | Automatic algorithm selection |

**GPU Support:**
- `kdtree_cuda_3d_index.h` / `.cu` - CUDA-accelerated 3D KD-tree (when `BUILD_CUDA_LIB=ON`)

### Key Utilities

- `src/cpp/flann/util/matrix.h` - Lightweight matrix wrapper (row-major)
- `src/cpp/flann/util/params.h` - Parameter passing via `std::map<std::string, any>`
- `src/cpp/flann/util/result_set.h` - Efficient result collection for searches
- `src/cpp/flann/util/heap.h` - Heap data structure for k-NN results
- `src/cpp/flann/algorithms/dist.h` - Distance metric implementations (L1, L2, Hamming, etc.)

### Distance Metrics

Distance functors define `ElementType` (data type) and `ResultType` (distance type). Common metrics include:
- `L2` / `L2_Simple` - Euclidean distance
- `L1` - Manhattan distance
- `MinkowskiDistance` - Generalized Minkowski
- `Hamming` - Hamming distance (binary data)
- `HellingerDistance`, `ChiSquareDistance`, `KL_Divergence` - Histogram comparisons

### Language Bindings

- **C Bindings:** `src/cpp/flann/flann.h` and `flann.cpp` - C API wrapper
- **Python:** `src/python/` - Wraps C API
- **MATLAB:** `src/matlab/` - MEX interface
- **Ruby:** `src/ruby/` - Ruby bindings

### Index Persistence

Indices can be saved to disk and reloaded:
```cpp
index.save("index_file.idx");
Index<L2<float>> loaded_index(SavedIndexParams("index_file.idx"), L2<float>());
```

File format includes header with index type, data type, and algorithm-specific state.

## Code Organization

```
src/cpp/flann/
├── flann.hpp          # Main C++ API (Index template class)
├── flann.h/.cpp       # C API wrapper
├── general.h          # FLANNException, type traits
├── defines.h          # Enum definitions (algorithm types, etc.)
├── algorithms/        # All search algorithm implementations
│   ├── nn_index.h     # Base class for all indices
│   ├── all_indices.h  # Includes all algorithm headers
│   ├── dist.h         # Distance metrics
│   └── ...
├── util/              # Utility classes
│   ├── matrix.h       # Matrix wrapper
│   ├── params.h       # IndexParams, SearchParams
│   ├── result_set.h   # Result collection
│   ├── heap.h         # Priority queue
│   └── ...
├── io/                # I/O utilities (HDF5 support)
├── nn/                # Nearest neighbor utilities
└── mpi/               # MPI support (when enabled)

test/                  # Test suite
examples/              # Usage examples
```

## Development Notes

### Adding New Tests

1. Add `.cpp` test file to `test/` directory
2. Use GTest framework: `#include <gtest/gtest.h>`
3. Link against HDF5 if loading test datasets
4. Register in `test/CMakeLists.txt` using `flann_add_gtest(target_name source.cpp)`

### Index Lifecycle

All indices follow this pattern:
1. **Construction** - Pass dataset matrix and parameters (e.g., `KDTreeIndexParams`)
2. **Building** - Call `buildIndex()` to construct search structures
3. **Searching** - Call `knnSearch()` or `radiusSearch()`
4. **Optional:** Add/remove points dynamically with `addPoints()`/`removePoint()`

### Parameter System

Parameters use a type-erased map (`std::map<std::string, any>`):
```cpp
IndexParams params;
params["algorithm"] = FLANN_INDEX_KDTREE;
params["trees"] = 4;
Index<L2<float>> index(dataset, params);
```

See `src/cpp/flann/util/params.h` for `SearchParams` and algorithm-specific parameter structs.

### Memory Management

- Index owns a copy of the dataset (or references user data)
- `Matrix<T>` is a non-owning view by default
- Use `Matrix<T>::release()` to relinquish ownership
- CUDA memory managed separately when GPU support enabled

## Dependencies

**Required:**
- C++ compiler with C++98 support (C++11 for some features)
- CMake >= 2.6

**Optional:**
- GTest - For running C++ tests
- HDF5 - For loading test datasets and examples
- OpenMP - For multi-threading support
- MPI + Boost (mpi, system, serialization, thread) - For distributed computing
- CUDA - For GPU acceleration
- **OpenCL** - For GPU acceleration (alternative to CUDA)
- Python - For Python bindings
- MATLAB - For MATLAB bindings

## OpenCL Support (Experimental GPU Acceleration)

### Overview

This fork includes OpenCL-accelerated implementations of nearest neighbor search algorithms for GPU acceleration. The OpenCL code was developed in 2017-2018 and has been modernized for OpenCL 3.0 compatibility.

**Supported Algorithms:**
- **K-Means Index** (`FLANN_INDEX_KMEANS_OPENCL`) - Hierarchical k-means with GPU acceleration
- **Hierarchical Clustering** (`FLANN_INDEX_HIERARCHICAL_OPENCL`) - GPU-accelerated clustering

**Performance Characteristics:**
- Best for large datasets (>50K points) and high dimensions (>64D)
- Typical speedup: 5-20x vs multi-core CPU for large datasets
- Overhead: ~0.3-1.0s kernel compilation + data transfer
- Precision: 92-98% recall (comparable to CPU versions)

### Building with OpenCL

```bash
# Install OpenCL development headers (Ubuntu/Debian)
sudo apt-get install ocl-icd-opencl-dev opencl-headers clinfo

# Verify OpenCL devices
clinfo  # Should show your GPU

# Build with OpenCL support
mkdir build && cd build
cmake -DBUILD_OpenCL_LIB=ON \
      -DBUILD_TESTS=ON \
      ..
make -j$(nproc)
```

### System Requirements

**Hardware:**
- OpenCL 1.2+ compatible device (GPU, CPU, or accelerator)
- Minimum 2GB device memory (4GB+ recommended)
- Tested platforms:
  - NVIDIA GPUs (Tesla T4, RTX series) with CUDA OpenCL backend
  - AMD GPUs with ROCm OpenCL
  - Intel integrated/discrete GPUs

**Software:**
```bash
# Ubuntu/Debian
sudo apt-get install ocl-icd-opencl-dev opencl-headers

# Fedora/RHEL
sudo dnf install ocl-icd-devel opencl-headers

# Verify installation
clinfo | grep "Platform Name"
```

### Usage Example

```cpp
#include <flann/flann.hpp>

// Load your dataset
flann::Matrix<float> dataset = ...;  // Your data (N x D)

// Create OpenCL-accelerated K-Means index
flann::Index<flann::L2<float>> index(
    dataset,
    flann::KMeansOpenCLIndexParams(
        32,    // branching factor
        11,    // iterations
        flann::FLANN_CENTERS_RANDOM,
        0.2    // cb_index
    )
);

index.buildIndex();  // Builds index structure

// Perform search (automatically uses GPU)
flann::Matrix<float> queries = ...;      // Query vectors
flann::Matrix<int> indices(queries.rows, 10);    // k=10
flann::Matrix<float> distances(queries.rows, 10);

index.knnSearch(queries, indices, distances, 10,
                flann::SearchParams(128));  // checks parameter
```

### Performance Guidelines

**When to Use OpenCL:**
- ✅ Large datasets (>50,000 points)
- ✅ High dimensions (>64D)
- ✅ Batch queries (>100 queries)
- ✅ GPU available with sufficient memory

**When NOT to Use OpenCL:**
- ❌ Small datasets (<10,000 points) - overhead dominates
- ❌ Few queries (<10) - transfer cost not amortized
- ❌ No GPU available or insufficient memory

**Typical Performance (SIFT128D, Tesla T4):**
- 10K points: ~0.15s build, ~0.01s search (1000 queries)
- 100K points: ~0.6s build, ~0.01s search (1000 queries)
- Speedup vs CPU: 5-15x for search, 2-5x for build

### Device Information

The library automatically logs device capabilities at runtime:
```
[FLANN OpenCL] Device: Tesla T4
[FLANN OpenCL] OpenCL Version: OpenCL 3.0 CUDA
[FLANN OpenCL] Max Work Group Size: 1024
[FLANN OpenCL] Max Compute Units: 40
```

### Troubleshooting

**Build Issues:**

*Error: "CL/opencl.h not found"*
```bash
sudo apt-get install ocl-icd-opencl-dev opencl-headers
```

*Error: "No OpenCL platforms found"*
- Verify drivers: `clinfo`
- Install GPU drivers (NVIDIA, AMD, or Intel)
- For CPU fallback: `sudo apt-get install pocl-opencl-icd`

**Runtime Issues:**

*OpenCL error at initialization:*
- Check GPU memory: `nvidia-smi` (NVIDIA) or `radeontop` (AMD)
- Verify device is accessible: `clinfo`
- Try CPU OpenCL device if GPU fails

*Poor performance:*
- Ensure using GPU device (check logged device name)
- Small datasets have overhead that dominates - use CPU version
- Profile GPU utilization: `nvidia-smi -l 1` during search

*Kernel compilation errors:*
- Check OpenCL version compatibility (code targets 1.2+)
- Review kernel build logs in error messages
- Some older GPUs may have work group size limitations

**Known Limitations:**

1. **Cleanup Segfault:** Tests may segfault during global teardown (AFTER completion). This does not affect correctness or functionality - it's a destructor exception issue in C++11+ mode.

2. **Memory Overhead:** Dataset is duplicated in GPU memory. Large datasets may exceed GPU memory limits.

3. **Binary Format:** OpenCL kernels are compiled at runtime. First search incurs ~0.3-1.0s compilation overhead.

### Implementation Details

**Files:**
- `src/cpp/flann/algorithms/kmeans_opencl_index.h` - K-Means OpenCL implementation (~877 lines)
- `src/cpp/flann/algorithms/hierarchical_opencl_index.h` - Hierarchical clustering (~884 lines)
- `src/cpp/flann/algorithms/nn_opencl_index.h` - Base OpenCL infrastructure (~1,279 lines)

**Design:**
- Template-based like CPU versions
- Automatic kernel generation based on distance metric and parameters
- Uses OpenCL 1.2 API with 3.0 compatibility fixes
- Work group sizes automatically tuned to device capabilities

### References

- OpenCL Specification: https://www.khronos.org/opencl/
- FLANN Paper: Muja & Lowe, "Fast Approximate Nearest Neighbors with Automatic Algorithm Configuration", VISAPP 2009
- This fork: Based on 2017-2018 OpenCL implementation, modernized 2024
