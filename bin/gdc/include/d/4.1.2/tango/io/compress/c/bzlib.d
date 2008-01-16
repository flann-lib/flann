/* Converted to D from bzlib.h by htod */

module tango.io.compress.c.bzlib;

/*-------------------------------------------------------------*/
/*--- Public header file for the library.                   ---*/
/*---                                               bzlib.h ---*/
/*-------------------------------------------------------------*/

/* ------------------------------------------------------------------
   This file is part of bzip2/libbzip2, a program and library for
   lossless, block-sorting data compression.

   bzip2/libbzip2 version 1.0.4 of 20 December 2006
   Copyright (C) 1996-2006 Julian Seward <jseward@bzip.org>

   Please read the WARNING, DISCLAIMER and PATENTS sections in the 
   README file.

   This program is released under the terms of the license contained
   in the file LICENSE.
   ------------------------------------------------------------------ */

extern(C):

const BZ_RUN = 0;
const BZ_FLUSH = 1;
const BZ_FINISH = 2;

const BZ_OK = 0;
const BZ_RUN_OK = 1;
const BZ_FLUSH_OK = 2;
const BZ_FINISH_OK = 3;
const BZ_STREAM_END = 4;
const BZ_SEQUENCE_ERROR = -1;
const BZ_PARAM_ERROR = -2;
const BZ_MEM_ERROR = -3;
const BZ_DATA_ERROR = -4;
const BZ_DATA_ERROR_MAGIC = -5;
const BZ_IO_ERROR = -6;
const BZ_UNEXPECTED_EOF = -7;
const BZ_OUTBUFF_FULL = -8;
const BZ_CONFIG_ERROR = -9;

struct bz_stream
{
    ubyte *next_in;
    uint avail_in;
    uint total_in_lo32;
    uint total_in_hi32;
    ubyte *next_out;
    uint avail_out;
    uint total_out_lo32;
    uint total_out_hi32;
    void *state;
    void * function(void *, int , int )bzalloc;
    void  function(void *, void *)bzfree;
    void *opaque;
}

import tango.stdc.stdio : FILE;

/*-- Core (low-level) library functions --*/

//C     BZ_EXTERN int BZ_API(BZ2_bzCompressInit) ( 
//C           bz_stream* strm, 
//C           int        blockSize100k, 
//C           int        verbosity, 
//C           int        workFactor 
//C        );
extern (Windows):
int  BZ2_bzCompressInit(bz_stream *strm, int blockSize100k, int verbosity, int workFactor);

//C     BZ_EXTERN int BZ_API(BZ2_bzCompress) ( 
//C           bz_stream* strm, 
//C           int action 
//C        );
int  BZ2_bzCompress(bz_stream *strm, int action);

//C     BZ_EXTERN int BZ_API(BZ2_bzCompressEnd) ( 
//C           bz_stream* strm 
//C        );
int  BZ2_bzCompressEnd(bz_stream *strm);

//C     BZ_EXTERN int BZ_API(BZ2_bzDecompressInit) ( 
//C           bz_stream *strm, 
//C           int       verbosity, 
//C           int       small
//C        );
int  BZ2_bzDecompressInit(bz_stream *strm, int verbosity, int small);

//C     BZ_EXTERN int BZ_API(BZ2_bzDecompress) ( 
//C           bz_stream* strm 
//C        );
int  BZ2_bzDecompress(bz_stream *strm);

//C     BZ_EXTERN int BZ_API(BZ2_bzDecompressEnd) ( 
//C           bz_stream *strm 
//C        );
int  BZ2_bzDecompressEnd(bz_stream *strm);



/*-- High(er) level library functions --*/

version(BZ_NO_STDIO){}else{

const BZ_MAX_UNUSED = 5000;
alias void BZFILE;

//C     BZ_EXTERN BZFILE* BZ_API(BZ2_bzReadOpen) ( 
//C           int*  bzerror,   
//C           FILE* f, 
//C           int   verbosity, 
//C           int   small,
//C           void* unused,    
//C           int   nUnused 
//C        );
extern (Windows):
BZFILE * BZ2_bzReadOpen(int *bzerror, FILE *f, int verbosity, int small, void *unused, int nUnused);

//C     BZ_EXTERN void BZ_API(BZ2_bzReadClose) ( 
//C           int*    bzerror, 
//C           BZFILE* b 
//C        );
void  BZ2_bzReadClose(int *bzerror, BZFILE *b);

//C     BZ_EXTERN void BZ_API(BZ2_bzReadGetUnused) ( 
//C           int*    bzerror, 
//C           BZFILE* b, 
//C           void**  unused,  
//C           int*    nUnused 
//C        );
void  BZ2_bzReadGetUnused(int *bzerror, BZFILE *b, void **unused, int *nUnused);

//C     BZ_EXTERN int BZ_API(BZ2_bzRead) ( 
//C           int*    bzerror, 
//C           BZFILE* b, 
//C           void*   buf, 
//C           int     len 
//C        );
int  BZ2_bzRead(int *bzerror, BZFILE *b, void *buf, int len);

//C     BZ_EXTERN BZFILE* BZ_API(BZ2_bzWriteOpen) ( 
//C           int*  bzerror,      
//C           FILE* f, 
//C           int   blockSize100k, 
//C           int   verbosity, 
//C           int   workFactor 
//C        );
BZFILE * BZ2_bzWriteOpen(int *bzerror, FILE *f, int blockSize100k, int verbosity, int workFactor);

//C     BZ_EXTERN void BZ_API(BZ2_bzWrite) ( 
//C           int*    bzerror, 
//C           BZFILE* b, 
//C           void*   buf, 
//C           int     len 
//C        );
void  BZ2_bzWrite(int *bzerror, BZFILE *b, void *buf, int len);

//C     BZ_EXTERN void BZ_API(BZ2_bzWriteClose) ( 
//C           int*          bzerror, 
//C           BZFILE*       b, 
//C           int           abandon, 
//C           unsigned int* nbytes_in, 
//C           unsigned int* nbytes_out 
//C        );
void  BZ2_bzWriteClose(int *bzerror, BZFILE *b, int abandon, uint *nbytes_in, uint *nbytes_out);

//C     BZ_EXTERN void BZ_API(BZ2_bzWriteClose64) ( 
//C           int*          bzerror, 
//C           BZFILE*       b, 
//C           int           abandon, 
//C           unsigned int* nbytes_in_lo32, 
//C           unsigned int* nbytes_in_hi32, 
//C           unsigned int* nbytes_out_lo32, 
//C           unsigned int* nbytes_out_hi32
//C        );
void  BZ2_bzWriteClose64(int *bzerror, BZFILE *b, int abandon, uint *nbytes_in_lo32, uint *nbytes_in_hi32, uint *nbytes_out_lo32, uint *nbytes_out_hi32);

}

/*-- Utility functions --*/

//C     BZ_EXTERN int BZ_API(BZ2_bzBuffToBuffCompress) ( 
//C           char*         dest, 
//C           unsigned int* destLen,
//C           char*         source, 
//C           unsigned int  sourceLen,
//C           int           blockSize100k, 
//C           int           verbosity, 
//C           int           workFactor 
//C        );
int  BZ2_bzBuffToBuffCompress(char *dest, uint *destLen, char *source, uint sourceLen, int blockSize100k, int verbosity, int workFactor);

//C     BZ_EXTERN int BZ_API(BZ2_bzBuffToBuffDecompress) ( 
//C           char*         dest, 
//C           unsigned int* destLen,
//C           char*         source, 
//C           unsigned int  sourceLen,
//C           int           small, 
//C           int           verbosity 
//C        );
int  BZ2_bzBuffToBuffDecompress(char *dest, uint *destLen, char *source, uint sourceLen, int small, int verbosity);


/*--
   Code contributed by Yoshioka Tsuneo (tsuneo@rr.iij4u.or.jp)
   to support better zlib compatibility.
   This code is not _officially_ part of libbzip2 (yet);
   I haven't tested it, documented it, or considered the
   threading-safeness of it.
   If this code breaks, please contact both Yoshioka and me.
--*/

//C     BZ_EXTERN const char * BZ_API(BZ2_bzlibVersion) (
//C           void
//C        );
char * BZ2_bzlibVersion();

version(BZ_NO_STDIO){}else{

//C     BZ_EXTERN BZFILE * BZ_API(BZ2_bzopen) (
//C           const char *path,
//C           const char *mode
//C        );
BZFILE * BZ2_bzopen(char *path, char *mode);

//C     BZ_EXTERN BZFILE * BZ_API(BZ2_bzdopen) (
//C           int        fd,
//C           const char *mode
//C        );
BZFILE * BZ2_bzdopen(int fd, char *mode);
         
//C     BZ_EXTERN int BZ_API(BZ2_bzread) (
//C           BZFILE* b, 
//C           void* buf, 
//C           int len 
//C        );
int  BZ2_bzread(BZFILE *b, void *buf, int len);

//C     BZ_EXTERN int BZ_API(BZ2_bzwrite) (
//C           BZFILE* b, 
//C           void*   buf, 
//C           int     len 
//C        );
int  BZ2_bzwrite(BZFILE *b, void *buf, int len);

//C     BZ_EXTERN int BZ_API(BZ2_bzflush) (
//C           BZFILE* b
//C        );
int  BZ2_bzflush(BZFILE *b);

//C     BZ_EXTERN void BZ_API(BZ2_bzclose) (
//C           BZFILE* b
//C        );
void  BZ2_bzclose(BZFILE *b);

//C     BZ_EXTERN const char * BZ_API(BZ2_bzerror) (
//C           BZFILE *b, 
//C           int    *errnum
//C        );
char * BZ2_bzerror(BZFILE *b, int *errnum);

}

/*-------------------------------------------------------------*/
/*--- end                                           bzlib.h ---*/
/*-------------------------------------------------------------*/
