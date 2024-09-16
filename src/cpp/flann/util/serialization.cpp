#include "serialization.h"

#include <lz4.h>
#include <lz4hc.h>

namespace {
LZ4_streamHC_t lz4Stream_body;
LZ4_streamHC_t *lz4Stream;

LZ4_streamDecode_t lz4StreamDecode_body;
LZ4_streamDecode_t *lz4StreamDecode;

} // namespace

namespace flann {
namespace serialization {
void SaveArchive::initBlock() {
  // Alloc the space for both buffer blocks (each compressed block
  // references the previous)
  buffer_ = buffer_blocks_ = (char *)malloc(BLOCK_BYTES * 2);
  compressed_buffer_ =
      (char *)malloc(LZ4_COMPRESSBOUND(BLOCK_BYTES) + sizeof(size_t));
  if (buffer_ == NULL || compressed_buffer_ == NULL) {
    throw FLANNException("Error allocating compression buffer");
  }

  // Init the LZ4 stream
  lz4Stream = &lz4Stream_body;
  LZ4_resetStreamHC(lz4Stream, 9);
  first_block_ = true;

  offset_ = 0;
}

void SaveArchive::flushBlock() {
  size_t compSz = 0;
  // Handle header
  if (first_block_) {
    // Copy & set the header
    IndexHeaderStruct *head = (IndexHeaderStruct *)buffer_;
    size_t headSz = sizeof(IndexHeaderStruct);

    assert(head->compression == 0);
    head->compression = 1; // Bool now, enum later

    // Do the compression for the block
    compSz = LZ4_compress_HC_continue(
        lz4Stream, buffer_ + headSz, compressed_buffer_ + headSz,
        offset_ - headSz, LZ4_COMPRESSBOUND(BLOCK_BYTES));

    if (compSz <= 0) {
      throw FLANNException("Error compressing (first block)");
    }

    // Handle header
    head->first_block_size = compSz;
    memcpy(compressed_buffer_, buffer_, headSz);

    compSz += headSz;
    first_block_ = false;
  } else {
    size_t headSz = sizeof(compSz);

    // Do the compression for the block
    compSz = LZ4_compress_HC_continue(lz4Stream, buffer_,
                                      compressed_buffer_ + headSz, offset_,
                                      LZ4_COMPRESSBOUND(BLOCK_BYTES));

    if (compSz <= 0) {
      throw FLANNException("Error compressing");
    }

    // Save the size of the compressed block as the header
    memcpy(compressed_buffer_, &compSz, headSz);
    compSz += headSz;
  }

  // Write the compressed buffer
  fwrite(compressed_buffer_, compSz, 1, stream_);

  // Switch the buffer to the *other* block
  if (buffer_ == buffer_blocks_)
    buffer_ = &buffer_blocks_[BLOCK_BYTES];
  else
    buffer_ = buffer_blocks_;
  offset_ = 0;
}

void SaveArchive::endBlock() {
  // Cleanup memory
  free(buffer_blocks_);
  buffer_blocks_ = NULL;
  buffer_ = NULL;
  free(compressed_buffer_);
  compressed_buffer_ = NULL;

  // Write a '0' size for next block
  size_t z = 0;
  fwrite(&z, sizeof(z), 1, stream_);
}

void LoadArchive::decompressAndLoadV10(FILE *stream) {
  buffer_ = NULL;

  // Find file size
  size_t pos = ftell(stream);
  fseek(stream, 0, SEEK_END);
  size_t fileSize = ftell(stream) - pos;
  fseek(stream, pos, SEEK_SET);
  size_t headSz = sizeof(IndexHeaderStruct);

  // Read the (compressed) file to a buffer
  char *compBuffer = (char *)malloc(fileSize);
  if (compBuffer == NULL) {
    throw FLANNException("Error allocating file buffer space");
  }
  if (fread(compBuffer, fileSize, 1, stream) != 1) {
    free(compBuffer);
    throw FLANNException(
        "Invalid index file, cannot read from disk (compressed)");
  }

  // Extract header
  IndexHeaderStruct *head = (IndexHeaderStruct *)(compBuffer);

  // Backward compatability
  size_t compressedSz = fileSize - headSz;
  size_t uncompressedSz = head->first_block_size - headSz;

  // Check for compression type
  if (head->compression != 1) {
    free(compBuffer);
    throw FLANNException("Compression type not supported");
  }

  // Allocate a decompressed buffer
  ptr_ = buffer_ = (char *)malloc(uncompressedSz + headSz);
  if (buffer_ == NULL) {
    free(compBuffer);
    throw FLANNException("Error (re)allocating decompression buffer");
  }

  // Extract body
  size_t usedSz = LZ4_decompress_safe(compBuffer + headSz, buffer_ + headSz,
                                      compressedSz, uncompressedSz);

  // Check if the decompression was the expected size.
  if (usedSz != uncompressedSz) {
    free(compBuffer);
    throw FLANNException("Unexpected decompression size");
  }

  // Copy header data
  memcpy(buffer_, compBuffer, headSz);
  free(compBuffer);

  // Put the file pointer at the end of the data we've read
  if (compressedSz + headSz + pos != fileSize)
    fseek(stream, compressedSz + headSz + pos, SEEK_SET);
  block_sz_ = uncompressedSz + headSz;
}

void LoadArchive::initBlock(FILE *stream) {
  size_t pos = ftell(stream);
  buffer_ = NULL;
  buffer_blocks_ = NULL;
  compressed_buffer_ = NULL;
  size_t headSz = sizeof(IndexHeaderStruct);

  // Read the file header to a buffer
  IndexHeaderStruct *head = (IndexHeaderStruct *)malloc(headSz);
  if (head == NULL) {
    throw FLANNException("Error allocating header buffer space");
  }
  if (fread(head, headSz, 1, stream) != 1) {
    free(head);
    throw FLANNException("Invalid index file, cannot read from disk (header)");
  }

  // Backward compatability
  if (head->signature[13] == '1' && head->signature[15] == '0') {
    free(head);
    fseek(stream, pos, SEEK_SET);
    return decompressAndLoadV10(stream);
  }

  // Alloc the space for both buffer blocks (each block
  // references the previous)
  buffer_ = buffer_blocks_ = (char *)malloc(BLOCK_BYTES * 2);
  compressed_buffer_ = (char *)malloc(LZ4_COMPRESSBOUND(BLOCK_BYTES));
  if (buffer_ == NULL || compressed_buffer_ == NULL) {
    free(head);
    throw FLANNException("Error allocating compression buffer");
  }

  // Init the LZ4 stream
  lz4StreamDecode = &lz4StreamDecode_body;
  LZ4_setStreamDecode(lz4StreamDecode, NULL, 0);

  // Read first block
  memcpy(buffer_, head, headSz);
  loadBlock(buffer_ + headSz, head->first_block_size, stream);
  block_sz_ += headSz;
  ptr_ = buffer_;
  free(head);
}

void loadBlock(char *buffer_, size_t compSz, FILE *stream) {
  if (compSz >= LZ4_COMPRESSBOUND(BLOCK_BYTES)) {
    throw FLANNException("Requested block size too large");
  }

  // Read the block into the compressed buffer
  if (fread(compressed_buffer_, compSz, 1, stream) != 1) {
    throw FLANNException("Invalid index file, cannot read from disk (block)");
  }

  // Decompress into the regular buffer
  const int decBytes = LZ4_decompress_safe_continue(
      lz4StreamDecode, compressed_buffer_, buffer_, compSz, BLOCK_BYTES);
  if (decBytes <= 0) {
    throw FLANNException("Invalid index file, cannot decompress block");
  }
  block_sz_ = decBytes;
}

void LoadArchive::preparePtr(size_t size) {
  // Return if the new size is less than (or eq) the size of a block
  if (ptr_ + size <= buffer_ + block_sz_)
    return;

  // Switch the buffer to the *other* block
  if (buffer_ == buffer_blocks_)
    buffer_ = &buffer_blocks_[BLOCK_BYTES];
  else
    buffer_ = buffer_blocks_;

  // Find the size of the next block
  size_t cmpSz = 0;
  size_t readCnt = fread(&cmpSz, sizeof(cmpSz), 1, stream_);
  if (cmpSz <= 0 || readCnt != 1) {
    throw FLANNException("Requested to read next block past end of file");
  }

  // Load block & init ptr
  loadBlock(buffer_, cmpSz, stream_);
  ptr_ = buffer_;
}

void LoadArchive::endBlock() {
  // If not v1.0 format hack...
  if (buffer_blocks_ != NULL) {
    // Read the last '0' in the file
    size_t zero = 1;
    if (fread(&zero, sizeof(zero), 1, stream_) != 1) {
      throw FLANNException("Invalid index file, cannot read from disk (end)");
    }
    if (zero != 0) {
      throw FLANNException("Invalid index file, last block not zero length");
    }
  }

  // Free resources
  if (buffer_blocks_ != NULL) {
    free(buffer_blocks_);
    buffer_blocks_ = NULL;
  }
  if (compressed_buffer_ != NULL) {
    free(compressed_buffer_);
    compressed_buffer_ = NULL;
  }
  ptr_ = NULL;
}

} // namespace serialization
} // namespace flann