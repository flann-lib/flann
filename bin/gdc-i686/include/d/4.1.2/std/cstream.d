/**
 * The std.cstream module bridges std.c.stdio (or std.stdio) and std.stream.
 * Both std.c.stdio and std.stream are publicly imported by std.cstream.
 * Authors: Ben Hinkle
 * License: Public Domain
 * Macros:
 *	WIKI=Phobos/StdCstream
 */

module std.cstream;

import std.stream;
import std.c.stdio;

/**
 * A Stream wrapper for a C file of type FILE*.
 */
class CFile : Stream {
  FILE* cfile;

  /**
   * Create the stream wrapper for the given C file.
   * Params:
   *   mode = a bitwise combination of $(B FileMode.In) for a readable file
   *          and $(B FileMode.Out) for a writeable file.
   *   seekable = indicates if the stream should be _seekable.
   */
  this(FILE* cfile, FileMode mode, bool seekable = false) {
    super();
    this.file = cfile;
    readable = cast(bool)(mode & FileMode.In);
    writeable = cast(bool)(mode & FileMode.Out);
    this.seekable = seekable;
  }

  /**
   * Closes the stream.
   */
  ~this() { close(); }

  /**
   * Property to get or set the underlying file for this stream.
   * Setting the file marks the stream as open.
   */
  FILE* file() { return cfile; }

  /**
   * Ditto
   */
  void file(FILE* cfile) {
    this.cfile = cfile; 
    isopen = true;
  }

  /**
   * Overrides of the $(B Stream) methods to call the underlying $(B FILE*)
   * C functions.
   */
  override void flush() { fflush(cfile); }

  /**
   * Ditto
   */
  override void close() { 
    if (isopen)
      fclose(cfile); 
    isopen = readable = writeable = seekable = false; 
  }

  /**
   * Ditto
   */
  override bool eof() { 
    return cast(bool)(readEOF || feof(cfile)); 
  }

  /**
   * Ditto
   */
  override char getc() { 
    return cast(char)fgetc(cfile); 
  }

  /**
   * Ditto
   */
  override char ungetc(char c) { 
    return cast(char)std.c.stdio.ungetc(c,cfile); 
  }

  /**
   * Ditto
   */
  override size_t readBlock(void* buffer, size_t size) {
    size_t n = fread(buffer,1,size,cfile);
    readEOF = cast(bool)(n == 0);
    return n;
  }

  /**
   * Ditto
   */
  override size_t writeBlock(void* buffer, size_t size) {
    return fwrite(buffer,1,size,cfile);
  }

  /**
   * Ditto
   */
  override ulong seek(long offset, SeekPos rel) {
    readEOF = false;
    if (fseek(cfile,cast(int)offset,rel) != 0)
      throw new SeekException("unable to move file pointer");
    return ftell(cfile);
  }

  /**
   * Ditto
   */
  override void writeLine(char[] s) {
    writeString(s);
    writeString("\n");
  }

  /**
   * Ditto
   */
  override void writeLineW(wchar[] s) {
    writeStringW(s);
    writeStringW("\n");
  }

  // run a few tests
  unittest {
    FILE* f = fopen("stream.txt","w");
    assert(f !is null);
    CFile file = new CFile(f,FileMode.Out);
    int i = 666;
    // should be ok to write
    assert(file.writeable);
    file.writeLine("Testing stream.d:");
    file.writeString("Hello, world!");
    file.write(i);
    // string#1 + string#2 + int should give exacly that
    version (Win32)
      assert(file.position() == 19 + 13 + 4);
    version (linux)
      assert(file.position() == 18 + 13 + 4);
    file.close();
    // no operations are allowed when file is closed
    assert(!file.readable && !file.writeable && !file.seekable);
    f = fopen("stream.txt","r");
    file = new CFile(f,FileMode.In,true);
    // should be ok to read
    assert(file.readable);
    char[] line = file.readLine();
    char[] exp = "Testing stream.d:";
    assert(line[0] == 'T');
    assert(line.length == exp.length);
    assert(!std.string.cmp(line, "Testing stream.d:"));
    // jump over "Hello, "
    file.seek(7, SeekPos.Current);
    version (Win32)
      assert(file.position() == 19 + 7);
    version (linux)
      assert(file.position() == 18 + 7);
    assert(!std.string.cmp(file.readString(6), "world!"));
    i = 0; file.read(i);
    assert(i == 666);
    // string#1 + string#2 + int should give exacly that
    version (Win32)
      assert(file.position() == 19 + 13 + 4);
    version (linux)
      assert(file.position() == 18 + 13 + 4);
    // we must be at the end of file
    file.close();
    f = fopen("stream.txt","w+");
    file = new CFile(f,FileMode.In|FileMode.Out,true);
    file.writeLine("Testing stream.d:");
    file.writeLine("Another line");
    file.writeLine("");
    file.writeLine("That was blank");
    file.position = 0;
    char[][] lines;
    foreach(char[] line; file) {
      lines ~= line.dup;
    }
    assert( lines.length == 5 );
    assert( lines[0] == "Testing stream.d:");
    assert( lines[1] == "Another line");
    assert( lines[2] == "");
    assert( lines[3] == "That was blank");
    file.position = 0;
    lines = new char[][5];
    foreach(ulong n, char[] line; file) {
      lines[cast(size_t)(n-1)] = line.dup;
    }
    assert( lines[0] == "Testing stream.d:");
    assert( lines[1] == "Another line");
    assert( lines[2] == "");
    assert( lines[3] == "That was blank");
    file.close();
    remove("stream.txt");
  }
}

/**
 * CFile wrapper of std.c.stdio.stdin (not seekable).
 */
CFile din;

/**
 * CFile wrapper of std.c.stdio.stdout (not seekable).
 */
CFile dout;

/**
 * CFile wrapper of std.c.stdio.stderr (not seekable).
 */
CFile derr;

static this() {
  // open standard I/O devices
  din = new CFile(std.c.stdio.stdin,FileMode.In);
  dout = new CFile(std.c.stdio.stdout,FileMode.Out);
  derr = new CFile(std.c.stdio.stderr,FileMode.Out);
}

