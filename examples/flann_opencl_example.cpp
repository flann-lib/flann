/*
 * FLANN OpenCL Example
 *
 * Demonstrates CPU vs OpenCL K-Means performance comparison.
 * No external data files required - generates synthetic SIFT-like descriptors.
 *
 * NOTE: Performance results depend heavily on:
 * - Dataset characteristics (real vs synthetic data)
 * - Dataset size (larger datasets show better GPU utilization)
 * - Query batch size (more queries amortize OpenCL overhead)
 * For optimal performance, use datasets >50K points with batch queries >100.
 *
 * Usage:
 *   ./flann_opencl_example [dataset_size] [query_count]
 *
 * Example:
 *   ./flann_opencl_example 100000 1000
 *
 * Author: FLANN OpenCL (modernized 2024)
 */

#define FLANN_USE_OPENCL
#include <flann/flann.hpp>
#include <iostream>
#include <iomanip>
#include <chrono>
#include <vector>
#include <cstdlib>
#include <ctime>

using namespace flann;
using namespace std;

// Timing helper
class Timer {
    chrono::high_resolution_clock::time_point start;
public:
    Timer() : start(chrono::high_resolution_clock::now()) {}

    double elapsed() const {
        auto end = chrono::high_resolution_clock::now();
        return chrono::duration_cast<chrono::duration<double>>(end - start).count();
    }

    void reset() {
        start = chrono::high_resolution_clock::now();
    }
};

// Generate random SIFT-like descriptors
void generate_random_data(float* data, size_t count) {
    for (size_t i = 0; i < count; ++i) {
        data[i] = static_cast<float>(rand()) / RAND_MAX;
    }
}

// Calculate precision (percentage of matching indices)
double calculate_precision(const int* indices_cpu, const int* indices_opencl, size_t queries, int knn) {
    int matches = 0;
    int total = queries * knn;

    for (size_t i = 0; i < queries; ++i) {
        for (int j = 0; j < knn; ++j) {
            int cpu_idx = indices_cpu[i * knn + j];
            // Check if this index appears anywhere in OpenCL results for this query
            for (int k = 0; k < knn; ++k) {
                if (cpu_idx == indices_opencl[i * knn + k]) {
                    matches++;
                    break;
                }
            }
        }
    }

    return static_cast<double>(matches) / total * 100.0;
}

int main(int argc, char** argv) {
    // Parse command line arguments
    size_t dataset_size = 100000;  // Default: 100K points
    size_t query_count = 1000;     // Default: 1000 queries

    if (argc >= 2) {
        dataset_size = atoi(argv[1]);
    }
    if (argc >= 3) {
        query_count = atoi(argv[2]);
    }

    const size_t dim = 128;        // SIFT descriptor dimensionality
    const int knn = 10;            // k nearest neighbors
    const int checks = 128;        // Approximate search parameter

    // Header
    cout << "============================================" << endl;
    cout << "FLANN OpenCL Example" << endl;
    cout << "============================================" << endl;
    cout << "Dataset: " << dataset_size << " points x " << dim << " dimensions" << endl;
    cout << "Queries: " << query_count << " x " << knn << " neighbors" << endl;
    cout << "Checks:  " << checks << " (approximate search parameter)" << endl;
    cout << endl;

    // Seed random number generator
    srand(static_cast<unsigned int>(time(NULL)));

    // Generate random dataset (SIFT-like descriptors)
    cout << "Generating random dataset..." << flush;
    vector<float> dataset_data(dataset_size * dim);
    generate_random_data(dataset_data.data(), dataset_size * dim);
    Matrix<float> dataset(dataset_data.data(), dataset_size, dim);
    cout << " done" << endl;

    // Generate random queries
    cout << "Generating random queries..." << flush;
    vector<float> queries_data(query_count * dim);
    generate_random_data(queries_data.data(), query_count * dim);
    Matrix<float> queries(queries_data.data(), query_count, dim);
    cout << " done" << endl;

    cout << endl;

    // ====================
    // CPU K-Means Index
    // ====================
    cout << "--- CPU K-Means Index ---" << endl;

    Timer timer;

    cout << "Building index..." << flush;
    KMeansIndexParams cpu_params(32, 11, FLANN_CENTERS_RANDOM, 0.2);
    Index<L2<float>> cpu_index(dataset, cpu_params);
    cpu_index.buildIndex();
    double cpu_build_time = timer.elapsed();
    cout << " done (" << fixed << setprecision(3) << cpu_build_time << " s)" << endl;

    // Allocate result matrices
    vector<int> cpu_indices_data(query_count * knn);
    vector<float> cpu_distances_data(query_count * knn);
    Matrix<int> cpu_indices(cpu_indices_data.data(), query_count, knn);
    Matrix<float> cpu_distances(cpu_distances_data.data(), query_count, knn);

    cout << "Searching..." << flush;
    timer.reset();
    cpu_index.knnSearch(queries, cpu_indices, cpu_distances, knn, SearchParams(checks));
    double cpu_search_time = timer.elapsed();
    cout << " done (" << fixed << setprecision(3) << cpu_search_time << " s)" << endl;

    double cpu_per_query = cpu_search_time * 1000.0 / query_count;
    cout << "Time per query: " << fixed << setprecision(3) << cpu_per_query << " ms" << endl;
    cout << "Total time:     " << fixed << setprecision(3) << (cpu_build_time + cpu_search_time) << " s" << endl;

    cout << endl;

    // ====================
    // OpenCL K-Means Index
    // ====================
    cout << "--- OpenCL K-Means Index ---" << endl;

    timer.reset();

    cout << "Building index..." << flush;
    KMeansOpenCLIndexParams opencl_params(32, 11, FLANN_CENTERS_RANDOM, 0.2);
    Index<L2<float>> opencl_index(dataset, opencl_params);
    opencl_index.buildIndex();
    double opencl_build_time = timer.elapsed();
    cout << " done (" << fixed << setprecision(3) << opencl_build_time << " s)" << endl;

    // Allocate result matrices
    vector<int> opencl_indices_data(query_count * knn);
    vector<float> opencl_distances_data(query_count * knn);
    Matrix<int> opencl_indices(opencl_indices_data.data(), query_count, knn);
    Matrix<float> opencl_distances(opencl_distances_data.data(), query_count, knn);

    cout << "Searching..." << flush;
    timer.reset();
    opencl_index.knnSearch(queries, opencl_indices, opencl_distances, knn, SearchParams(checks));
    double opencl_search_time = timer.elapsed();
    cout << " done (" << fixed << setprecision(3) << opencl_search_time << " s)" << endl;

    double opencl_per_query = opencl_search_time * 1000.0 / query_count;
    cout << "Time per query: " << fixed << setprecision(3) << opencl_per_query << " ms" << endl;
    cout << "Total time:     " << fixed << setprecision(3) << (opencl_build_time + opencl_search_time) << " s" << endl;

    cout << endl;

    // ====================
    // Performance Comparison
    // ====================
    cout << "============================================" << endl;
    cout << "Performance Comparison" << endl;
    cout << "============================================" << endl;

    double build_speedup = cpu_build_time / opencl_build_time;
    double search_speedup = cpu_search_time / opencl_search_time;
    double total_speedup = (cpu_build_time + cpu_search_time) / (opencl_build_time + opencl_search_time);

    cout << "Build Time:" << endl;
    cout << "  CPU:    " << fixed << setprecision(3) << cpu_build_time << " s" << endl;
    cout << "  OpenCL: " << fixed << setprecision(3) << opencl_build_time << " s" << endl;
    cout << "  Speedup: " << fixed << setprecision(2) << build_speedup << "x";
    if (build_speedup < 1.0) {
        cout << " (CPU faster)";
    }
    cout << endl << endl;

    cout << "Search Time (" << query_count << " queries):" << endl;
    cout << "  CPU:    " << fixed << setprecision(3) << cpu_search_time << " s ("
         << setprecision(3) << cpu_per_query << " ms/query)" << endl;
    cout << "  OpenCL: " << fixed << setprecision(3) << opencl_search_time << " s ("
         << setprecision(3) << opencl_per_query << " ms/query)" << endl;
    cout << "  Speedup: " << fixed << setprecision(2) << search_speedup << "x" << endl << endl;

    cout << "Total Time (build + search):" << endl;
    cout << "  CPU:    " << fixed << setprecision(3) << (cpu_build_time + cpu_search_time) << " s" << endl;
    cout << "  OpenCL: " << fixed << setprecision(3) << (opencl_build_time + opencl_search_time) << " s" << endl;
    cout << "  Speedup: " << fixed << setprecision(2) << total_speedup << "x" << endl << endl;

    // Calculate precision (how similar are the results?)
    double precision = calculate_precision(
        cpu_indices_data.data(),
        opencl_indices_data.data(),
        query_count,
        knn
    );

    cout << "Result Agreement: " << fixed << setprecision(2) << precision << "%" << endl;
    cout << "(Percentage of neighbors that match between CPU and OpenCL)" << endl;
    cout << endl;

    // ====================
    // Recommendations
    // ====================
    cout << "============================================" << endl;
    cout << "Recommendations" << endl;
    cout << "============================================" << endl;

    if (search_speedup >= 3.0) {
        cout << "✓ OpenCL provides significant speedup (" << fixed << setprecision(1)
             << search_speedup << "x)" << endl;
        cout << "  Recommendation: Use OpenCL for this dataset size" << endl;
    } else if (search_speedup >= 1.5) {
        cout << "✓ OpenCL provides moderate speedup (" << fixed << setprecision(1)
             << search_speedup << "x)" << endl;
        cout << "  Recommendation: Use OpenCL if GPU available" << endl;
    } else if (search_speedup >= 1.0) {
        cout << "⚠ OpenCL provides minimal speedup (" << fixed << setprecision(1)
             << search_speedup << "x)" << endl;
        cout << "  Recommendation: Either CPU or OpenCL acceptable" << endl;
    } else {
        cout << "⚠ CPU is faster for this dataset size" << endl;
        cout << "  Recommendation: Use CPU (OpenCL overhead dominates)" << endl;
        cout << endl;
        cout << "  Try larger datasets (>50K points) or more queries" << endl;
        cout << "  for OpenCL to show benefits." << endl;
    }

    cout << endl;

    if (precision >= 95.0) {
        cout << "✓ Results have excellent agreement (" << fixed << setprecision(1)
             << precision << "%)" << endl;
    } else if (precision >= 90.0) {
        cout << "✓ Results have good agreement (" << fixed << setprecision(1)
             << precision << "%)" << endl;
    } else {
        cout << "⚠ Results have lower agreement (" << fixed << setprecision(1)
             << precision << "%)" << endl;
        cout << "  Note: This is expected for approximate algorithms with" << endl;
        cout << "  randomized initialization. Both are valid results." << endl;
    }

    cout << endl;
    cout << "============================================" << endl;
    cout << "Example Complete" << endl;
    cout << "============================================" << endl;

    return 0;
}
