// Copyright (c) 1999-2002 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// www.digitalmars.com

struct GCStats
{
    size_t poolsize;		// total size of pool
    size_t usedsize;		// bytes allocated
    size_t freeblocks;		// number of blocks marked FREE
    size_t freelistsize;		// total of memory on free lists
    size_t pageblocks;		// number of blocks marked PAGE
}


