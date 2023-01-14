/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2011       Andreas Muetzel (amuetzel@uni-koblenz.de). All rights reserved.
 *
 * THE BSD LICENSE
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *************************************************************************/

#ifndef FLANN_CUDA_KD_TREE_BUILDER_H_
#define FLANN_CUDA_KD_TREE_BUILDER_H_
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include <thrust/partition.h>
#include <thrust/unique.h>
#include <thrust/scan.h>
#include <thrust/execution_policy.h>
#include <flann/util/cutil_math.h>
#include <stdlib.h>

// #define PRINT_DEBUG_TIMING

namespace flann
{
//      template< typename T >
//      void print_vector(  const flann::cuda::device_vector_noinit<T>& v )
//      {
//              for( int i=0; i< v.size(); i++ )
//              {
//                      std::cout<<v[i]<<std::endl;
//              }
//      }
//
//      template< typename T1, typename T2 >
//      void print_vector(  const flann::cuda::device_vector_noinit<T1>& v1, const flann::cuda::device_vector_noinit<T2>& v2 )
//      {
//              for( int i=0; i< v1.size(); i++ )
//              {
//                      std::cout<<i<<": "<<v1[i]<<" "<<v2[i]<<std::endl;
//              }
//      }
//
//      template< typename T1, typename T2, typename T3 >
//      void print_vector(  const flann::cuda::device_vector_noinit<T1>& v1, const flann::cuda::device_vector_noinit<T2>& v2, const flann::cuda::device_vector_noinit<T3>& v3 )
//      {
//              for( int i=0; i< v1.size(); i++ )
//              {
//                      std::cout<<i<<": "<<v1[i]<<" "<<v2[i]<<" "<<v3[i]<<std::endl;
//              }
//      }
//
//      template< typename T >
//      void print_vector_by_index(  const flann::cuda::device_vector_noinit<T>& v,const flann::cuda::device_vector_noinit<int>& ind )
//      {
//              for( int i=0; i< v.size(); i++ )
//              {
//                      std::cout<<v[ind[i]]<<std::endl;
//              }
//      }

//      std::ostream& operator <<(std::ostream& stream, const cuda::kd_tree_builder_detail::SplitInfo& s) {
//      stream<<"(split l/r: "<< s.left <<" "<< s.right<< "  split:"<<s.split_dim<<" "<<s.split_val<<")";
//      return stream;
// }
//
//
// std::ostream& operator <<(std::ostream& stream, const cuda::kd_tree_builder_detail::NodeInfo& s) {
//      stream<<"(node: "<<s.child1()<<" "<<s.parent()<<" "<<s.child2()<<")";
//      return stream;
// }
//
// std::ostream& operator <<(std::ostream& stream, const float4& s) {
//      stream<<"("<<s.x<<","<<s.y<<","<<s.z<<","<<s.w<<")";
//      return stream;
// }
namespace cuda
{
	// flann::cuda::device_vector_noinit is used to take place of thrust::device_vector
	// as thrust::device_vector always uses default stream, and always contains a fill
	template<typename T>
	class device_vector_noinit
	{
	private:
		thrust::device_ptr<T> m_ptr;
		size_t m_size;

	public:
		device_vector_noinit()
		{
			m_size = 0;
		}

		~device_vector_noinit()
		{
			if (m_size)
				thrust::device_free(m_ptr);
			m_size = 0;
		}

		device_vector_noinit(size_t s)
		{
			m_size = s;
			if (s)
				m_ptr = thrust::device_malloc<T>(s);
		}

		template<typename DerivedPolicy>
		device_vector_noinit(const thrust::detail::execution_policy_base<DerivedPolicy> &exec, size_t s, T t)
		{
			m_size = s;
			if (s)
			{
				m_ptr = thrust::device_malloc<T>(s);
				thrust::fill(exec, m_ptr, m_ptr + m_size, t);
			}
		}

		size_t size() const
		{
			return m_size;
		}

		void resize(size_t s)
		{
			if (m_size)
				thrust::device_free(m_ptr);
			m_size = s;
			if (s)
				m_ptr = thrust::device_malloc<T>(s);
		}

		template<typename DerivedPolicy>
		void append(const thrust::detail::execution_policy_base<DerivedPolicy> &exec, size_t n, T t)
		{
			if (n == 0)
				return;

			if (m_size)
			{
				thrust::device_ptr<T> new_ptr = thrust::device_malloc<T>(m_size + n);

				thrust::copy(exec, m_ptr, m_ptr + m_size, new_ptr);
				thrust::fill(exec, new_ptr + m_size, new_ptr + m_size + n, t);

				thrust::device_free(m_ptr);
				m_ptr = new_ptr;

				m_size = m_size + n;
			}
			else
			{
				resize(n);
				thrust::fill(exec, m_ptr, m_ptr + n, t);
				m_size = n;
			}
		}

		thrust::device_ptr<T> begin() const
		{
			return m_ptr;
		}

		thrust::device_ptr<T> end() const
		{
			return m_ptr + m_size;
		}

		auto back() const
		{
			return m_ptr[m_size - 1];
		}

		auto operator [] (const size_t i) const
		{
			return m_ptr[i];
		}
	};


namespace kd_tree_builder_detail
{
//! normal node: contains the split dimension and value
//! leaf node: left == index of first points, right==index of last point +1
struct SplitInfo
{
    union {
        struct
        {
            // begin of child nodes
            int left;
            // end of child nodes
            int right;
        };
        struct
        {
            int split_dim;
            float split_val;
        };
    };

};

struct IsEven
{
    typedef int result_type;
    __device__
    int operator()(int i )
    {
        return (i& 1)==0;
    }
};

struct SecondElementIsEven
{
    __host__ __device__
    bool operator()( const thrust::tuple<int,int>& i )
    {
        return (thrust::get<1>(i)& 1)==0;
    }
};

//! just for convenience: access a float4 by an index in [0,1,2]
//! (casting it to a float* and accessing it by the index is way slower...)
__host__ __device__
float get_value_by_index( const float4& f, int i )
{
    switch(i) {
    case 0:
        return f.x;
    case 1:
        return f.y;
    default:
        return f.z;
    }

}

//! mark a point as belonging to the left or right child of its current parent
//! called after parents are split
struct MovePointsToChildNodes
{
    MovePointsToChildNodes( int* child1, SplitInfo* splits, float* x, float* y, float* z, int* ox, int* oy, int* oz, int* lrx, int* lry, int* lrz )
        : child1_(child1), splits_(splits), x_(x), y_(y), z_(z), ox_(ox), oy_(oy), oz_(oz), lrx_(lrx), lry_(lry), lrz_(lrz){}
    //  int dim;
    //  float threshold;
    int* child1_;
    SplitInfo* splits_;

    // coordinate values
    float* x_, * y_, * z_;
    // owner indices -> which node does the point belong to?
    int* ox_, * oy_, * oz_;
    // temp info: will be set to 1 of a point is moved to the right child node, 0 otherwise
    // (used later in the scan op to separate the points of the children into continuous ranges)
    int* lrx_, * lry_, * lrz_;
    __device__
    void operator()( const thrust::tuple<int, int, int, int>& data )
    {
        int index = thrust::get<0>(data);
        int owner = ox_[index]; // before a split, all points at the same position in the index array have the same owner
        int point_ind1=thrust::get<1>(data);
        int point_ind2=thrust::get<2>(data);
        int point_ind3=thrust::get<3>(data);
        int leftChild=child1_[owner];
        int split_dim;
        float dim_val1, dim_val2, dim_val3;
        SplitInfo split;
        lrx_[index]=0;
        lry_[index]=0;
        lrz_[index]=0;
        // this element already belongs to a leaf node -> everything alright, no need to change anything
        if( leftChild==-1 ) {
            return;
        }
        // otherwise: load split data, and assign this index to the new owner
        split = splits_[owner];
        split_dim=split.split_dim;
        switch( split_dim ) {
        case 0:
            dim_val1=x_[point_ind1];
            dim_val2=x_[point_ind2];
            dim_val3=x_[point_ind3];
            break;
        case 1:
            dim_val1=y_[point_ind1];
            dim_val2=y_[point_ind2];
            dim_val3=y_[point_ind3];
            break;
        default:
            dim_val1=z_[point_ind1];
            dim_val2=z_[point_ind2];
            dim_val3=z_[point_ind3];
            break;

        }


        int r1=leftChild +(dim_val1 > split.split_val);
        ox_[index]=r1;
        int r2=leftChild+(dim_val2 > split.split_val);
        oy_[index]=r2;
        oz_[index]=leftChild+(dim_val3 > split.split_val);

        lrx_[index] = (dim_val1 > split.split_val);
        lry_[index] = (dim_val2 > split.split_val);
        lrz_[index] = (dim_val3 > split.split_val);
        //                      return thrust::make_tuple( r1, r2, leftChild+(dim_val > split.split_val) );
    }
};

//! used to update the left/right pointers and aabb infos after the node splits
struct SetLeftAndRightAndAABB
{
    int maxPoints;
    int nElements;

    SplitInfo* nodes;
    int* counts;
    int* labels;
    float4* aabbMin;
    float4* aabbMax;
    const float* x,* y,* z;
    const int* ix, * iy, * iz;

    __host__ __device__
    void operator()( int i )
    {
        int index=labels[i];
        int right;
        int left = counts[i];
        nodes[index].left=left;
        if( i < nElements-1 ) {
            right=counts[i+1];
        }
        else { // index==nNodes
            right=maxPoints;
        }
        nodes[index].right=right;
        aabbMin[index].x=x[ix[left]];
        aabbMin[index].y=y[iy[left]];
        aabbMin[index].z=z[iz[left]];
        aabbMax[index].x=x[ix[right-1]];
        aabbMax[index].y=y[iy[right-1]];
        aabbMax[index].z=z[iz[right-1]];
    }
};


//! - decide whether a node has to be split
//! if yes:
//! - allocate child nodes
//! - set split axis as axis of maximum aabb length
struct SplitNodes
{
    int maxPointsPerNode;
    int* node_count;
    int* nodes_allocated;
    int* out_of_space;
    int* child1_;
    int* parent_;
    SplitInfo* splits;

    __device__
    void operator()( thrust::tuple<int&, int&,SplitInfo&,float4&,float4&, int> node ) // float4: aabbMin, aabbMax
    {
        int& parent=thrust::get<0>(node);
        int& child1=thrust::get<1>(node);
        SplitInfo& s=thrust::get<2>(node);
        const float4& aabbMin=thrust::get<3>(node);
        const float4& aabbMax=thrust::get<4>(node);
        int my_index = thrust::get<5>(node);
        bool split_node=false;
        // first, each thread block counts the number of nodes that it needs to allocate...
        __shared__ int block_nodes_to_allocate;
        if( threadIdx.x== 0 ) block_nodes_to_allocate=0;
        __syncthreads();

        // don't split if all points are equal
        // (could lead to an infinite loop, and doesn't make any sense anyway)
        bool all_points_in_node_are_equal=aabbMin.x == aabbMax.x && aabbMin.y==aabbMax.y && aabbMin.z==aabbMax.z;

        int offset_to_global=0;

        // maybe this could be replaced with a reduction...
        if(( child1==-1) &&( s.right-s.left > maxPointsPerNode) && !all_points_in_node_are_equal ) { // leaf node
            split_node=true;
            offset_to_global = atomicAdd( &block_nodes_to_allocate,2 );
        }

        __syncthreads();
        __shared__ int block_left;
        __shared__ bool enough_space;
        // ... then the first thread tries to allocate this many nodes...
        if( threadIdx.x==0) {
            block_left = atomicAdd( node_count, block_nodes_to_allocate );
            enough_space = block_left+block_nodes_to_allocate < *nodes_allocated;
            // if it doesn't succeed, no nodes will be created by this block
            if( !enough_space ) {
                atomicAdd( node_count, -block_nodes_to_allocate );
                *out_of_space=1;
            }
        }

        __syncthreads();
        // this thread needs to split it's node && there was enough space for all the nodes
        // in this block.
        //(The whole "allocate-per-block-thing" is much faster than letting each element allocate
        // its space on its own, because shared memory atomics are A LOT faster than
        // global mem atomics!)
        if( split_node && enough_space ) {
            int left = block_left + offset_to_global;

            splits[left].left=s.left;
            splits[left].right=s.right;
            splits[left+1].left=0;
            splits[left+1].right=0;

            // split axis/position: middle of longest aabb extent
            float4 aabbDim=aabbMax-aabbMin;
            int maxDim=0;
            float maxDimLength=aabbDim.x;
            float4 splitVal=(aabbMax+aabbMin);
            splitVal*=0.5f;
            for( int i=1; i<=2; i++ ) {
                float val = get_value_by_index(aabbDim,i);
                if( val > maxDimLength ) {
                    maxDim=i;
                    maxDimLength=val;
                }
            }
            s.split_dim=maxDim;
            s.split_val=get_value_by_index(splitVal,maxDim);

            child1_[my_index]=left;
            splits[my_index]=s;

            parent_[left]=my_index;
            parent_[left+1]=my_index;
            child1_[left]=-1;
            child1_[left+1]=-1;
        }
    }
};


//! computes the scatter target address for the split operation, see Sengupta,Harris,Zhang,Owen: Scan Primitives for GPU Computing
//! in my use case, this is about 2x as fast as thrust::partition
struct set_addr3
{
    const int* val_, * f_;

    int npoints_;
    __device__
    int operator()( int id )
    {
        int nf = f_[npoints_-1] + (val_[npoints_-1]);
        int f=f_[id];
        int t = id -f+nf;
        return val_[id] ? f : t;
    }
};

//! converts a float4 point (xyz) to a tuple of three float vals (used to separate the
//! float4 input buffer into three arrays in the beginning of the tree build)
struct pointxyz_to_px_py_pz
{
    __device__
    thrust::tuple<float,float,float> operator()( const float4& val )
    {
        return thrust::make_tuple(val.x, val.y, val.z);
    }
};
} // namespace kd_tree_builder_detail

} // namespace cuda


std::ostream& operator <<(std::ostream& stream, const cuda::kd_tree_builder_detail::SplitInfo& s)
{
    stream<<"(split l/r: "<< s.left <<" "<< s.right<< "  split:"<<s.split_dim<<" "<<s.split_val<<")";
    return stream;
}
class CudaKdTreeBuilder
{
public:
    CudaKdTreeBuilder( const flann::cuda::device_vector_noinit<float4>& points, int max_leaf_size, cudaStream_t stream ) : /*out_of_space_(1,0),node_count_(1,1),*/ max_leaf_size_(max_leaf_size)
    {
        points_=&points;
	gpu_stream = stream;
        int prealloc = max((int)points.size()/max_leaf_size_*16, 1);
	thrust::host_vector<int> alloc_info(3);
	alloc_info[0] = 1;
	alloc_info[1] = prealloc;
	alloc_info[2] = 0;
	allocation_info_.resize(3);
	thrust::detail::two_system_copy(thrust::host, thrust::cuda::par.on(gpu_stream), alloc_info.begin(), alloc_info.end(), allocation_info_.begin());

        //              std::cout<<points_->size()<<std::endl;

	child1_ = new flann::cuda::device_vector_noinit<int>(thrust::cuda::par.on(gpu_stream), prealloc, -1);
	parent_ = new flann::cuda::device_vector_noinit<int>(thrust::cuda::par.on(gpu_stream), prealloc, -1);
	cuda::kd_tree_builder_detail::SplitInfo s;
        s.left=0;
        s.right=0;
		splits_ = new flann::cuda::device_vector_noinit<cuda::kd_tree_builder_detail::SplitInfo>(thrust::cuda::par.on(gpu_stream), prealloc, s);
		s.right=points.size();
        //(*splits_)[0]=s;
		thrust::detail::two_system_copy(thrust::host, thrust::cuda::par.on(gpu_stream), &s, &s + 1, splits_->begin());

        aabb_min_=new flann::cuda::device_vector_noinit<float4>(prealloc);
        aabb_max_=new flann::cuda::device_vector_noinit<float4>(prealloc);

        index_x_=new flann::cuda::device_vector_noinit<int>(points_->size());
        index_y_=new flann::cuda::device_vector_noinit<int>(points_->size());
        index_z_=new flann::cuda::device_vector_noinit<int>(points_->size());

        owners_x_=new flann::cuda::device_vector_noinit<int>(thrust::cuda::par.on(gpu_stream), points_->size(),0);
        owners_y_=new flann::cuda::device_vector_noinit<int>(thrust::cuda::par.on(gpu_stream), points_->size(),0);
        owners_z_=new flann::cuda::device_vector_noinit<int>(thrust::cuda::par.on(gpu_stream), points_->size(),0);

        leftright_x_ = new flann::cuda::device_vector_noinit<int>(thrust::cuda::par.on(gpu_stream), points_->size(),0);
        leftright_y_ = new flann::cuda::device_vector_noinit<int>(thrust::cuda::par.on(gpu_stream), points_->size(),0);
        leftright_z_ = new flann::cuda::device_vector_noinit<int>(thrust::cuda::par.on(gpu_stream), points_->size(),0);

        tmp_index_=new flann::cuda::device_vector_noinit<int>(points_->size());
        tmp_owners_=new flann::cuda::device_vector_noinit<int>(points_->size());
        tmp_misc_=new flann::cuda::device_vector_noinit<int>(points_->size());

        points_x_=new flann::cuda::device_vector_noinit<float>(points_->size());
        points_y_=new flann::cuda::device_vector_noinit<float>(points_->size());
        points_z_=new flann::cuda::device_vector_noinit<float>(points_->size());
        delete_node_info_=false;
    }

    ~CudaKdTreeBuilder()
    {
        if( delete_node_info_ ) {
            delete child1_;
            delete parent_;
            delete splits_;
            delete aabb_min_;
            delete aabb_max_;
            delete index_x_;
		}

        delete index_y_;
        delete index_z_;
        delete owners_x_;
        delete owners_y_;
        delete owners_z_;
        delete points_x_;
        delete points_y_;
        delete points_z_;
        delete leftright_x_;
        delete leftright_y_;
        delete leftright_z_;
        delete tmp_index_;
        delete tmp_owners_;
        delete tmp_misc_;
    }

	//! build the tree
	//! general idea:
	//! - build sorted lists of the points in x y and z order (to be able to compute tight AABBs in O(1) )
	//! - while( nodes to split exist )
	//!    - split non-child nodes along longest axis if the number of points is > max_points_per_node
	//!    - for each point: determine whether it is in a node that was split. If yes, mark it as belonging to the left or right child node of its current parent node
	//!    - reorder the points so that the points of a single node are continuous in the node array
	//!    - update the left/right pointers and AABBs of all nodes
    void buildTree()
    {
        //              std::cout<<"buildTree()"<<std::endl;
        //              sleep(1);
        //              Util::Timer stepTimer;
        thrust::transform(thrust::cuda::par.on(gpu_stream), points_->begin(), points_->end(), thrust::make_zip_iterator(thrust::make_tuple(points_x_->begin(), points_y_->begin(),points_z_->begin()) ), cuda::kd_tree_builder_detail::pointxyz_to_px_py_pz() );

        thrust::counting_iterator<int> it(0);
        thrust::copy(thrust::cuda::par.on(gpu_stream), it, it+points_->size(), index_x_->begin() );

        thrust::copy(thrust::cuda::par.on(gpu_stream), index_x_->begin(), index_x_->end(), index_y_->begin() );
        thrust::copy(thrust::cuda::par.on(gpu_stream), index_x_->begin(), index_x_->end(), index_z_->begin() );

        flann::cuda::device_vector_noinit<float> tmpv(points_->size());

        // create sorted index list -> can be used to compute AABBs in O(1)
        thrust::copy(thrust::cuda::par.on(gpu_stream), points_x_->begin(), points_x_->end(), tmpv.begin());
        thrust::sort_by_key(thrust::cuda::par.on(gpu_stream), tmpv.begin(), tmpv.end(), index_x_->begin() );
        thrust::copy(thrust::cuda::par.on(gpu_stream), points_y_->begin(), points_y_->end(), tmpv.begin());
        thrust::sort_by_key(thrust::cuda::par.on(gpu_stream), tmpv.begin(), tmpv.end(), index_y_->begin() );
        thrust::copy(thrust::cuda::par.on(gpu_stream), points_z_->begin(), points_z_->end(), tmpv.begin());
        thrust::sort_by_key(thrust::cuda::par.on(gpu_stream), tmpv.begin(), tmpv.end(), index_z_->begin() );

		int idxx, idxy, idxz;
		float xx, yy, zz;
		float4 xyzw;

		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, index_x_->begin(), index_x_->begin() + 1, &idxx);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, index_y_->begin(), index_y_->begin() + 1, &idxy);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, index_z_->begin(), index_z_->begin() + 1, &idxz);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, points_x_->begin() + idxx, points_x_->begin() + idxx + 1, &xx);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, points_y_->begin() + idxy, points_y_->begin() + idxy + 1, &yy);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, points_z_->begin() + idxz, points_z_->begin() + idxz + 1, &zz);
		xyzw = make_float4(xx, yy, zz, 0);
		thrust::detail::two_system_copy(thrust::host, thrust::cuda::par.on(gpu_stream), &xyzw, &xyzw + 1, aabb_min_->begin());

		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, index_x_->end() - 1, index_x_->end(), &idxx);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, index_y_->end() - 1, index_y_->end(), &idxy);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, index_z_->end() - 1, index_z_->end(), &idxz);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, points_x_->begin() + idxx, points_x_->begin() + idxx + 1, &xx);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, points_y_->begin() + idxy, points_y_->begin() + idxy + 1, &yy);
		thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, points_z_->begin() + idxz, points_z_->begin() + idxz + 1, &zz);
		xyzw = make_float4(xx, yy, zz, 0);
		thrust::detail::two_system_copy(thrust::host, thrust::cuda::par.on(gpu_stream), &xyzw, &xyzw + 1, aabb_max_->begin());

        //(*aabb_min_)[0]=make_float4((*points_x_)[(*index_x_)[0]],(*points_y_)[(*index_y_)[0]],(*points_z_)[(*index_z_)[0]],0);

        //(*aabb_max_)[0]=make_float4((*points_x_)[(*index_x_)[points_->size()-1]],(*points_y_)[(*index_y_)[points_->size()-1]],(*points_z_)[(*index_z_)[points_->size()-1]],0);
        #ifdef PRINT_DEBUG_TIMING
        cudaDeviceSynchronize();
        std::cout<<" initial stuff:"<<stepTimer.elapsed()<<std::endl;
        stepTimer.restart();
        #endif
        int last_node_count=0;
        for( int i=0;; i++ ) {
            cuda::kd_tree_builder_detail::SplitNodes sn;

            sn.maxPointsPerNode=max_leaf_size_;
            sn.node_count=thrust::raw_pointer_cast(&allocation_info_[NodeCount]);
            sn.nodes_allocated=thrust::raw_pointer_cast(&allocation_info_[NodesAllocated]);
            sn.out_of_space=thrust::raw_pointer_cast(&allocation_info_[OutOfSpace]);
            sn.child1_=thrust::raw_pointer_cast(&(*child1_)[0]);
            sn.parent_=thrust::raw_pointer_cast(&(*parent_)[0]);
            sn.splits=thrust::raw_pointer_cast(&(*splits_)[0]);

            thrust::counting_iterator<int> cit(0);
            thrust::for_each(thrust::cuda::par.on(gpu_stream), thrust::make_zip_iterator(thrust::make_tuple( parent_->begin(), child1_->begin(),  splits_->begin(), aabb_min_->begin(), aabb_max_->begin(), cit  )),
                              thrust::make_zip_iterator(thrust::make_tuple( parent_->begin()+last_node_count, child1_->begin()+last_node_count,splits_->begin()+last_node_count, aabb_min_->begin()+last_node_count, aabb_max_->begin()+last_node_count,cit+last_node_count  )),
                              sn   );
            // copy allocation info to host
            thrust::host_vector<int> alloc_info(allocation_info_.size());
			thrust::detail::two_system_copy(thrust::cuda::par.on(gpu_stream), thrust::host, allocation_info_.begin(), allocation_info_.end(), alloc_info.begin());

            if( last_node_count == alloc_info[NodeCount] ) { // no more nodes were split -> done
                break;
            }
            last_node_count=alloc_info[NodeCount];
			
			// a node was un-splittable due to a lack of space
            if( alloc_info[OutOfSpace]==1 ) {
                resize_node_vectors(alloc_info[NodesAllocated]*2);
                alloc_info[OutOfSpace]=0;
                alloc_info[NodesAllocated]*=2;
				thrust::detail::two_system_copy(thrust::host, thrust::cuda::par.on(gpu_stream), alloc_info.begin(), alloc_info.end(), allocation_info_.begin());
				//allocation_info_=alloc_info;
            }
            #ifdef PRINT_DEBUG_TIMING
            cudaDeviceSynchronize();
            std::cout<<" node split:"<<stepTimer.elapsed()<<std::endl;
            stepTimer.restart();
            #endif

            // foreach point: point was in node that was split?move it to child (leaf) node : do nothing
            cuda::kd_tree_builder_detail::MovePointsToChildNodes sno( thrust::raw_pointer_cast(&(*child1_)[0]),
                                                                      thrust::raw_pointer_cast(&(*splits_)[0]),
                                                                      thrust::raw_pointer_cast(&(*points_x_)[0]),
                                                                      thrust::raw_pointer_cast(&(*points_y_)[0]),
                                                                      thrust::raw_pointer_cast(&(*points_z_)[0]),
                                                                      thrust::raw_pointer_cast(&(*owners_x_)[0]),
                                                                      thrust::raw_pointer_cast(&(*owners_y_)[0]),
                                                                      thrust::raw_pointer_cast(&(*owners_z_)[0]),
                                                                      thrust::raw_pointer_cast(&(*leftright_x_)[0]),
                                                                      thrust::raw_pointer_cast(&(*leftright_y_)[0]),
                                                                      thrust::raw_pointer_cast(&(*leftright_z_)[0])
                                                                      );
            thrust::counting_iterator<int> ci0(0);
            thrust::for_each(thrust::cuda::par.on(gpu_stream), thrust::make_zip_iterator( thrust::make_tuple( ci0, index_x_->begin(), index_y_->begin(), index_z_->begin()) ),
                              thrust::make_zip_iterator( thrust::make_tuple( ci0+points_->size(), index_x_->end(), index_y_->end(), index_z_->end()) ),sno  );

            #ifdef PRINT_DEBUG_TIMING
            cudaDeviceSynchronize();
            std::cout<<" set new owners:"<<stepTimer.elapsed()<<std::endl;
            stepTimer.restart();
            #endif

            // move points around so that each leaf node's points are continuous
            separate_left_and_right_children(*index_x_,*owners_x_,*tmp_index_,*tmp_owners_, *leftright_x_);
            std::swap(tmp_index_, index_x_);
            std::swap(tmp_owners_, owners_x_);
            separate_left_and_right_children(*index_y_,*owners_y_,*tmp_index_,*tmp_owners_, *leftright_y_,false);
            std::swap(tmp_index_, index_y_);
            separate_left_and_right_children(*index_z_,*owners_z_,*tmp_index_,*tmp_owners_, *leftright_z_,false);
            std::swap(tmp_index_, index_z_);

            #ifdef PRINT_DEBUG_TIMING
            cudaDeviceSynchronize();
            std::cout<<" split:"<<stepTimer.elapsed()<<std::endl;
            stepTimer.restart();
            #endif
            // calculate new AABB etc
            update_leftright_and_aabb( *points_x_, *points_y_, *points_z_, *index_x_, *index_y_, *index_z_, *owners_x_, *splits_,*aabb_min_, *aabb_max_);
            #ifdef PRINT_DEBUG_TIMING
            cudaDeviceSynchronize();
            std::cout<<" update_leftright_and_aabb:"<<stepTimer.elapsed()<<std::endl;
            stepTimer.restart();
            print_vector(node_count_);
            #endif

        }
    }
    
	template<class Distance> 
	friend class KDTreeCuda3dIndex;

protected:


    //! takes the partitioned nodes, and sets the left-/right info of leaf nodes, as well as the AABBs
    void
    update_leftright_and_aabb( const flann::cuda::device_vector_noinit<float>& x, const flann::cuda::device_vector_noinit<float>& y,const flann::cuda::device_vector_noinit<float>& z,
                               const flann::cuda::device_vector_noinit<int>& ix, const flann::cuda::device_vector_noinit<int>& iy,const flann::cuda::device_vector_noinit<int>& iz,
                               const flann::cuda::device_vector_noinit<int>& owners,
                               flann::cuda::device_vector_noinit<cuda::kd_tree_builder_detail::SplitInfo>& splits, flann::cuda::device_vector_noinit<float4>& aabbMin,flann::cuda::device_vector_noinit<float4>& aabbMax)
    {
        flann::cuda::device_vector_noinit<int>* labelsUnique=tmp_owners_;
        flann::cuda::device_vector_noinit<int>* countsUnique=tmp_index_;
		// assume: points of each node are continuous in the array
		
		// find which nodes are here, and where each node's points begin and end
        int unique_labels = thrust::unique_by_key_copy(thrust::cuda::par.on(gpu_stream), owners.begin(), owners.end(), thrust::counting_iterator<int>(0), labelsUnique->begin(), countsUnique->begin()).first - labelsUnique->begin();

		// update the info
        cuda::kd_tree_builder_detail::SetLeftAndRightAndAABB s;
        s.maxPoints=x.size();
        s.nElements=unique_labels;
        s.nodes=thrust::raw_pointer_cast(&(splits[0]));
        s.counts=thrust::raw_pointer_cast(&( (*countsUnique)[0]));
        s.labels=thrust::raw_pointer_cast(&( (*labelsUnique)[0]));
        s.x=thrust::raw_pointer_cast(&x[0]);
        s.y=thrust::raw_pointer_cast(&y[0]);
        s.z=thrust::raw_pointer_cast(&z[0]);
        s.ix=thrust::raw_pointer_cast(&ix[0]);
        s.iy=thrust::raw_pointer_cast(&iy[0]);
        s.iz=thrust::raw_pointer_cast(&iz[0]);
        s.aabbMin=thrust::raw_pointer_cast(&aabbMin[0]);
        s.aabbMax=thrust::raw_pointer_cast(&aabbMax[0]);

        thrust::counting_iterator<int> it(0);
        thrust::for_each(thrust::cuda::par.on(gpu_stream), it, it+unique_labels, s);
    }

    //! Separates the left and right children of each node into continuous parts of the array.
    //! More specifically, it seperates children with even and odd node indices because nodes are always
    //! allocated in pairs -> child1==child2+1 -> child1 even and child2 odd, or vice-versa.
    //! Since the split operation is stable, this results in continuous partitions
    //! for all the single nodes.
    //! (basically the split primitive according to sengupta et al)
    //! about twice as fast as thrust::partition
    void separate_left_and_right_children( flann::cuda::device_vector_noinit<int>& key_in, flann::cuda::device_vector_noinit<int>& val_in, flann::cuda::device_vector_noinit<int>& key_out, flann::cuda::device_vector_noinit<int>& val_out, flann::cuda::device_vector_noinit<int>& left_right_marks, bool scatter_val_out=true )
    {
        flann::cuda::device_vector_noinit<int>* f_tmp = &val_out;
        flann::cuda::device_vector_noinit<int>* addr_tmp = tmp_misc_;

        thrust::exclusive_scan(thrust::cuda::par.on(gpu_stream), /*thrust::make_transform_iterator(*/ left_right_marks.begin() /*,cuda::kd_tree_builder_detail::IsEven*/
                                                                     /*())*/, /*thrust::make_transform_iterator(*/ left_right_marks.end() /*,cuda::kd_tree_builder_detail::IsEven*/
                                                                     /*())*/,     f_tmp->begin() );
        cuda::kd_tree_builder_detail::set_addr3 sa;
        sa.val_=thrust::raw_pointer_cast(&left_right_marks[0]);
        sa.f_=thrust::raw_pointer_cast(&(*f_tmp)[0]);
        sa.npoints_=key_in.size();
        thrust::counting_iterator<int> it(0);
        thrust::transform(thrust::cuda::par.on(gpu_stream), it, it+val_in.size(), addr_tmp->begin(), sa);

        thrust::scatter(thrust::cuda::par.on(gpu_stream), key_in.begin(), key_in.end(), addr_tmp->begin(), key_out.begin());
        if( scatter_val_out ) thrust::scatter(thrust::cuda::par.on(gpu_stream), val_in.begin(), val_in.end(), addr_tmp->begin(), val_out.begin());
    }

    //! allocates additional space in all the node-related vectors.
    //! new_size elements will be added to all vectors.
    void resize_node_vectors( size_t new_size )
    {
        size_t add = new_size - child1_->size();
        child1_->append(thrust::cuda::par.on(gpu_stream), add, -1);
        parent_->append(thrust::cuda::par.on(gpu_stream), add, -1);
        cuda::kd_tree_builder_detail::SplitInfo s;
        s.left=0;
        s.right=0;
        splits_->append(thrust::cuda::par.on(gpu_stream), add, s);
        float4 f=make_float4(0.0f, 0.0f, 0.0f, 0.0f);
        aabb_min_->append(thrust::cuda::par.on(gpu_stream), add, f);
        aabb_max_->append(thrust::cuda::par.on(gpu_stream), add, f);
    }

	cudaStream_t gpu_stream;

    const flann::cuda::device_vector_noinit<float4>* points_;
	
	// tree data, those are stored per-node
	
	//! left child of each node. (right child==left child + 1, due to the alloc mechanism)
	//! child1_[node]==-1 if node is a leaf node
    flann::cuda::device_vector_noinit<int>* child1_;
	//! parent node of each node
    flann::cuda::device_vector_noinit<int>* parent_;
	//! split info (dim/value or left/right pointers)
    flann::cuda::device_vector_noinit<cuda::kd_tree_builder_detail::SplitInfo>* splits_;
	//! min aabb value of each node
    flann::cuda::device_vector_noinit<float4>* aabb_min_;
	//! max aabb value of each node
    flann::cuda::device_vector_noinit<float4>* aabb_max_;

    enum AllocationInfo
    {
        NodeCount=0,
        NodesAllocated=1,
        OutOfSpace=2
    };
    // those were put into a single vector of 3 elements so that only one mem transfer will be needed for all three of them
    //  flann::cuda::device_vector_noinit<int> out_of_space_;
    //  flann::cuda::device_vector_noinit<int> node_count_;
    //  flann::cuda::device_vector_noinit<int> nodes_allocated_;
    flann::cuda::device_vector_noinit<int> allocation_info_;
	
    int max_leaf_size_;

	// coordinate values of the points
    flann::cuda::device_vector_noinit<float>* points_x_, * points_y_, * points_z_;
	// indices
    flann::cuda::device_vector_noinit<int>* index_x_,  * index_y_,  * index_z_;
	// owner node
    flann::cuda::device_vector_noinit<int>* owners_x_, * owners_y_, * owners_z_;
	// contains info about whether a point was partitioned to the left or right child after a split
    flann::cuda::device_vector_noinit<int>* leftright_x_, * leftright_y_, * leftright_z_;
    flann::cuda::device_vector_noinit<int>* tmp_index_, * tmp_owners_, * tmp_misc_;
    bool delete_node_info_;
};


} // namespace flann
#endif
