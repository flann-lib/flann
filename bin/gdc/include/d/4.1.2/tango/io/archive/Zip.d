/*******************************************************************************
 *
 * copyright:   Copyright © 2007 Daniel Keep.  All rights reserved.
 *
 * license:     BSD style: $(LICENSE)
 *
 * version:     Initial release: December 2007
 *
 * author:      Daniel Keep
 *
 ******************************************************************************/

module tango.io.archive.Zip;

/*

TODO
====

* Disable UTF encoding until I've worked out what version of Zip that's
  related to... (actually; it's entirely possible that's it's merely a
  *proposal* at the moment.) (*Done*)

* Make ZipEntry safe: make them aware that their creating reader has been
  destroyed.

*/

import tango.core.ByteSwap : ByteSwap;
import tango.io.Buffer : Buffer;
import tango.io.FileConduit : FileConduit;
import tango.io.FilePath : FilePath, PathView;
import tango.io.MappedBuffer : MappedBuffer;
import tango.io.compress.ZlibStream : ZlibInput, ZlibOutput;
import tango.io.digest.Crc32 : Crc32;
import tango.io.model.IConduit : IConduit, InputStream, OutputStream;
import tango.io.stream.DigestStream : DigestInput;
import tango.time.Time : Time, TimeSpan;
import tango.time.WallClock : WallClock;
import tango.time.chrono.Gregorian : Gregorian;

import Integer = tango.text.convert.Integer;

debug(Zip) import tango.io.Stdout : Stderr;

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Implementation crap
//
// Why is this here, you ask?  Because of bloody DMD forward reference bugs.
// For pete's sake, Walter, FIX THEM, please!
//
// To skip to the actual user-visible stuff, search for "Shared stuff".

private
{

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// LocalFileHeader
//

    align(1)
    struct LocalFileHeaderData
    {
        ushort      extract_version = ushort.max;
        ushort      general_flags = 0;
        ushort      compression_method = 0;
        ushort      modification_file_time = 0;
        ushort      modification_file_date = 0;
        uint        crc_32 = 0; // offsetof = 10
        uint        compressed_size = 0;
        uint        uncompressed_size = 0;
        ushort      file_name_length = 0;
        ushort      extra_field_length = 0;

        debug(Zip) void dump()
        {
            Stderr
            ("LocalFileHeader.Data {")("\n")
            ("  extract_version = ")(extract_version)("\n")
            ("  general_flags = ")(general_flags)("\n")
            ("  compression_method = ")(compression_method)("\n")
            ("  modification_file_time = ")(modification_file_time)("\n")
            ("  modification_file_date = ")(modification_file_date)("\n")
            ("  crc_32 = ")(crc_32)("\n")
            ("  compressed_size = ")(compressed_size)("\n")
            ("  uncompressed_size = ")(uncompressed_size)("\n")
            ("  file_name_length = ")(file_name_length)("\n")
            ("  extra_field_length = ")(extra_field_length)("\n")
            ("}").newline;
        }
    }

struct LocalFileHeader
{
    const uint signature = 0x04034b50;

    alias LocalFileHeaderData Data;
    Data data;
    static assert( Data.sizeof == 26 );

    char[] file_name;
    ubyte[] extra_field;

    void[] data_arr()
    {
        return (&data)[0..1];
    }

    void put(OutputStream output)
    {
        // Make sure var-length fields will fit.
        if( file_name.length > ushort.max )
            ZipException.fntoolong;

        if( extra_field.length > ushort.max )
            ZipException.eftoolong;

        // Encode filename
        auto file_name = utf8_to_cp437(this.file_name);
        scope(exit) if( file_name !is cast(ubyte[])this.file_name )
            delete file_name;

        if( file_name is null )
            ZipException.fnencode;

        // Update lengths in data
        Data data = this.data;
        data.file_name_length = file_name.length;
        data.extra_field_length = extra_field.length;

        // Do it
        version( BigEndian ) swapAll(data);
        writeExact(output, (&data)[0..1]);
        writeExact(output, file_name);
        writeExact(output, extra_field);
    }

    void fill(InputStream src)
    {
        readExact(src, data_arr);
        version( BigEndian ) swapAll(data);

        //debug(Zip) data.dump;

        auto tmp = new ubyte[data.file_name_length];
        readExact(src, tmp);
        file_name = cp437_to_utf8(tmp);
        if( cast(char*) tmp.ptr !is file_name.ptr ) delete tmp;

        extra_field = new ubyte[data.extra_field_length];
        readExact(src, extra_field);
    }

    /*
     * This method will check to make sure that the local and central headers
     * are the same; if they're not, then that indicates that the archive is
     * corrupt.
     */
    bool agrees_with(FileHeader h)
    {
        if( data.extract_version != h.data.extract_version
                || data.general_flags != h.data.general_flags
                || data.compression_method != h.data.compression_method
                || data.modification_file_time != h.data.modification_file_time
                || data.modification_file_date != h.data.modification_file_date
                || data.crc_32 != h.data.crc_32
                || data.compressed_size != h.data.compressed_size
                || data.uncompressed_size != h.data.uncompressed_size
                || file_name != h.file_name
                || extra_field != h.extra_field )
            return false;

        // We need a separate check for the sizes and crc32, since these will
        // be zero if a trailing descriptor was used.
        if( !h.usingDataDescriptor && (
                   data.crc_32 != h.data.crc_32
                || data.compressed_size != h.data.compressed_size
                || data.uncompressed_size != h.data.uncompressed_size ) )
            return false;

        return true;
    }
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// FileHeader
//

    align(1)
    struct FileHeaderData
    {
        ubyte       zip_version;
        ubyte       file_attribute_type;
        ushort      extract_version;
        ushort      general_flags;
        ushort      compression_method;
        ushort      modification_file_time;
        ushort      modification_file_date;
        uint        crc_32;
        uint        compressed_size;
        uint        uncompressed_size;
        ushort      file_name_length;
        ushort      extra_field_length;
        ushort      file_comment_length;
        ushort      disk_number_start;
        ushort      internal_file_attributes = 0;
        uint        external_file_attributes = 0;
        int         relative_offset_of_local_header;

        debug(Zip) void dump()
        {
            Stderr
            ("FileHeader.Data {\n")
            ("  zip_version = ")(zip_version)("\n")
            ("  file_attribute_type = ")(file_attribute_type)("\n")
            ("  extract_version = ")(extract_version)("\n")
            ("  general_flags = ")(general_flags)("\n")
            ("  compression_method = ")(compression_method)("\n")
            ("  modification_file_time = ")(modification_file_time)("\n")
            ("  modification_file_date = ")(modification_file_date)("\n")
            ("  crc_32 = ")(crc_32)("\n")
            ("  compressed_size = ")(compressed_size)("\n")
            ("  uncompressed_size = ")(uncompressed_size)("\n")
            ("  file_name_length = ")(file_name_length)("\n")
            ("  extra_field_length = ")(extra_field_length)("\n")
            ("  file_comment_length = ")(file_comment_length)("\n")
            ("  disk_number_start = ")(disk_number_start)("\n")
            ("  internal_file_attributes = ")(internal_file_attributes)("\n")
            ("  external_file_attributes = ")(external_file_attributes)("\n")
            ("  relative_offset_of_local_header = ")(relative_offset_of_local_header)
                ("\n")
            ("}").newline;
        }

        void fromLocal(LocalFileHeader.Data data)
        {
            extract_version = data.extract_version;
            general_flags = data.general_flags;
            compression_method = data.compression_method;
            modification_file_time = data.modification_file_time;
            modification_file_date = data.modification_file_date;
            crc_32 = data.crc_32;
            compressed_size = data.compressed_size;
            uncompressed_size = data.uncompressed_size;
            file_name_length = data.file_name_length;
            extra_field_length = data.extra_field_length;
        }
    }

struct FileHeader
{
    const uint signature = 0x02014b50;

    alias FileHeaderData Data;
    Data* data;
    static assert( Data.sizeof == 42 );
    
    char[] file_name;
    ubyte[] extra_field;
    char[] file_comment;

    bool usingDataDescriptor()
    {
        return !!(data.general_flags & 1<<3);
    }

    uint compressionOptions()
    {
        return (data.general_flags >> 1) & 0b11;
    }

    bool usingUtf8()
    {
        //return !!(data.general_flags & 1<<11);
        return false;
    }

    void[] data_arr()
    {
        return (cast(void*)data)[0 .. Data.sizeof];
    }

    void put(OutputStream output)
    {
        // Make sure the var-length fields will fit.
        if( file_name.length > ushort.max )
            ZipException.fntoolong;

        if( extra_field.length > ushort.max )
            ZipException.eftoolong;

        if( file_comment.length > ushort.max )
            ZipException.cotoolong;

        // encode the filename and comment
        auto file_name = utf8_to_cp437(this.file_name);
        scope(exit) if( file_name !is cast(ubyte[])this.file_name )
            delete file_name;
        auto file_comment = utf8_to_cp437(this.file_comment);
        scope(exit) if( file_comment !is cast(ubyte[])this.file_comment )
            delete file_comment;

        if( file_name is null )
            ZipException.fnencode;

        if( file_comment is null && this.file_comment !is null )
            ZipException.coencode;

        // Update the lengths
        Data data = *(this.data);
        data.file_name_length = file_name.length;
        data.extra_field_length = extra_field.length;
       data.file_comment_length = file_comment.length;

        // Ok; let's do this! 
        version( BigEndian ) swapAll(data);
        writeExact(output, (&data)[0..1]);
        writeExact(output, file_name);
        writeExact(output, extra_field);
        writeExact(output, file_comment);
    }

    long map(void[] src)
    {
        //debug(Zip) Stderr.formatln("FileHeader.map([0..{}])",src.length);

        auto old_ptr = src.ptr;

        data = cast(Data*) src.ptr;
        src = src[Data.sizeof..$];
        version( BigEndian ) swapAll(*data);

        //debug(Zip) data.dump;

        char[] function(ubyte[]) conv_fn;
        if( usingUtf8 )
            conv_fn = &cp437_to_utf8;
        else
            conv_fn = &utf8_to_utf8;

        file_name = conv_fn(
                cast(ubyte[]) src[0..data.file_name_length]);
        src = src[data.file_name_length..$];

        extra_field = cast(ubyte[]) src[0..data.extra_field_length];
        src = src[data.extra_field_length..$];

        file_comment = conv_fn(
                cast(ubyte[]) src[0..data.file_comment_length]);
        src = src[data.file_comment_length..$];

        // Return how many bytes we've eaten
        //debug(Zip) Stderr.formatln(" . used {} bytes", cast(long)(src.ptr - old_ptr));
        return cast(long)(src.ptr - old_ptr);
    }
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// EndOfCDRecord
//

    align(1)
    struct EndOfCDRecordData
    {
        ushort      disk_number = 0;
        ushort      disk_with_start_of_central_directory = 0;
        ushort      central_directory_entries_on_this_disk;
        ushort      central_directory_entries_total;
        uint        size_of_central_directory;
        uint        offset_of_start_of_cd_from_starting_disk;
        ushort      file_comment_length;

        debug(Zip) void dump()
        {
            Stderr
                .formatln("EndOfCDRecord.Data {}","{")
                .formatln("  disk_number = {}", disk_number)
                .formatln("  disk_with_start_of_central_directory = {}",
                        disk_with_start_of_central_directory)
                .formatln("  central_directory_entries_on_this_disk = {}",
                        central_directory_entries_on_this_disk)
                .formatln("  central_directory_entries_total = {}",
                        central_directory_entries_total)
                .formatln("  size_of_central_directory = {}",
                        size_of_central_directory)
                .formatln("  offset_of_start_of_cd_from_starting_disk = {}",
                        offset_of_start_of_cd_from_starting_disk)
                .formatln("  file_comment_length = {}", file_comment_length)
                .formatln("}");
        }
    }

struct EndOfCDRecord
{
    const uint  signature = 0x06054b50;

    alias EndOfCDRecordData Data;
    Data data;
    static assert( data.sizeof == 18 );
    
    char[] file_comment;

    void[] data_arr()
    {
        return (cast(void*)&data)[0 .. data.sizeof];
    }

    void put(OutputStream output)
    {
        // Set up the comment; check length, encode
        if( file_comment.length > ushort.max )
            ZipException.cotoolong;

        auto file_comment = utf8_to_cp437(this.file_comment);
        scope(exit) if( file_comment !is cast(ubyte[])this.file_comment )
                delete file_comment;

        // Set up data block
        Data data = this.data;
        data.file_comment_length = file_comment.length;
        
        version( BigEndian ) swapAll(data);
        writeExact(output, (&data)[0..1]);
    }

    void fill(void[] src)
    {
        //Stderr.formatln("EndOfCDRecord.fill([0..{}])",src.length);

        auto _data = data_arr;
        _data[] = src[0.._data.length];
        src = src[_data.length..$];
        version( BigEndian ) swapAll(data);

        //data.dump;

        file_comment = cast(char[]) src[0..data.file_comment_length].dup;
    }
}

// End of implementation crap
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Shared stuff

public
{
    /**
     * This enumeration denotes the kind of compression used on a file.
     */
    enum Method
    {
        /// No compression should be used.
        Store,
        /// Deflate compression.
        Deflate,
        /**
         * This is a special value used for unsupported or unrecognised
         * compression methods.  This value is only used internally.
         */
        Unsupported
    }
}

private
{
    const ushort ZIP_VERSION = 20;
    const ushort MAX_EXTRACT_VERSION = 20;

    /*                                     compression flags
                                  uses trailing descriptor |
                               utf-8 encoding            | |
                                            ^            ^ /\               */
    const ushort SUPPORTED_FLAGS = 0b00_0_0_0_0000_0_0_0_1_11_0;
    const ushort UNSUPPORTED_FLAGS = ~SUPPORTED_FLAGS;

    Method toMethod(ushort method)
    {
        switch( method )
        {
            case 0:     return Method.Store;
            case 8:     return Method.Deflate;
            default:    return Method.Unsupported;
        }
    }

    ushort fromMethod(Method method)
    {
        switch( method )
        {
            case Method.Store:      return 0;
            case Method.Deflate:    return 8;
            default:
                assert(false, "unsupported compression method");
        }
    }

    /* NOTE: This doesn't actually appear to work.  Using the default magic
     * number with Tango's Crc32 digest works, however.
     */
    //const CRC_MAGIC = 0xdebb20e3u;
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// ZipReader

interface ZipReader
{
    bool streamed();
    void close();
    bool more();
    ZipEntry get();
    ZipEntry get(ZipEntry);
    int opApply(int delegate(ref ZipEntry));
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// ZipWriter

interface ZipWriter
{
    void finish();
    void putFile(ZipEntryInfo info, char[] path);
    void putFile(ZipEntryInfo info, PathView path);
    void putStream(ZipEntryInfo info, InputStream source);
    void putEntry(ZipEntryInfo info, ZipEntry entry);
    void putData(ZipEntryInfo info, void[] data);
    Method method();
    Method method(Method);
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// ZipBlockReader

/**
 * The ZipBlockReader class is used to parse a Zip archive.  It exposes the
 * contents of the archive via an iteration interface.  For instance, to loop
 * over all files in an archive, one can use either
 *
 * -----
 *  foreach( entry ; reader )
 *      ...
 * -----
 *
 * Or
 *
 * -----
 *  while( reader.more )
 *  {
 *      auto entry = reader.get;
 *      ...
 *  }
 * -----
 * 
 * See the ZipEntry class for more information on the contents of entries.
 *
 * Note that this class can only be used with input sources which can be
 * freely seeked.  Also note that you may open a ZipEntry instance produced by
 * this reader at any time until the ZipReader that created it is closed.
 */
class ZipBlockReader : ZipReader
{
    /**
     * Creates a ZipBlockReader using the specified file on the local
     * filesystem.
     */
    this(char[] path)
    {
        this(FilePath(path));
    }

    /// ditto
    this(PathView path)
    {
        file_source = new FileConduit(path);
        this(file_source);
    }

version( none )
{
    /**
     * Creates a ZipBlockReader using the provided FileConduit instance.  Where
     * possible, the conduit will be wrapped in a memory-mapped buffer for
     * optimum performance.  If you do not want the FileConduit memory-mapped,
     * either cast it to an InputStream first, or pass source.input to the
     * constructor.
     */
    this(FileConduit source)
    {
        // BUG: MappedBuffer doesn't implement IConduit.Seek
        //mm_source = new MappedBuffer(source);
        //this(mm_source);
        this(source.input);
    }
}
    
    /**
     * Creates a ZipBlockReader using the provided InputStream.  Please note
     * that this InputStream must also implement the IConduit.Seek interface.
     */
    this(InputStream source)
    in
    {
        assert( cast(IConduit.Seek) source, "source stream must be seekable" );
    }
    body
    {
        this.source = source;
        this.seeker = cast(IConduit.Seek) source;
    }

    bool streamed() { return false; }

    /**
     * Closes the reader, and releases all resources.  After this operation,
     * all ZipEntry instances created by this ZipReader are invalid and should
     * not be used.
     */
    void close()
    {
        state = State.Done;
        source = null;
        seeker = null;
        delete headers;
        delete cd_data;

        if( file_source !is null )  delete file_source;
        if( mm_source !is null )    delete mm_source;
    }

    /**
     * Returns true if and only if there are additional files in the archive
     * which have not been read via the get method.  This returns true before
     * the first call to get (assuming the opened archive is non-empty), and
     * false after the last file has been accessed.
     */
    bool more()
    {
        switch( state )
        {
            case State.Init:
                read_cd;
                assert( state == State.Open );
                return more;
                
            case State.Open:
                return (current_index < headers.length);

            case State.Done:
                return false;
        }
    }

    /**
     * Retrieves the next file from the archive.  Note that although this does
     * perform IO operations, it will not read the contents of the file.
     *
     * The optional reuse argument can be used to instruct the reader to reuse
     * an existing ZipEntry instance.  If passed a null reference, it will
     * create a new ZipEntry instance.
     */
    ZipEntry get()
    {
        if( !more )
            ZipExhaustedException();
        
        return new ZipEntry(headers[current_index++], &open_file);
    }

    /// ditto
    ZipEntry get(ZipEntry reuse)
    {
        if( !more )
            ZipExhaustedException();

        if( reuse is null )
            return new ZipEntry(headers[current_index++], &open_file);
        else
            return reuse.reset(headers[current_index++], &open_file);
    }

    /**
     * This is used to iterate over the contents of an archive using a foreach
     * loop.  Please note that the iteration will reuse the ZipEntry instance
     * passed to your loop.  If you wish to keep the instance and re-use it
     * later, you $(B must) use the dup member to create a copy.
     */
    int opApply(int delegate(ref ZipEntry) dg)
    {
        int result = 0;
        ZipEntry entry;

        while( more )
        {
            entry = get(entry);
            
            result = dg(entry);
            if( result )
                break;
        }

        if( entry !is null )
            delete entry;

        return result;
    }

private:
    InputStream source;
    IConduit.Seek seeker;

    enum State { Init, Open, Done }
    State state;
    size_t current_index = 0;
    FileHeader[] headers;

    // These should be killed when the reader is closed.
    ubyte[] cd_data;
    FileConduit file_source = null;
    MappedBuffer mm_source = null;

    /*
     * This function will read the contents of the central directory.  Split
     * or spanned archives aren't supported.
     */
    void read_cd()
    in
    {
        assert( state == State.Init );
        assert( headers is null );
        assert( cd_data is null );
    }
    out
    {
        assert( state == State.Open );
        assert( headers !is null );
        assert( cd_data !is null );
        assert( current_index == 0 );
    }
    body
    {
        //Stderr.formatln("ZipReader.read_cd()");

        // First, we need to locate the end of cd record, so that we know
        // where the cd itself is, and how big it is.
        auto eocdr = read_eocd_record;

        // Now, make sure the archive is all in one file.
        if( eocdr.data.disk_number !=
                    eocdr.data.disk_with_start_of_central_directory
                || eocdr.data.central_directory_entries_on_this_disk !=
                    eocdr.data.central_directory_entries_total )
            ZipNotSupportedException.spanned;

        // Ok, read the whole damn thing in one go.
        cd_data = new ubyte[eocdr.data.size_of_central_directory];
        long cd_offset = eocdr.data.offset_of_start_of_cd_from_starting_disk;
        seeker.seek(cd_offset, IConduit.Seek.Anchor.Begin);
        readExact(source, cd_data);

        // Cake.  Now, we need to break it up into records.
        headers = new FileHeader[
            eocdr.data.central_directory_entries_total];

        long cdr_offset = cd_offset;

        // Ok, map the CD data into file headers.
        foreach( i,ref header ; headers )
        {
            //Stderr.formatln(" . reading header {}...", i);

            // Check signature
            {
                uint sig = (cast(uint[])(cd_data[0..4]))[0];
                version( BigEndian ) swap(sig);
                if( sig != FileHeader.signature )
                    ZipException.badsig("file header");
            }

            auto used = header.map(cd_data[4..$]);
            cd_data = cd_data[4+used..$];

            // Update offset for next record
            cdr_offset += 4 /* for sig. */ + used;
        }

        // Done!
        state = State.Open;
    }

    /*
     * This will locate the end of CD record in the open stream.
     *
     * This code sucks, but that's because Zip sucks.
     *
     * Basically, the EOCD record is stuffed somewhere at the end of the file.
     * In a brilliant move, the record is *variably sized*, which means we
     * have to do a linear backwards search to find it.
     *
     * The header itself (including the signature) is at minimum 22 bytes
     * long, plus anywhere between 0 and 2^16-1 bytes of comment.  That means
     * we need to read the last 2^16-1 + 22 bytes from the file, and look for
     * the signature [0x50,0x4b,0x05,0x06] in [0 .. $-18].
     *
     * If we find the EOCD record, we'll return its contents.  If we couldn't
     * find it, we'll throw an exception.
     */
    EndOfCDRecord read_eocd_record()
    in
    {
        assert( state == State.Init );
    }
    body
    {
        //Stderr.formatln("read_eocd_record()");

        // Signature + record + max. comment length
        const max_chunk_len = 4 + EndOfCDRecord.Data.sizeof + ushort.max;

        auto file_len = seeker.seek(0, IConduit.Seek.Anchor.End);

        // We're going to need min(max_chunk_len, file_len) bytes.
        long chunk_len = max_chunk_len;
        if( file_len < max_chunk_len )
            chunk_len = file_len;
        //Stderr.formatln(" . chunk_len = {}", chunk_len);

        // Seek back and read in the chunk.  Don't forget to clean up after
        // ourselves.
        seeker.seek(-chunk_len, IConduit.Seek.Anchor.End);
        auto chunk_offset = seeker.seek(0, IConduit.Seek.Anchor.Current);
        //Stderr.formatln(" . chunk_offset = {}", chunk_offset);
        auto chunk = new ubyte[chunk_len];
        scope(exit) delete chunk;
        readExact(source, chunk);

        // Now look for our magic number.  Don't forget that on big-endian
        // machines, we need to byteswap the value we're looking for.
        version( BigEndian )
            uint eocd_magic = swap(EndOfCDRecord.signature);
        else
            uint eocd_magic = EndOfCDRecord.signature;

        size_t eocd_loc = -1;

        for( size_t i=chunk_len-18; i>=0; --i )
        {
            if( *(cast(uint*)(chunk.ptr+i)) == eocd_magic )
            {
                // Found the bugger!  Make sure we skip the signature (forgot
                // to do that originally; talk about weird errors :P)
                eocd_loc = i+4;
                break;
            }
        }

        // If we didn't find it, then we'll assume that this is not a valid
        // archive.
        if( eocd_loc == -1 )
            ZipException.missingdir;

        // Ok, so we found it; now what?  Now we need to read the record
        // itself in.  eocd_loc is the offset within the chunk where the eocd
        // record was found, so slice it out.
        EndOfCDRecord eocdr;
        eocdr.fill(chunk[eocd_loc..$]);

        // Excellent.  We're done here.
        return eocdr;
    }

    /*
     * Opens the specified file for reading.  If the raw argument passed is
     * true, then the file is *not* decompressed.
     */
    InputStream open_file(FileHeader header, bool raw)
    {
        // Check to make sure that we actually *can* open this file.
        if( header.data.extract_version > MAX_EXTRACT_VERSION )
            ZipNotSupportedException.zipver(header.data.extract_version);

        if( header.data.general_flags & UNSUPPORTED_FLAGS )
            ZipNotSupportedException.flags;

        if( toMethod(header.data.compression_method) == Method.Unsupported )
            ZipNotSupportedException.method(header.data.compression_method);

        // Open a raw stream
        InputStream stream = open_file_raw(header);

        // If that's all they wanted, pass it back.
        if( raw )
            return stream;

        // Next up, wrap in an appropriate decompression stream
        switch( toMethod(header.data.compression_method) )
        {
            case Method.Store:
                // Do nothing: \o/
                break;

            case Method.Deflate:
                // Wrap in a zlib stream.  -15 means to use a 32KB window, and
                // not to look for the normal zlib header and trailer.
                stream = new ZlibInput(stream, -15);
                break;

            default:
                assert(false);
        }

        // We done, yo!
        return stream;
    }

    /*
     * Opens a file's raw input stream.  Basically, this returns a slice of
     * the archive's input stream.
     */
    InputStream open_file_raw(FileHeader header)
    {
        // Seek to and parse the local file header
        seeker.seek(header.data.relative_offset_of_local_header,
                IConduit.Seek.Anchor.Begin);

        {
            uint sig;
            readExact(source, (&sig)[0..1]);
            version( BigEndian ) swap(sig);
            if( sig != LocalFileHeader.signature )
                ZipException.badsig("local file header");
        }

        LocalFileHeader lheader; lheader.fill(source);
        
        if( !lheader.agrees_with(header) )
            ZipException.incons(header.file_name);
        
        // Ok; get a slice stream for the file
        return new SliceSeekInputStream(
             source, seeker.seek(0, IConduit.Seek.Anchor.Current),
             header.data.compressed_size);
    }
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// ZipBlockWriter

/**
 * The ZipBlockWriter class is used to create a Zip archive.  It uses a
 * writing iterator interface.
 *
 * Note that this class can only be used with output streams which can be
 * freely seeked.
 */

class ZipBlockWriter : ZipWriter
{
    /**
     * Creates a ZipBlockWriter using the specified file on the local
     * filesystem.
     */
    this(char[] path)
    {
        this(FilePath(path));
    }
    
    /// ditto
    this(PathView path)
    {
        file_output = new FileConduit(path, FileConduit.WriteCreate);
        this(file_output);
    }

    /**
     * Creates a ZipBlockWriter using the provided OutputStream.  Please note
     * that this OutputStream must also implement the IConduit.Seek interface.
     */
    this(OutputStream output)
    in
    {
        assert( output !is null );
        assert( (cast(IConduit.Seek) output) !is null );
    }
    body
    {
        this.output = output;
        this.seeker = cast(IConduit.Seek) output;

        // Default to Deflate compression
        method = Method.Deflate;
    }

    /**
     * Finalises the archive, writes out the central directory, and closes the
     * output stream.
     */
    void finish()
    {
        put_cd;
        output.close();
        output = null;
        seeker = null;

        if( file_output !is null ) delete file_output;
    }

    /**
     * Adds a file from the local filesystem to the archive.
     */
    void putFile(ZipEntryInfo info, char[] path)
    {
        putFile(info, FilePath(path));
    }

    /// ditto
    void putFile(ZipEntryInfo info, PathView path)
    {
        scope file = new FileConduit(path);
        scope(exit) file.close();
        putStream(info, file);
    }

    /**
     * Adds a file using the contents of the given InputStream to the archive.
     */
    void putStream(ZipEntryInfo info, InputStream source)
    {
        put_compressed(info, source);
    }

    /**
     * Transfers a file from another archive into this archive.  Note that
     * this method will not perform any compression: whatever compression was
     * applied to the file originally will be preserved.
     */
    void putEntry(ZipEntryInfo info, ZipEntry entry)
    {
        put_raw(info, entry);
    }

    /**
     * Adds a file using the contents of the given array to the archive.
     */
    void putData(ZipEntryInfo info, void[] data)
    {
        //scope mc = new MemoryConduit(data);
        scope mc = new Buffer(data);
        scope(exit) mc.close;
        put_compressed(info, mc);
    }

    /**
     * This property allows you to control what compression method should be
     * used for files being added to the archive.
     */
    Method method() { return _method; }
    Method method(Method v) { return _method = v; } /// ditto

private:
    OutputStream output;
    IConduit.Seek seeker;
    FileConduit file_output;

    Method _method;

    struct Entry
    {
        FileHeaderData data;
        long header_position;
        char[] filename;
        char[] comment;
        ubyte[] extra;
    }
    Entry[] entries;

    void put_cd()
    {
        // check that there aren't too many CD entries
        if( entries.length > ushort.max )
            ZipException.toomanyentries;

        auto cd_pos = seeker.seek(0, IConduit.Seek.Anchor.Current);
        if( cd_pos > uint.max )
            ZipException.toolong;

        foreach( entry ; entries )
        {
            FileHeader header;
            header.data = &entry.data;
            header.file_name = entry.filename;
            header.extra_field = entry.extra;
            header.file_comment = entry.comment;

            write(output, FileHeader.signature);
            header.put(output);
        }

        auto cd_len = seeker.seek(0, IConduit.Seek.Anchor.Current) - cd_pos;

        if( cd_len > uint.max )
            ZipException.cdtoolong;

        {
            EndOfCDRecord eocdr;
            eocdr.data.central_directory_entries_on_this_disk =
                entries.length;
            eocdr.data.central_directory_entries_total = entries.length;
            eocdr.data.size_of_central_directory = cd_len;
            eocdr.data.offset_of_start_of_cd_from_starting_disk = cd_pos;

            write(output, EndOfCDRecord.signature);
            eocdr.put(output);
        }
    }

    void put_raw(ZipEntryInfo info, ZipEntry entry)
    {
        // Write out local file header
        LocalFileHeader.Data lhdata;
        auto chdata = entry.header.data;
        lhdata.extract_version = chdata.extract_version;
        lhdata.general_flags = chdata.general_flags;
        lhdata.compression_method = chdata.compression_method;
        lhdata.crc_32 = chdata.crc_32;
        lhdata.compressed_size = chdata.compressed_size;
        lhdata.uncompressed_size = chdata.uncompressed_size;

        timeToDos(info.modified, lhdata.modification_file_time,
                                 lhdata.modification_file_date);
        
        put_local_header(lhdata, info.name);
        
        // Store comment
        entries[$-1].comment = info.comment;

        // Output file contents
        {
            auto input = entry.open_raw;
            scope(exit) input.close;
            output.copy(input).flush();
        }
    }

    void put_compressed(ZipEntryInfo info, InputStream source)
    {
        debug(Zip) Stderr.formatln("ZipBlockWriter.put_compressed()");

        // Write out partial local file header
        auto header_pos = seeker.seek(0, IConduit.Seek.Anchor.Current);
        debug(Zip) Stderr.formatln(" . header for {} at {}", info.name, header_pos);
        put_local_header(info, _method);

        // Store comment
        entries[$-1].comment = info.comment;

        uint crc;
        uint compressed_size;
        uint uncompressed_size;

        // Output file contents
        {
            // Input/output chains
            InputStream in_chain = source;
            OutputStream out_chain = new WrapSeekOutputStream(output);

            // Count number of bytes coming in from the source file
            scope in_counter = new CounterInput(in_chain);
            in_chain = in_counter;
            scope(success) uncompressed_size = in_counter.count;

            // Count the number of bytes going out to the archive
            scope out_counter = new CounterOutput(out_chain);
            out_chain = out_counter;
            scope(success) compressed_size = out_counter.count;

            // Add crc
            scope crc_d = new Crc32(/*CRC_MAGIC*/);
            scope crc_s = new DigestInput(in_chain, crc_d);
            in_chain = crc_s;
            scope(success)
            {
                debug(Zip) Stderr.formatln(" . Success: storing CRC.");
                crc = crc_d.crc32Digest;
            }

            // Add compression
            ZlibOutput compress;
            scope(exit) if( compress !is null ) delete compress;

            switch( _method )
            {
                case Method.Store:
                    break;

                case Method.Deflate:
                    compress = new ZlibOutput(out_chain,
                            ZlibOutput.Level.init, -15);
                    out_chain = compress;
                    break;
            }

            // All done.
            scope(exit) in_chain.close();
            scope(success) in_chain.clear();
            scope(exit) out_chain.close();

            out_chain.copy(in_chain).flush;

            debug(Zip) if( compress !is null )
            {
                Stderr.formatln(" . compressed to {} bytes", compress.written);
            }

            debug(Zip) Stderr.formatln(" . wrote {} bytes", out_counter.count);
            debug(Zip) Stderr.formatln(" . contents written");
        }

        debug(Zip) Stderr.formatln(" . CRC for \"{}\": 0x{:x8}", info.name, crc);

        // Rewind, and patch the header
        auto final_pos = seeker.seek(0, IConduit.Seek.Anchor.Current);
        seeker.seek(header_pos);
        patch_local_header(crc, compressed_size, uncompressed_size);

        // Seek back to the end of the file, and we're done!
        seeker.seek(final_pos);
    }

    /*
     * Patches the local file header starting at the current output location
     * with updated crc and size information.  Also updates the current last
     * Entry.
     */
    void patch_local_header(uint crc_32, uint compressed_size,
            uint uncompressed_size)
    {
        /* BUG: For some reason, this code won't compile.  No idea why... if
         * you instantiate LFHD, it says that there is no "offsetof" property.
         */
        /+
        alias LocalFileHeaderData LFHD;
        static assert( LFHD.compressed_size.offsetof
                == LFHD.crc_32.offsetof + 4 );
        static assert( LFHD.uncompressed_size.offsetof
                == LFHD.compressed_size.offsetof + 4 );
        +/

        // Don't forget we have to seek past the signature, too
        // BUG: .offsetof is broken here
        /+seeker.seek(LFHD.crc_32.offsetof+4, IConduit.Seek.Anchor.Current);+/
        seeker.seek(10+4, IConduit.Seek.Anchor.Current);
        write(output, crc_32);
        write(output, compressed_size);
        write(output, uncompressed_size);

        with( entries[$-1] )
        {
            data.crc_32 = crc_32;
            data.compressed_size = compressed_size;
            data.uncompressed_size = uncompressed_size;
        }
    }

    /*
     * Generates and outputs a local file header from the given info block and
     * compression method.  Note that the crc_32, compressed_size and
     * uncompressed_size header fields will be set to zero, and must be
     * patched.
     */
    void put_local_header(ZipEntryInfo info, Method method)
    {
        LocalFileHeader.Data data;

        data.compression_method = fromMethod(method);
        timeToDos(info.modified, data.modification_file_time,
                                 data.modification_file_date);

        put_local_header(data, info.name);
    }

    /*
     * Writes the given local file header data and filename out to the output
     * stream.  It also appends a new Entry with the data and filename.
     */
    void put_local_header(LocalFileHeaderData data,
            char[] file_name)
    {
        // Compute Zip version
        if( data.extract_version == data.extract_version.max )
        {
            ushort zipver = 10;
            void minver(ushort v) { zipver = v>zipver ? v : zipver; }

            {
                // Compression method
                switch( data.compression_method )
                {
                    case 0: minver(10); break;
                    case 8: minver(20); break;
                }

                // File is a folder
                if( file_name.length > 0 && file_name[$-1] == '/'
                        || file_name[$-1] == '\\' )
                    // Is a directory, not a real file
                    minver(20);
            }
            data.extract_version = zipver;
        }

        /+// Encode filename
        auto file_name_437 = utf8_to_cp437(file_name);
        if( file_name_437 is null )
            ZipException.fnencode;+/

        /+// Set up file name length
        if( file_name_437.length > ushort.max )
            ZipException.fntoolong;

        data.file_name_length = file_name_437.length;+/

        LocalFileHeader header;
        header.data = data;
        header.file_name = file_name;

        // Write out the header and the filename
        auto header_pos = seeker.seek(0, IConduit.Seek.Anchor.Current);
        
        write(output, LocalFileHeader.signature);
        header.put(output);

        // Save the header
        Entry entry;
        entry.data.fromLocal(header.data);
        entry.filename = file_name;
        entry.header_position = header_pos;
        entry.data.relative_offset_of_local_header = header_pos;
        entries ~= entry;
    }
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// ZipEntry

/**
 * This class is used to represent a single entry in an archive.
 * Specifically, it combines meta-data about the file (see the info field)
 * along with the two basic operations on an entry: open and verify.
 */
class ZipEntry
{
    /**
     * Header information on the file.  See the ZipEntryInfo structure for
     * more information.
     */
    ZipEntryInfo info;

    /**
     * Size (in bytes) of the file's uncompressed contents.
     */
    uint size()
    {
        return header.data.uncompressed_size;;
    }
    
    /**
     * Opens a stream for reading from the file.  The contents of this stream
     * represent the decompressed contents of the file stored in the archive.
     *
     * You should not assume that the returned stream is seekable.
     *
     * Note that the returned stream may be safely closed without affecting
     * the underlying archive stream.
     *
     * If the file has not yet been verified, then the stream will be checked
     * as you read from it.  When the stream is either exhausted or closed,
     * then the integrity of the file's data will be checked.  This means that
     * if the file is corrupt, an exception will be thrown only after you have
     * finished reading from the stream.  If you wish to make sure the data is
     * valid before you read from the file, call the verify method.
     */
    InputStream open()
    {
        // If we haven't verified yet, wrap the stream in the appropriate
        // decorators.
        if( !verified )
            return new ZipEntryVerifier(this, open_dg(header, false));

        else
            return open_dg(header, false);
    }

    /**
     * Verifies the contents of this file by computing the CRC32 checksum,
     * and comparing it against the stored one.  Throws an exception if the
     * checksums do not match.
     *
     * Not valid on streamed Zip archives.
     */
    void verify()
    {
        // If we haven't verified the contents yet, just read everything in
        // to trigger it.
        scope s = open;
        auto buffer = new ubyte[s.conduit.bufferSize];
        while( s.read(buffer) != s.Eof )
            {/*Do nothing*/}
        s.close;
    }

    /**
     * Creates a new, independent copy of this instance.
     */
    ZipEntry dup()
    {
        return new ZipEntry(header, open_dg);
    }

private:
    /*
     * Callback used to open the file.
     */
    alias InputStream delegate(FileHeader, bool raw) open_dg_t;
    open_dg_t open_dg;

    /*
     * Raw ZIP header.
     */
    FileHeader header;

    /*
     * The flag used to keep track of whether the file's contents have been
     * verified.
     */
    bool verified = false;

    /*
     * Opens a stream that does not perform any decompression or
     * transformation of the file contents.  This is used internally by
     * ZipWriter to perform fast zip to zip transfers without having to
     * decompress and then recompress the contents.
     *
     * Note that because zip stores CRCs for the *uncompressed* data, this
     * method currently does not do any verification.
     */
    InputStream open_raw()
    {
        return open_dg(header, true);
    }

    /*
     * Creates a new ZipEntry from the FileHeader.
     */
    this(FileHeader header, open_dg_t open_dg)
    {
        this.reset(header, open_dg);
    }

    /*
     * Resets the current instance with new values.
     */
    ZipEntry reset(FileHeader header, open_dg_t open_dg)
    {
        this.header = header;
        this.open_dg = open_dg;
        with( info )
        {
            name = header.file_name.dup;
            dosToTime(header.data.modification_file_time,
                      header.data.modification_file_date,
                      modified);
            comment = header.file_comment.dup;
        }

        this.verified = false;

        return this;
    }
}

/**
 * This structure contains various pieces of meta-data on a file.  The
 * contents of this structure may be safely mutated.
 *
 * This structure is also used to specify meta-data about a file when adding
 * it to an archive.
 */
struct ZipEntryInfo
{
    /// Full path and file name of this file.
    char[] name;
    /// Modification timestamp.  If this is left uninitialised when passed to
    /// a ZipWriter, it will be reset to the current system time.
    Time modified = Time.min;
    /// Comment on the file.
    char[] comment;
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Exceptions
//

import tango.core.Exception : TracedException;

/**
 * This is the base class from which all exceptions generated by this module
 * derive from.
 */
class ZipException : TracedException
{
    this(char[] msg) { super(msg); }

private:
    alias typeof(this) thisT;
    static void opCall(char[] msg) { throw new ZipException(msg); }

    static void badsig()
    {
        thisT("corrupt signature or unexpected section found");
    }

    static void badsig(char[] type)
    {
        thisT("corrupt "~type~" signature or unexpected section found");
    }

    static void incons(char[] name)
    {
        thisT("inconsistent headers for file \""~name~"\"; "
                "archive is likely corrupted");
    }

    static void missingdir()
    {
        thisT("could not locate central archive directory; "
                "file is corrupt or possibly not a Zip archive");
    }

    static void toomanyentries()
    {
        thisT("too many archive entries");
    }

    static void toolong()
    {
        thisT("archive is too long; limited to 4GB total");
    }

    static void cdtoolong()
    {
        thisT("central directory is too long; limited to 4GB total");
    }

    static void fntoolong()
    {
        thisT("file name too long; limited to 65,535 characters");
    }

    static void eftoolong()
    {
        thisT("extra field too long; limited to 65,535 characters");
    }

    static void cotoolong()
    {
        thisT("extra field too long; limited to 65,535 characters");
    }

    static void fnencode()
    {
        thisT("could not encode filename into codepage 437");
    }

    static void coencode()
    {
        thisT("could not encode comment into codepage 437");
    }

    static void tooold()
    {
        thisT("cannot represent dates before January 1, 1980");
    }
}

/**
 * This exception is thrown if a ZipReader detects that a file's contents do
 * not match the stored checksum.
 */
class ZipChecksumException : ZipException
{
    this(char[] name)
    {
        super("checksum failed on zip entry \""~name~"\"");
    }

private:
    static void opCall(char[] name) { throw new ZipChecksumException(name); }
}

/**
 * This exception is thrown if you call get reader method when there are no
 * more files in the archive.
 */
class ZipExhaustedException : ZipException
{
    this() { super("no more entries in archive"); }

private:
    static void opCall() { throw new ZipExhaustedException; }
}

/**
 * This exception is thrown if you attempt to read an archive that uses
 * features not supported by the reader.
 */
class ZipNotSupportedException : ZipException
{
    this(char[] msg) { super(msg); }

private:
    alias ZipNotSupportedException thisT;

    static void opCall(char[] msg)
    {
        throw new thisT(msg ~ " not supported");
    }

    static void spanned()
    {
        thisT("split and multi-disk archives");
    }

    static void zipver(ushort ver)
    {
        throw new thisT("zip format version "
                ~Integer.toString(ver / 10)
                ~"."
                ~Integer.toString(ver % 10)
                ~" not supported; maximum of version "
                ~Integer.toString(MAX_EXTRACT_VERSION / 10)
                ~"."
                ~Integer.toString(MAX_EXTRACT_VERSION % 10)
                ~" supported.");
    }

    static void flags()
    {
        throw new thisT("unknown or unsupported file flags enabled");
    }

    static void method(ushort m)
    {
        // Cheat here and work out what the method *actually* is
        char[] ms;
        switch( m )
        {
            case 0:     
            case 8:     assert(false); // supported

            case 1:     ms = "Shrink"; break;
            case 2:     ms = "Reduce (factor 1)"; break;
            case 3:     ms = "Reduce (factor 2)"; break;
            case 4:     ms = "Reduce (factor 3)"; break;
            case 5:     ms = "Reduce (factor 4)"; break;
            case 6:     ms = "Implode"; break;

            case 9:     ms = "Deflate64"; break;
            case 10:    ms = "TERSE (old)"; break;

            case 12:    ms = "Bzip2"; break;
            case 14:    ms = "LZMA"; break;

            case 18:    ms = "TERSE (new)"; break;
            case 19:    ms = "LZ77"; break;

            case 97:    ms = "WavPack"; break;
            case 98:    ms = "PPMd"; break;

            default:    ms = "unknown";
        }

        thisT(ms ~ " compression method");
    }
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Convenience methods

void createArchive(char[] archive, Method method, char[][] files...)
{
    scope zw = new ZipBlockWriter(archive);
    zw.method = method;

    foreach( file ; files )
        zw.putFile(ZipEntryInfo(file), file);

    zw.finish;
}

void createArchive(PathView archive, Method method, PathView[] files...)
{
    scope zw = new ZipBlockWriter(archive);
    zw.method = method;

    foreach( file ; files )
        zw.putFile(ZipEntryInfo(file.toString), file);

    zw.finish;
}

void extractArchive(char[] archive, char[] folder)
{
    extractArchive(FilePath(archive), FilePath(folder));
}

void extractArchive(PathView archive, PathView dest)
{
    scope folder = FilePath(dest.toString);
    scope zr = new ZipBlockReader(archive);

    foreach( entry ; zr )
    {
        // Skip directories
        if( entry.info.name[$-1] == '/' ) continue;

        auto path = folder.dup.append(entry.info.name);
        scope fout = new FileConduit(path, FileConduit.WriteCreate);
        fout.output.copy(entry.open);
    }
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Private implementation stuff
//

private:

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Verification stuff

/*
 * This class wraps an input stream, and computes the CRC as it passes
 * through.  On the event of either a close or EOF, it checks the CRC against
 * the one in the provided ZipEntry.  If they don't match, it throws an
 * exception.
 */

class ZipEntryVerifier : InputStream
{
    this(ZipEntry entry, InputStream source)
    in
    {
        assert( entry !is null );
        assert( source !is null );
    }
    body
    {
        this.entry = entry;
        this.digest = new Crc32;
        this.source = new DigestInput(source, digest);
    }

    IConduit conduit()
    {
        return source.conduit;
    }

    void close()
    {
        check;

        this.source.close;
        this.entry = null;
        this.digest = null;
        this.source = null;
    }

    uint read(void[] dst)
    {
        auto bytes = source.read(dst);
        if( bytes == IConduit.Eof )
            check;
        return bytes;
    }

    InputStream clear()
    {
        this.source.clear;
        return this;
    }

private:
    Crc32 digest;
    InputStream source;
    ZipEntry entry;

    void check()
    {
        if( digest is null ) return;

        auto crc = digest.crc32Digest;
        delete digest;

        if( crc != entry.header.data.crc_32 )
            ZipChecksumException(entry.info.name);

        else
            entry.verified = true;
    }
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// IO functions

/*
 * Really, seriously, read some bytes without having to go through a sodding
 * buffer.
 */
void readExact(InputStream s, void[] dst)
{
    //Stderr.formatln("readExact(s, [0..{}])", dst.length);
    while( dst.length > 0 )
    {
        auto octets = s.read(dst);
        //Stderr.formatln(" . octets = {}", octets);
        if( octets == -1 ) // Beware the dangers of MAGICAL THINKING
            throw new Exception("unexpected end of stream");
        dst = dst[octets..$];
    }
}

/*
 * Really, seriously, write some bytes.
 */
void writeExact(OutputStream s, void[] src)
{
    while( src.length > 0 )
    {
        auto octets = s.write(src);
        if( octets == -1 )
            throw new Exception("unexpected end of stream");
        src = src[octets..$];
    }
}

void write(T)(OutputStream s, T value)
{
    version( BigEndian ) swap(value);
    writeExact(s, (&value)[0..1]);
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Endian garbage

void swapAll(T)(inout T data)
{
    static if( is(typeof(T.record_fields)) )
        const fields = T.record_fields;
    else
        const fields = data.tupleof.length;

    foreach( i,_ ; data.tupleof )
    {
        if( i == fields ) break;
        swap(data.tupleof[i]);
    }
}

void swap(T)(inout T data)
{
    static if( T.sizeof == 1 )
        {}
    else static if( T.sizeof == 2 )
        ByteSwap.swap16(&data, 2);
    else static if( T.sizeof == 4 )
        ByteSwap.swap32(&data, 4);
    else static if( T.sizeof == 8 )
        ByteSwap.swap64(&data, 8);
    else static if( T.sizeof == 10 )
        ByteSwap.swap80(&data, 10);
    else
        static assert(false, "Can't swap "~T.stringof~"s.");
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// IBM Code Page 437 stuff
//

const char[][] cp437_to_utf8_map_low = [
    "\u0000"[], "\u263a",   "\u263b",   "\u2665",
    "\u2666",   "\u2663",   "\u2660",   "\u2022",
    "\u25d8",   "\u25cb",   "\u25d9",   "\u2642",
    "\u2640",   "\u266a",   "\u266b",   "\u263c",

    "\u25b6",   "\u25c0",   "\u2195",   "\u203c",
    "\u00b6",   "\u00a7",   "\u25ac",   "\u21a8",
    "\u2191",   "\u2193",   "\u2192",   "\u2190",
    "\u221f",   "\u2194",   "\u25b2",   "\u25bc"
];

const char[][] cp437_to_utf8_map_high = [
    "\u00c7"[], "\u00fc",   "\u00e9",   "\u00e2",
    "\u00e4",   "\u00e0",   "\u00e5",   "\u00e7",
    "\u00ea",   "\u00eb",   "\u00e8",   "\u00ef",
    "\u00ee",   "\u00ec",   "\u00c4",   "\u00c5",

    "\u00c9",   "\u00e6",   "\u00c6",   "\u00f4",
    "\u00f6",   "\u00f2",   "\u00fb",   "\u00f9",
    "\u00ff",   "\u00d6",   "\u00dc",   "\u00f8",
    "\u00a3",   "\u00a5",   "\u20a7",   "\u0192",

    "\u00e1",   "\u00ed",   "\u00f3",   "\u00fa",
    "\u00f1",   "\u00d1",   "\u00aa",   "\u00ba",
    "\u00bf",   "\u2310",   "\u00ac",   "\u00bd",
    "\u00bc",   "\u00a1",   "\u00ab",   "\u00bb",

    "\u2591",   "\u2592",   "\u2593",   "\u2502",
    "\u2524",   "\u2561",   "\u2562",   "\u2556",
    "\u2555",   "\u2563",   "\u2551",   "\u2557",
    "\u255d",   "\u255c",   "\u255b",   "\u2510",

    "\u2514",   "\u2534",   "\u252c",   "\u251c",
    "\u2500",   "\u253c",   "\u255e",   "\u255f",
    "\u255a",   "\u2554",   "\u2569",   "\u2566",
    "\u2560",   "\u2550",   "\u256c",   "\u2567",

    "\u2568",   "\u2564",   "\u2565",   "\u2559",
    "\u2558",   "\u2552",   "\u2553",   "\u256b",
    "\u256a",   "\u2518",   "\u250c",   "\u2588",
    "\u2584",   "\u258c",   "\u2590",   "\u2580",
    "\u03b1",   "\u00df",   "\u0393",   "\u03c0",
    "\u03a3",   "\u03c3",   "\u00b5",   "\u03c4",
    "\u03a6",   "\u0398",   "\u03a9",   "\u03b4",
    "\u221e",   "\u03c6",   "\u03b5",   "\u2229",

    "\u2261",   "\u00b1",   "\u2265",   "\u2264",
    "\u2320",   "\u2321",   "\u00f7",   "\u2248",
    "\u00b0",   "\u2219",   "\u00b7",   "\u221a",
    "\u207f",   "\u00b2",   "\u25a0",   "\u00a0"
];

char[] cp437_to_utf8(ubyte[] s)
{
    foreach( i,c ; s )
    {
        if( (1 <= c && c <= 31) || c >= 127 )
        {
            /* Damn; we got a character not in ASCII.  Since this is the first
             * non-ASCII character we found, copy everything up to this point
             * into the output verbatim.  We'll allocate twice as much space
             * as there are remaining characters to ensure we don't need to do
             * any further allocations.
             */
            auto r = new char[i+2*(s.length-i)];
            r[0..i] = cast(char[]) s[0..i];
            size_t k=i; // current length

            // We insert new characters at r[i+j+k]

            foreach( d ; s[i..$] )
            {
                if( 32 <= d && d <= 126 || d == 0 )
                {
                    r[k++] = d;
                }
                else if( 1 <= d && d <= 31 )
                {
                    char[] repl = cp437_to_utf8_map_low[d];
                    r[k..k+repl.length] = repl[];
                    k += repl.length;
                }
                else if( d == 127 )
                {
                    char[] repl = "\u2302";
                    r[k..k+repl.length] = repl[];
                    k += repl.length;
                }
                else if( d > 127 )
                {
                    char[] repl = cp437_to_utf8_map_high[d-128];
                    r[k..k+repl.length] = repl[];
                    k += repl.length;
                }
                else
                    assert(false);
            }

            return r[0..k];
        }
    }

    /* If we got here, then all the characters in s are also in ASCII, which
     * means it's also valid UTF-8; return the string unmodified.
     */
    return cast(char[]) s;
}

debug( UnitTest )
{
    unittest
    {
        char[] c(char[] s) { return cp437_to_utf8(cast(ubyte[]) s); }

        auto s = c("Hi there \x01 old \x0c!");
        assert( s == "Hi there \u263a old \u2640!", "\""~s~"\"" );
        s = c("Marker \x7f and divide \xf6.");
        assert( s == "Marker \u2302 and divide \u00f7.", "\""~s~"\"" );
    }
}

const char[dchar] utf8_to_cp437_map;

static this()
{
    utf8_to_cp437_map = [
        '\u0000': '\x00', '\u263a': '\x01', '\u263b': '\x02', '\u2665': '\x03',
        '\u2666': '\x04', '\u2663': '\x05', '\u2660': '\x06', '\u2022': '\x07',
        '\u25d8': '\x08', '\u25cb': '\x09', '\u25d9': '\x0a', '\u2642': '\x0b',
        '\u2640': '\x0c', '\u266a': '\x0d', '\u266b': '\x0e', '\u263c': '\x0f',

        '\u25b6': '\x10', '\u25c0': '\x11', '\u2195': '\x12', '\u203c': '\x13',
        '\u00b6': '\x14', '\u00a7': '\x15', '\u25ac': '\x16', '\u21a8': '\x17',
        '\u2191': '\x18', '\u2193': '\x19', '\u2192': '\x1a', '\u2190': '\x1b',
        '\u221f': '\x1c', '\u2194': '\x1d', '\u25b2': '\x1e', '\u25bc': '\x1f',

        /*
         * Printable ASCII range (well, most of it) is handled specially.
         */

        '\u00c7': '\x80', '\u00fc': '\x81', '\u00e9': '\x82', '\u00e2': '\x83',
        '\u00e4': '\x84', '\u00e0': '\x85', '\u00e5': '\x86', '\u00e7': '\x87',
        '\u00ea': '\x88', '\u00eb': '\x89', '\u00e8': '\x8a', '\u00ef': '\x8b',
        '\u00ee': '\x8c', '\u00ec': '\x8d', '\u00c4': '\x8e', '\u00c5': '\x8f',
    
        '\u00c9': '\x90', '\u00e6': '\x91', '\u00c6': '\x92', '\u00f4': '\x93',
        '\u00f6': '\x94', '\u00f2': '\x95', '\u00fb': '\x96', '\u00f9': '\x97',
        '\u00ff': '\x98', '\u00d6': '\x99', '\u00dc': '\x9a', '\u00f8': '\x9b',
        '\u00a3': '\x9c', '\u00a5': '\x9d', '\u20a7': '\x9e', '\u0192': '\x9f',
    
        '\u00e1': '\xa0', '\u00ed': '\xa1', '\u00f3': '\xa2', '\u00fa': '\xa3',
        '\u00f1': '\xa4', '\u00d1': '\xa5', '\u00aa': '\xa6', '\u00ba': '\xa7',
        '\u00bf': '\xa8', '\u2310': '\xa9', '\u00ac': '\xaa', '\u00bd': '\xab',
        '\u00bc': '\xac', '\u00a1': '\xad', '\u00ab': '\xae', '\u00bb': '\xaf',
    
        '\u2591': '\xb0', '\u2592': '\xb1', '\u2593': '\xb2', '\u2502': '\xb3',
        '\u2524': '\xb4', '\u2561': '\xb5', '\u2562': '\xb6', '\u2556': '\xb7',
        '\u2555': '\xb8', '\u2563': '\xb9', '\u2551': '\xba', '\u2557': '\xbb',
        '\u255d': '\xbc', '\u255c': '\xbd', '\u255b': '\xbe', '\u2510': '\xbf',
    
        '\u2514': '\xc0', '\u2534': '\xc1', '\u252c': '\xc2', '\u251c': '\xc3',
        '\u2500': '\xc4', '\u253c': '\xc5', '\u255e': '\xc6', '\u255f': '\xc7',
        '\u255a': '\xc8', '\u2554': '\xc9', '\u2569': '\xca', '\u2566': '\xcb',
        '\u2560': '\xcc', '\u2550': '\xcd', '\u256c': '\xce', '\u2567': '\xcf',
    
        '\u2568': '\xd0', '\u2564': '\xd1', '\u2565': '\xd2', '\u2559': '\xd3',
        '\u2558': '\xd4', '\u2552': '\xd5', '\u2553': '\xd6', '\u256b': '\xd7',
        '\u256a': '\xd8', '\u2518': '\xd9', '\u250c': '\xda', '\u2588': '\xdb',
        '\u2584': '\xdc', '\u258c': '\xdd', '\u2590': '\xde', '\u2580': '\xdf',

        '\u03b1': '\xe0', '\u00df': '\xe1', '\u0393': '\xe2', '\u03c0': '\xe3',
        '\u03a3': '\xe4', '\u03c3': '\xe5', '\u00b5': '\xe6', '\u03c4': '\xe7',
        '\u03a6': '\xe8', '\u0398': '\xe9', '\u03a9': '\xea', '\u03b4': '\xeb',
        '\u221e': '\xec', '\u03c6': '\xed', '\u03b5': '\xee', '\u2229': '\xef',
    
        '\u2261': '\xf0', '\u00b1': '\xf1', '\u2265': '\xf2', '\u2264': '\xf3',
        '\u2320': '\xf4', '\u2321': '\xf5', '\u00f7': '\xf6', '\u2248': '\xf7',
        '\u00b0': '\xf8', '\u2219': '\xf9', '\u00b7': '\xfa', '\u221a': '\xfb',
        '\u207f': '\xfc', '\u00b2': '\xfd', '\u25a0': '\xfe', '\u00a0': '\xff'
    ];
}

ubyte[] utf8_to_cp437(char[] s)
{
    foreach( i,dchar c ; s )
    {
        if( !((32 <= c && c <= 126) || c == 0) )
        {
            /* We got a character not in CP 437: we need to create a buffer to
             * hold the new string.  Since UTF-8 is *always* larger than CP
             * 437, we need, at most, an array of the same number of elements.
             */
            auto r = new ubyte[s.length];
            r[0..i] = cast(ubyte[]) s[0..i];
            size_t k=i;

            foreach( dchar d ; s[i..$] )
            {
                if( 32 <= d && d <= 126 || d == 0 )
                    r[k++] = d;
                
                else if( d == '\u2302' )
                    r[k++] = '\x7f';

                else if( auto e_ptr = d in utf8_to_cp437_map )
                    r[k++] = *e_ptr;
                
                else
                {
                    throw new Exception("cannot encode character \""
                            ~ Integer.toString(cast(uint)d)
                            ~ "\" in codepage 437.");
                }
            }

            return r[0..k];
        }
    }

    // If we got here, then the entire string is printable ASCII, which just
    // happens to *also* be valid CP 437!  Huzzah!
    return cast(ubyte[]) s;
}

debug( UnitTest )
{
    unittest
    {
        alias cp437_to_utf8 x;
        alias utf8_to_cp437 y;

        ubyte[256] s;
        foreach( i,ref c ; s )
            c = i;

        auto a = x(s);
        auto b = y(a);
        if(!( b == s ))
        {
            // Display list of characters that failed to convert as expected,
            // and what value we got.
            auto hex = "0123456789abcdef";
            auto msg = "".dup;
            foreach( i,ch ; b )
            {
                if( ch != i )
                {
                    msg ~= hex[i>>4];
                    msg ~= hex[i&15];
                    msg ~= " (";
                    msg ~= hex[ch>>4];
                    msg ~= hex[ch&15];
                    msg ~= "), ";
                }
            }
            msg ~= "failed.";

            assert( false, msg );
        }
    }
}

/*
 * This is here to simplify the code elsewhere.
 */
char[] utf8_to_utf8(ubyte[] s) { return cast(char[]) s; }
ubyte[] utf8_to_utf8(char[] s) { return cast(ubyte[]) s; }

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// Date/time stuff

void dosToTime(ushort dostime, ushort dosdate, out Time time)
{
    uint sec, min, hour, day, mon, year;
    sec = (dostime & 0b00000_000000_11111) * 2;
    min = (dostime & 0b00000_111111_00000) >> 5;
    hour= (dostime & 0b11111_000000_00000) >> 11;
    day = (dosdate & 0b0000000_0000_11111);
    mon = (dosdate & 0b0000000_1111_00000) >> 5;
    year=((dosdate & 0b1111111_0000_00000) >> 9) + 1980;

    // This code sucks.
    scope cal = new Gregorian;
    time = Time.epoch
        + TimeSpan.days(cal.getDaysInYear(year, 0))
        + TimeSpan.days(cal.getDaysInMonth(year, mon, 0))
        + TimeSpan.days(day)
        + TimeSpan.hours(hour)
        + TimeSpan.minutes(min)
        + TimeSpan.seconds(sec);
}

void timeToDos(Time time, out ushort dostime, out ushort dosdate)
{
    // Treat Time.min specially
    if( time == Time.min )
        time = WallClock.now;

    // *muttering angrily*
    scope cal = new Gregorian;
    
    if( cal.getYear(time) < 1980 )
        ZipException.tooold;

    auto span = time.span;
    dostime =
        (span.seconds / 2)
      | (span.minutes << 5)
      | (span.hours   << 11);

    dosdate =
        (cal.getDayOfMonth(time))
      | (cal.getMonth(time) << 5)
      |((cal.getYear(time) - 1980) << 9);
}

// ************************************************************************** //
// ************************************************************************** //
// ************************************************************************** //

// Dependencies
private:

import tango.io.Conduit : Conduit;

/*******************************************************************************

    copyright:  Copyright © 2007 Daniel Keep.  All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Prerelease

    author:     Daniel Keep

*******************************************************************************/

//module tangox.io.stream.CounterStream;

//import tango.io.Conduit : Conduit;
//import tango.io.model.IConduit : IConduit, InputStream, OutputStream;

/**
 * The counter stream classes are used to keep track of how many bytes flow
 * through a stream.
 *
 * To use them, simply wrap it around an existing stream.  The number of bytes
 * that have flowed through the wrapped stream may be accessed using the
 * count member.
 */
class CounterInput : InputStream
{
    ///
    this(InputStream input)
    in
    {
        assert( input !is null );
    }
    body
    {
        this.input = input;
    }

    override IConduit conduit()
    {
        return input.conduit;
    }

    override void close()
    {
        input.close();
        input = null;
    }

    override uint read(void[] dst)
    {
        auto read = input.read(dst);
        if( read != IConduit.Eof )
            _count += read;
        return read;
    }

    override InputStream clear()
    {
        input.clear();
        return this;
    }

    ///
    long count() { return _count; }

private:
    InputStream input;
    long _count;
}

/// ditto
class CounterOutput : OutputStream
{
    ///
    this(OutputStream output)
    in
    {
        assert( output !is null );
    }
    body
    {
        this.output = output;
    }

    override IConduit conduit()
    {
        return output.conduit;
    }

    override void close()
    {
        output.close();
        output = null;
    }

    override uint write(void[] dst)
    {
        auto wrote = output.write(dst);
        if( wrote != IConduit.Eof )
            _count += wrote;
        return wrote;
    }

    override OutputStream copy(InputStream src)
    {
        return Conduit.transfer(src, this);
    }

    override OutputStream flush()
    {
        output.flush();
        return this;
    }

    ///
    long count() { return _count; }

private:
    OutputStream output;
    long _count;
}

/*******************************************************************************

    copyright:  Copyright © 2007 Daniel Keep.  All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Prerelease

    author:     Daniel Keep

*******************************************************************************/

//module tangox.io.stream.SliceStream;

//import tango.io.Conduit : Conduit;
//import tango.io.model.IConduit : IConduit, InputStream, OutputStream;

/**
 * This stream can be used to provide stream-based access to a subset of
 * another stream.  It is akin to slicing an array.
 *
 * This stream fully supports seeking, and as such requires that the
 * underlying stream also support seeking.
 */
class SliceSeekInputStream : InputStream, IConduit.Seek
{
    alias IConduit.Seek.Anchor Anchor;

    /**
     * Create a new slice stream from the given source, covering the content
     * starting at position begin, for length bytes.
     */
    this(InputStream source, long begin, long length)
    in
    {
        assert( source !is null );
        assert( (cast(IConduit.Seek) source) !is null );
        assert( begin >= 0 );
        assert( length >= 0 );
    }
    body
    {
        this.source = source;
        this.seeker = cast(IConduit.Seek) source;
        this.begin = begin;
        this.length = length;
    }

    override IConduit conduit()
    {
        return source.conduit;
    }

    override void close()
    {
        source = null;
        seeker = null;
    }

    override uint read(void[] dst)
    {
        // If we're at the end of the slice, return eof
        if( _position >= length )
            return IConduit.Eof;

        // Otherwise, make sure we don't try to read past the end of the slice
        if( _position+dst.length > length )
            dst.length = length-_position;

        // Seek source stream to the appropriate location.
        if( seeker.seek(0, Anchor.Current) != begin+_position )
            seeker.seek(begin+_position, Anchor.Begin);

        // Do the read
        auto read = source.read(dst);
        if( read == IConduit.Eof )
            // If we got an Eof, we'll consider that a bug for the moment.
            // TODO: proper exception
            throw new Exception("unexpected end-of-stream");

        _position += read;
        return read;
    }

    override InputStream clear()
    {
        source.clear();
        return this;
    }

    override long seek(long offset, Anchor anchor = cast(Anchor)0)
    {
        switch( anchor )
        {
            case Anchor.Begin:
                _position = offset;
                break;

            case Anchor.Current:
                _position += offset;
                if( _position < 0 ) _position = 0;
                break;

            case Anchor.End:
                _position = length+offset;
                if( _position < 0 ) _position = 0;
                break;
        }

        return _position;
    }

private:
    InputStream source;
    IConduit.Seek seeker;

    long _position, begin, length;

    invariant
    {
        assert( cast(Object) source is cast(Object) seeker );
        assert( begin >= 0 );
        assert( length >= 0 );
        assert( _position >= 0 );
    }
}

/**
 * This stream can be used to provide stream-based access to a subset of
 * another stream.  It is akin to slicing an array.
 */
class SliceInputStream : InputStream
{
    /**
     * Create a new slice stream from the given source, covering the content
     * starting at the current seek position for length bytes.
     */
    this(InputStream source, long length)
    in
    {
        assert( source !is null );
        assert( length >= 0 );
    }
    body
    {
        this.source = source;
        this._length = length;
    }

    override IConduit conduit()
    {
        return source.conduit;
    }

    override void close()
    {
        source = null;
    }

    override uint read(void[] dst)
    {
        // If we're at the end of the slice, return eof
        if( _length <= 0 )
            return IConduit.Eof;

        // Otherwise, make sure we don't try to read past the end of the slice
        if( dst.length > _length )
            dst.length = _length;

        // Do the read
        auto read = source.read(dst);
        if( read == IConduit.Eof )
            // If we got an Eof, we'll consider that a bug for the moment.
            // TODO: proper exception
            throw new Exception("unexpected end-of-stream");

        _length -= read;
        return read;
    }

    override InputStream clear()
    {
        source.clear();
        return this;
    }

private:
    InputStream source;
    long _length;

    invariant
    {
        if( _length > 0 ) assert( source !is null );
    }
}

/**
 * This stream can be used to provide stream-based access to a subset of
 * another stream.  It is akin to slicing an array.
 *
 * This stream fully supports seeking, and as such requires that the
 * underlying stream also support seeking.
 */
class SliceSeekOutputStream : OutputStream, IConduit.Seek
{
    alias IConduit.Seek.Anchor Anchor;

    /**
     * Create a new slice stream from the given source, covering the content
     * starting at position begin, for length bytes.
     */
    this(OutputStream source, long begin, long length)
    in
    {
        assert( (cast(IConduit.Seek) source) !is null );
        assert( begin >= 0 );
        assert( length >= 0 );
    }
    body
    {
        this.source = source;
        this.seeker = cast(IConduit.Seek) source;
        this.begin = begin;
        this.length = length;
    }

    override IConduit conduit()
    {
        return source.conduit;
    }

    override void close()
    {
        source = null;
        seeker = null;
    }

    uint write(void[] src)
    {
        // If we're at the end of the slice, return eof
        if( _position >= length )
            return IConduit.Eof;

        // Otherwise, make sure we don't try to write past the end of the
        // slice
        if( _position+src.length > length )
            src.length = length-_position;

        // Seek source stream to the appropriate location.
        if( seeker.seek(0, Anchor.Current) != begin+_position )
            seeker.seek(begin+_position, Anchor.Begin);

        // Do the write
        auto wrote = source.write(src);
        if( wrote == IConduit.Eof )
            // If we got an Eof, we'll consider that a bug for the moment.
            // TODO: proper exception
            throw new Exception("unexpected end-of-stream");

        _position += wrote;
        return wrote;
    }

    override OutputStream copy(InputStream src)
    {
        return Conduit.transfer(src, this);
    }

    override OutputStream flush()
    {
        source.flush();
        return this;
    }

    override long seek(long offset, Anchor anchor = cast(Anchor)0)
    {
        switch( anchor )
        {
            case Anchor.Begin:
                _position = offset;
                break;

            case Anchor.Current:
                _position += offset;
                if( _position < 0 ) _position = 0;
                break;

            case Anchor.End:
                _position = length+offset;
                if( _position < 0 ) _position = 0;
                break;
        }

        return _position;
    }

private:
    OutputStream source;
    IConduit.Seek seeker;

    long _position, begin, length;

    invariant
    {
        assert( cast(Object) source is cast(Object) seeker );
        assert( begin >= 0 );
        assert( length >= 0 );
        assert( _position >= 0 );
    }
}

/*******************************************************************************

    copyright:  Copyright © 2007 Daniel Keep.  All rights reserved.

    license:    BSD style: $(LICENSE)

    version:    Prerelease

    author:     Daniel Keep

*******************************************************************************/

//module tangox.io.stream.WrapStream;

//import tango.io.Conduit : Conduit;
//import tango.io.model.IConduit : IConduit, InputStream, OutputStream;

/**
 * This stream can be used to provide access to another stream.
 * Its distinguishing feature is that users cannot close the underlying
 * stream.
 *
 * This stream fully supports seeking, and as such requires that the
 * underlying stream also support seeking.
 */
class WrapSeekInputStream : InputStream, IConduit.Seek
{
    alias IConduit.Seek.Anchor Anchor;

    /**
     * Create a new wrap stream from the given source.
     */
    this(InputStream source)
    in
    {
        assert( source !is null );
        assert( (cast(IConduit.Seek) source) !is null );
    }
    body
    {
        this.source = source;
        this.seeker = cast(IConduit.Seek) source;
        this._position = seeker.seek(0, Anchor.Current);
    }

    /// ditto
    this(InputStream source, long position)
    in
    {
        assert( position >= 0 );
    }
    body
    {
        this(source);
        this._position = position;
    }

    override IConduit conduit()
    {
        return source.conduit;
    }

    override void close()
    {
        source = null;
        seeker = null;
    }

    override uint read(void[] dst)
    {
        if( seeker.seek(0, Anchor.Current) != _position )
            seeker.seek(_position, Anchor.Begin);

        auto read = source.read(dst);
        if( read != IConduit.Eof )
            _position += read;

        return read;
    }

    override InputStream clear()
    {
        source.clear();
        return this;
    }

    override long seek(long offset, Anchor anchor = cast(Anchor)0)
    {
        seeker.seek(_position, Anchor.Begin);
        return (_position = seeker.seek(offset, anchor));
    }

private:
    InputStream source;
    IConduit.Seek seeker;
    long _position;

    invariant
    {
        assert( cast(Object) source is cast(Object) seeker );
        assert( _position >= 0 );
    }
}

/**
 * This stream can be used to provide access to another stream.
 * Its distinguishing feature is that the users cannot close the underlying
 * stream.
 *
 * This stream fully supports seeking, and as such requires that the
 * underlying stream also support seeking.
 */
class WrapSeekOutputStream : OutputStream, IConduit.Seek
{
    alias IConduit.Seek.Anchor Anchor;

    /**
     * Create a new wrap stream from the given source.
     */
    this(OutputStream source)
    in
    {
        assert( (cast(IConduit.Seek) source) !is null );
    }
    body
    {
        this.source = source;
        this.seeker = cast(IConduit.Seek) source;
        this._position = seeker.seek(0, Anchor.Current);
    }

    /// ditto
    this(OutputStream source, long position)
    in
    {
        assert( position >= 0 );
    }
    body
    {
        this(source);
        this._position = position;
    }

    override IConduit conduit()
    {
        return source.conduit;
    }

    override void close()
    {
        source = null;
        seeker = null;
    }

    uint write(void[] src)
    {
        if( seeker.seek(0, Anchor.Current) != _position )
            seeker.seek(_position, Anchor.Begin);

        auto wrote = source.write(src);
        if( wrote != IConduit.Eof )
            _position += wrote;
        return wrote;
    }

    override OutputStream copy(InputStream src)
    {
        return Conduit.transfer(src, this);
    }

    override OutputStream flush()
    {
        source.flush();
        return this;
    }

    override long seek(long offset, Anchor anchor = cast(Anchor)0)
    {
        seeker.seek(_position, Anchor.Begin);
        return (_position = seeker.seek(offset, anchor));
    }

private:
    OutputStream source;
    IConduit.Seek seeker;
    long _position;

    invariant
    {
        assert( cast(Object) source is cast(Object) seeker );
        assert( _position >= 0 );
    }
}

