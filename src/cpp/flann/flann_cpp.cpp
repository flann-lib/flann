/***********************************************************************
 * Software License Agreement (BSD License)
 *
 * Copyright 2008-2009  Marius Muja (mariusm@cs.ubc.ca). All rights reserved.
 * Copyright 2008-2009  David G. Lowe (lowe@cs.ubc.ca). All rights reserved.
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

#include <stdexcept>
#include <vector>

#include "flann/flann.h"
#include "flann/general.h"
#include "flann/util/timer.h"
#include "flann/util/logger.h"
#include "flann/nn/index_testing.h"
#include "flann/util/saving.h"
#include "flann/nn/ground_truth.h"
// index types
#include "flann/algorithms/all_indices.h"


#ifdef WIN32
#define EXPORTED extern "C" __declspec(dllexport)
#else
#define EXPORTED extern "C"
#endif

namespace flann
{

void log_verbosity(int level)
{
    if (level>=0) {
        logger.setLevel(level);
    }
}


IndexParams* IndexParams::createFromParameters(const FLANNParameters& p)
{
	IndexParams* params = ParamsFactory::instance().create(p.algorithm);
	params->fromParameters(p);

	return params;
}


class StaticInit
{
public:
	StaticInit()
	{
		ParamsFactory::instance().register_<LinearIndexParams>(LINEAR);
		ParamsFactory::instance().register_<KDTreeIndexParams>(KDTREE);
		ParamsFactory::instance().register_<KDTreeSingleIndexParams>(KDTREE_SINGLE);
		ParamsFactory::instance().register_<KMeansIndexParams>(KMEANS);
		ParamsFactory::instance().register_<CompositeIndexParams>(COMPOSITE);
		ParamsFactory::instance().register_<AutotunedIndexParams>(AUTOTUNED);
//		ParamsFactory::instance().register_<SavedIndexParams>(SAVED);
	}
};
StaticInit __init;


} // namespace FLANN



