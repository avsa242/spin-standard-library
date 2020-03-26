{
    --------------------------------------------
    Filename: filesystem.block.fat.spin
    Author: Tomas Rokicki, Jonathan Dummer
    Modified by: Jesse Burt
    Description: FAT16/32 filesystem driver
    Copyright (c) 2020
    Started Dec 28, 2006
    Updated Mar 25, 2020
    See end of file for terms of use.
    --------------------------------------------
}
'    NOTE: This is a modified version of fsrw.spin. The original header
'        is preserved below:

{{
'   fsrw 2.6 Copyright 2009  Tomas Rokicki and Jonathan Dummer
'
'   See end of file for terms of use.
'
'   This object provides FAT16/32 file read/write access on a block device.
'   Only one file open at a time.  Open modes are 'r' (read), 'a' (append),
'   'w' (write), and 'd' (delete).  Only the root directory is supported.
'   No long filenames are supported.  We also support traversing the
'   root directory.
'
'   In general, negative return values are errors; positive return
'   values are success.  Other than -1 on popen when the file does not
'   exist, all negative return values will be "aborted" rather than
'   returned.
'
'   Changes:
'       v1.1    28 December 2006    Fixed offset for ctime
'       v1.2    29 December 2006    Made default block driver be fast one
'       v1.3    6 January 2007      Added some docs, and a faster asm
'       v1.4    4 February 2007     Rearranged vars to save memory;
'                                   eliminated need for adjacent pins;
'                                   reduced idle current consumption; added
'                                   sample code with abort code data
'       v1.5    7 April 2007        Fixed problem when directory is larger
'                                       than a cluster.
'       v1.6    23 September 2008   Fixed a bug found when mixing pputc
'                                   with pwrite.  Also made the assembly
'                                       routines a bit more cautious.
'       v2.1    12 July 2009        FAT32, SDHC, multiblock, bug fixes
'       v2.4    26 September 2009   Added seek support.  Added clustersize.
'       v2.4a   6 October 2009      modified setdate to explicitly set year/month/etc.
'       v2.5    13 November 2009    fixed a bug on releasing the pins, added a "release" pass through function
'       v2.6    11 December 2009    faster transfer hub <=> cog, safe_spi.spin uses 1/2 speed reads, is default
}}
'
'   Constants describing FAT volumes.
'
CON

    SECTORSIZE  = 512
    SECTORSHIFT = 9
    DIRSIZE     = 32
    DIRSHIFT    = 5

OBJ

    sdspi: "memory.flash.sd.spi"                            ' Block-level access driver

VAR
'
'
'   Variables concerning the open file.
'
    long _fclust ' the current cluster number
    long _filesize ' the total current size of the file
    long _floc ' the seek position of the file
    long _frem ' how many bytes remain in this cluster from this file
    long _bufat ' where in the buffer our current character is
    long _bufend ' the last valid character (read) or free position (write)
    long _direntry ' the byte address of the directory entry (if open for write)
    long _writelink ' the byte offset of the disk location to store a new cluster
    long _fatptr ' the byte address of the most recently written fat entry
    long _firstcluster ' the first cluster of this file
    '
'   Variables used when mounting to describe the FAT layout of the card
'   (moved to the end of the file in the Spin version).
'
'
'   Variables controlling the caching.
'
'
'  Buffering:  two sector buffers.  These two buffers must be longword
'  aligned!  To ensure this, make sure they are the first byte variables
'  defined in this object.
'
    byte _buf[SECTORSIZE] ' main data buffer

PUB Mount(basepin) | start, sectorspercluster, reserved, rootentries, sectors
'   For compatibility, a single pin.
    return MountExplicit(basepin, basepin+1, basepin+2, basepin+3)

PUB MountExplicit(DO, CLK, DI, CS) | start, sectorspercluster, reserved, rootentries, sectors
'   Mount a volume.  The address passed in is passed along to the block
'   layer; see the currently used block layer for documentation.  If the
'   volume mounts, a 0 is returned, else abort is called.
    if (pdate == 0)
        pdate := constant(((2009-1980) << 25) + (1 << 21) + (27 << 16) + (7 << 11))
    unmount
    sdspi.start_explicit(DO, CLK, DI, CS)
    lastread := -1
    dirty := 0
    sdspi.readblock(0, @_buf)
    if (getfstype > 0)
        start := 0
    else
        start := brlong(@_buf+$1c6)
        sdspi.readblock(start, @_buf)
    filesystem := getfstype
    if (filesystem == 0)
        abort(-20) ' not a fat16 or fat32 volume
    if (brword(@_buf+$0b) <> SECTORSIZE)
        abort(-21) ' bad bytes per sector
    sectorspercluster := _buf[$0d]
    if (sectorspercluster & (sectorspercluster - 1))
        abort(-22) ' bad sectors per cluster
    clustershift := 0
    repeat while (sectorspercluster > 1)
        clustershift++
        sectorspercluster >>= 1
    sectorspercluster := 1 << clustershift
    clustersize := SECTORSIZE << clustershift
    reserved := brword(@_buf+$0e)
    if (_buf[$10] <> 2)
        abort(-23) ' not two FATs
    sectors := brword(@_buf+$13)
    if (sectors == 0)
        sectors := brlong(@_buf+$20)
    fat1 := start + reserved
    if (filesystem == 2)
        rootentries := 16 << clustershift
        sectorsperfat := brlong(@_buf+$24)
        dataregion := (fat1 + 2 * sectorsperfat) - 2 * sectorspercluster
        rootdir := (dataregion + (brword(@_buf+$2c) << clustershift)) << SECTORSHIFT
        rootdirend := rootdir + (rootentries << DIRSHIFT)
        endofchain := $ffffff0
    else
        rootentries := brword(@_buf+$11)
        sectorsperfat := brword(@_buf+$16)
        rootdir := (fat1 + 2 * sectorsperfat) << SECTORSHIFT
        rootdirend := rootdir + (rootentries << DIRSHIFT)
        dataregion := 1 + ((rootdirend - 1) >> SECTORSHIFT) - 2 * sectorspercluster
        endofchain := $fff0
    if (brword(@_buf+$1fe) <> $aa55)
        abort(-24) ' bad FAT signature
    totclusters := ((sectors - dataregion + start) >> clustershift)

PUB Unmount                                                                                                                  

    result := PClose
    sdspi.Stop

PUB FileSize

    return _filesize

PUB GetClusterCount

    return totclusters

PUB GetClusterSize

    return clustersize

PUB NextFile(fbuf) | i, t, at, lns
'   Find the next file in the root directory and extract its
'   (8.3) name into fbuf.  Fbuf must be sized to hold at least
'   13 characters (8 + 1 + 3 + 1).  If there is no next file,
'   -1 will be returned.  If there is, 0 will be returned.
    repeat
        if (_bufat => _bufend)
            t := pfillbuf
            if (t < 0)
                return t
            if (((_floc >> SECTORSHIFT) & ((1 << clustershift) - 1)) == 0)
                _fclust++
        at := @_buf + _bufat
        if (byte[at] == 0)
            return -1
        _bufat += DIRSIZE
        if (byte[at] <> $e5 and (byte[at][$0b] & $18) == 0)
            lns := fbuf
            repeat i from 0 to 10
                byte[fbuf] := byte[at][i]
                fbuf++
                if (byte[at][i] <> " ")
                    lns := fbuf
                if (i == 7 or i == 10)
                    fbuf := lns
                    if (i == 7)
                        byte[fbuf] := "."
                        fbuf++
            byte[fbuf] := 0
            return 0

PUB OpenDir | off
'   Close the currently open file, and set up the read buffer for
'   calls to nextfile.
    pclose
    off := rootdir - (dataregion << SECTORSHIFT)
    _fclust := off >> (clustershift + SECTORSHIFT)
    _floc := off - (_fclust << (clustershift + SECTORSHIFT))
    _frem := rootdirend - rootdir
    _filesize := _floc + _frem
    return 0

PUB PClose : r
'   Flush and close the currently open file if any.  Also reset the
'   pointers to valid values.  If there is no error, 0 will be returned.
    if (_direntry)
        r := pflush
    _bufat := 0
    _bufend := 0
    _filesize := 0
    _floc := 0
    _frem := 0
    _writelink := 0
    _direntry := 0
    _fclust := 0
    _firstcluster := 0
    sdspi.release

PUB PFlush
'   Call flush with the current data buffer location, and the flush
'   metadata flag set.
    return pflushbuf(_bufat, 1)

PUB PGetC | t
'   Read and return a single character.  If the end of file is
'   reached, -1 will be returned.  If an error occurs, a negative
'   number will be returned.
    if (_bufat => _bufend)
        t := pfillbuf
        if (t =< 0)
            return -1
    return (_buf[_bufat++])

PUB POpen(s, mode) : r | i, sentinel, dirptr, freeentry
'   Close any currently open file, and open a new one with the given
'   file name and mode.  Mode can be "r" "w" "a" or "d" (delete).
'   If the file is opened successfully, 0 will be returned.  If the
'   file did not exist, and the mode was not "w" or "a", -1 will be
'   returned.  Otherwise abort will be called with a negative error
'   code.
    pclose
    i := 0
    repeat while (i<8 and byte[s] and byte[s] <> ".")
        padname[i++] := uc(byte[s++])
    repeat while (i<8)
        padname[i++] := " "
    repeat while (byte[s] and byte[s] <> ".")
        s++
    if (byte[s] == ".")
        s++
    repeat while (i<11 and byte[s])
        padname[i++] := uc(byte[s++])
    repeat while (i < 11)
        padname[i++] := " "
    sentinel := 0
    freeentry := 0
    repeat dirptr from rootdir to rootdirend - DIRSIZE step DIRSIZE
        s := readbytec(dirptr)
        if (freeentry == 0 and (byte[s] == 0 or byte[s] == $e5))
            freeentry := dirptr
        if (byte[s] == 0)
            sentinel := dirptr
            quit
        repeat i from 0 to 10
            if (padname[i] <> byte[s][i])
                quit
        if (i == 11 and 0 == (byte[s][$0b] & $18)) ' this always returns
            _fclust := brword(s+$1a)
            if (filesystem == 2)
                _fclust += brword(s+$14) << 16
            _firstcluster := _fclust
            _filesize := brlong(s+$1c)
            if (mode == "r")
                _frem := (clustersize) <# (_filesize)
                return 0
            if (byte[s][11] & $d9)
                abort(-6) ' no permission to write
            if (mode == "d")
                brwword(s, $e5)
                if (_fclust)
                    freeclusters(_fclust)
                flushifdirty
                return 0
            if (mode == "w")
                brwword(s+$1a, 0)
                brwword(s+$14, 0)
                brwlong(s+$1c, 0)
                _writelink := 0
                _direntry := dirptr
                if (_fclust)
                    freeclusters(_fclust)
                _bufend := SECTORSIZE
                _fclust := 0
                _filesize := 0
                _frem := 0
                return 0
            elseif (mode == "a")
    ' this code will eventually be moved to seek
                _frem := _filesize
                freeentry := clustersize
                if (_fclust => endofchain)
                    _fclust := 0
                repeat while (_frem > freeentry)
                    if (_fclust < 2)
                        abort(-7) ' eof repeat while following chain
                    _fclust := nextcluster
                    _frem -= freeentry
                _floc := _filesize & constant(!(SECTORSIZE - 1))
                _bufend := SECTORSIZE
                _bufat := _frem & constant(SECTORSIZE - 1)
                _writelink := 0
                _direntry := dirptr
                if (_bufat)
                    sdspi.readblock(datablock, @_buf)
                    _frem := freeentry - (_floc & (freeentry - 1))
                else
                    if (_fclust < 2 or _frem == freeentry)
                        _frem := 0
                    else
                        _frem := freeentry - (_floc & (freeentry - 1))
                if (_fclust => 2)
                    followchain
                return 0
            else
                abort(-3) ' bad argument
    if (mode <> "w" and mode <> "a")
        return -1 ' not found
    _direntry := freeentry
    if (_direntry == 0)
        abort(-2) ' no empty directory entry
    ' write (or new append): create valid directory entry
    s := readbytec(_direntry)
    bytefill(s, 0, DIRSIZE)
    bytemove(s, @padname, 11)
    brwword(s+$1a, 0)
    brwword(s+$14, 0)
    i := pdate
    brwlong(s+$e, i) ' write create time and date
    brwlong(s+$16, i) ' write last modified date and time
    if (_direntry == sentinel and _direntry + DIRSIZE < rootdirend)
        brwword(readbytec(_direntry+DIRSIZE), 0)
    flushifdirty
    _writelink := 0
    _fclust := 0
    _bufend := SECTORSIZE

PUB PPutc(c)
'   Write a single character into the file open for write.  Returns
'   0 if successful, or a negative number if some error occurred.
    if (_bufat == SECTORSIZE)
        if (pflushbuf(SECTORSIZE, 0) < 0)
            return -1
    _buf[_bufat++] := c

PUB PPuts(b)
'   Write a null-terminated string to the file.
    return pwrite(b, strsize(b))

PUB PRead(ubuf, count) : r | t
'   Read count bytes into the buffer ubuf.  Returns the number of bytes
'   successfully read, or a negative number if there is an error.
'   The buffer may be as large as you want.
    repeat while (count > 0)
        if (_bufat => _bufend)
            t := pfillbuf
            if (t =< 0)
                if (r > 0)
    ' parens below prevent this from being optimized out
                    return (r)
                return t
        t := (_bufend - _bufat) <# (count)
        if ((t | (ubuf) | _bufat) & 3)
            bytemove(ubuf, @_buf+_bufat, t)
        else
            longmove(ubuf, @_buf+_bufat, t>>2)
        _bufat += t
        r += t
        ubuf += t
        count -= t

PUB PWrite(ubuf, count) : r | t
'   Write count bytes from the buffer ubuf.  Returns the number of bytes
'   successfully written, or a negative number if there is an error.
'   The buffer may be as large as you want.
    repeat while (count > 0)
        if (_bufat => _bufend)
            pflushbuf(_bufat, 0)
        t := (_bufend - _bufat) <# (count)
        if ((t | (ubuf) | _bufat) & 3)
            bytemove(@_buf+_bufat, ubuf, t)
        else
            longmove(@_buf+_bufat, ubuf, t>>2)
        r += t
        _bufat += t
        ubuf += t
        count -= t

PUB Release
'   This is just a pass-through function to allow the block layer
'   to tristate the I/O pins to the card.
    sdspi.release

PUB Seek(pos) | delta
'   Seek.  Right now will only seek within the current cluster.
'   Added for PrEdit so he can debug; do not use with files larger
'   than one cluster (and make that cluster size 32K please.)
'
'   Returns -1 on failure.  Make sure to check this return code!
'
'   We only support reads right now (but writes won't be too hard to
'   add).
    if (_direntry or pos < 0 or pos > _filesize)
        return -1
    delta := (_floc - _bufend) & - clustersize
    if (pos < delta)
        _fclust := _firstcluster
        _frem := (clustersize) <# (_filesize)
        _floc := 0
        _bufat := 0
        _bufend := 0
        delta := 0
    repeat while (pos => delta + clustersize)
        _fclust := nextcluster
        _floc += clustersize
        delta += clustersize
        _frem := (clustersize) <# (_filesize - _floc)
        _bufat := 0
        _bufend := 0
    if (_bufend == 0 or pos < _floc - _bufend or pos => _floc - _bufend + SECTORSIZE)
    ' must change buffer
        delta := _floc + _frem
        _floc := pos & - SECTORSIZE
        _frem := delta - _floc
        pfillbuf
    _bufat := pos & (SECTORSIZE - 1)
    return 0

PUB SetDate(year, month, day, hour, minute, second)
'   Set the current date and time, as a long, in the format
'   required by FAT16.  Various limits are not checked.
    pdate := ((year-1980) << 25) + (month << 21) + (day << 16)
    pdate += (hour << 11) + (minute << 5) + (second >> 1)

PUB Tell

    return _floc + _bufat - _bufend

PRI WriteBlock2(n, b)
'   On metadata writes, if we are updating the FAT region, also update
'   the second FAT region.
    sdspi.writeblock(n, b)
    if (n => fat1)
        if (n < fat1 + sectorsperfat)
            sdspi.writeblock(n+sectorsperfat, b)

PRI FlushIfDirty
'   If the metadata block is dirty, write it out.
    if (dirty)
        writeblock2(lastread, @buf2)
        dirty := 0

PRI ReadBlockC(n)
'   Read a block into the metadata buffer, if that block is not already
'   there.
    if (n <> lastread)
        flushifdirty
        sdspi.readblock(n, @buf2)
        lastread := n

PRI BRWord(b)
'   Read a byte-reversed word from a (possibly odd) address.
    return (byte[b]) + ((byte[b][1]) << 8)

PRI BRLong(b)
'   Read a byte-reversed long from a (possibly odd) address.
    return brword(b) + (brword(b+2) << 16)

PRI BRClust(b)
'   Read a cluster entry.
    if (filesystem == 1)
        return brword(b)
    else
        return brlong(b)

PRI BRWWord(w, v)
'   Write a byte-reversed word to a (possibly odd) address, and
'   mark the metadata buffer as dirty.
    byte[w++] := v
    byte[w] := v >> 8
    dirty := 1

PRI BRWLong(w, v)
'   Write a byte-reversed long to a (possibly odd) address, and
'   mark the metadata buffer as dirty.
    brwword(w, v)
    brwword(w+2, v >> 16)

PRI BRWClust(w, v)
'   Write a cluster entry.
    if (filesystem == 1)
        brwword(w, v)
    else
        brwlong(w, v)

PRI GetFSType : r

    if (brlong(@_buf+$36) == constant("F" + ("A" << 8) + ("T" << 16) + ("1" << 24)) and _buf[$3a]=="6")
        return 1
    if (brlong(@_buf+$52) == constant("F" + ("A" << 8) + ("T" << 16) + ("3" << 24)) and _buf[$56]=="2")
        return 2

PRI ReadByteC(byteloc)
'   Read a byte address from the disk through the metadata buffer and
'   return a pointer to that location.
    readblockc(byteloc >> SECTORSHIFT)
    return @buf2 + (byteloc & constant(SECTORSIZE - 1))

PRI ReadFAT(clust)
'   Read a fat location and return a pointer to the location of that
'   entry.
    _fatptr := (fat1 << SECTORSHIFT) + (clust << filesystem)
    return readbytec(_fatptr)

PRI FollowChain : r
'   Follow the fat chain and update the _writelink.
    r := brclust(readfat(_fclust))
    _writelink := _fatptr

PRI NextCluster : r
'   Read the next cluster and return it.  Set up _writelink to
'   point to the cluster we just read, for later updating.  If the
'   cluster number is bad, return a negative number.
    r := followchain
    if (r < 2 or r => totclusters)
        abort(-9) ' bad cluster value

PRI FreeClusters(clust) | bp
'   Free an entire cluster chain.  Used by remove and by overwrite.
'   Assumes the pointer has already been cleared/set to end of chain.
    repeat while (clust < endofchain)
        if (clust < 2)
            abort(-26) ' bad cluster number")
        bp := readfat(clust)
        clust := brclust(bp)
        brwclust(bp, 0)
    flushifdirty

PRI DataBlock
'   Calculate the block address of the current data location.
    return (_fclust << clustershift) + dataregion + ((_floc >> SECTORSHIFT) & ((1 << clustershift) - 1))

PRI UC(c)
'   Compute the upper case version of a character.
    if ("a" =< c and c =< "z")
        return c - 32
    return c

PRI PFlushBuf(rcnt, metadata) : r | cluststart, newcluster, count, i
'   Flush the current buffer, if we are open for write.  This may
'   allocate a new cluster if needed.  If metadata is true, the
'   metadata is written through to disk including any FAT cluster
'   allocations and also the file size in the directory entry.
    if (_direntry == 0)
        abort(-27) ' not open for writing
    if (rcnt > 0) ' must *not* allocate cluster if flushing an empty buffer
        if (_frem < SECTORSIZE)
    ' find a new clustercould be anywhere!  If possible, stay on the
    ' same page used for the last cluster.
            newcluster := -1
            cluststart := _fclust & (!((SECTORSIZE >> filesystem) - 1))
            count := 2
            repeat
                readfat(cluststart)
                repeat i from 0 to SECTORSIZE - 1<<filesystem step 1<<filesystem
                    if (buf2[i] == 0)
                        if (brclust(@buf2+i) == 0)
                            newcluster := cluststart + (i >> filesystem)
                            if (newcluster => totclusters)
                                newcluster := -1
                            quit
                if (newcluster > 1)
                    brwclust(@buf2+i, endofchain+$f)
                    if (_writelink == 0)
                        brwword(readbytec(_direntry)+$1a, newcluster)
                        _writelink := (_direntry&(SECTORSIZE-filesystem))
                        brwlong(@buf2+_writelink+$1c, _floc+_bufat)
                        if (filesystem == 2)
                            brwword(@buf2+_writelink+$14, newcluster>>16)
                    else
                        brwclust(readbytec(_writelink), newcluster)
                    _writelink := _fatptr + i
                    _fclust := newcluster
                    _frem := clustersize
                    quit
                else
                    cluststart += (SECTORSIZE >> filesystem)
                    if (cluststart => totclusters)
                        cluststart := 0
                        count--
                        if (rcnt < 0)
                            rcnt := -5 ' No space left on device
                            quit
        if (_frem => SECTORSIZE)
            sdspi.writeblock(datablock, @_buf)
            if (rcnt == SECTORSIZE) ' full buffer, clear it
                _floc += rcnt
                _frem -= rcnt
                _bufat := 0
                _bufend := rcnt
    if (rcnt < 0 or metadata) ' update metadata even if error
        readblockc(_direntry >> SECTORSHIFT) ' flushes unwritten FAT too
        brwlong(@buf2+(_direntry & (SECTORSIZE-filesystem))+$1c, _floc+_bufat)
        flushifdirty
    if (rcnt < 0)
        abort(rcnt)
    return rcnt

PRI PFillBuf : r
'   Get some data into an empty buffer.  If no more data is available,
'   return -1.  Otherwise return the number of bytes read into the
'   buffer.
    if (_floc => _filesize)
        return -1
    if (_frem == 0)
        _fclust := nextcluster
        _frem := (clustersize) <# (_filesize - _floc)
    sdspi.readblock(datablock, @_buf)
    r := SECTORSIZE
    if (_floc + r => _filesize)
        r := _filesize - _floc
    _floc += r
    _frem -= r
    _bufat := 0
    _bufend := r

DAT

    filesystem      long 0 ' 0 = unmounted, 1 = fat16, 2 = fat32
    rootdir         long 0 ' the byte address of the start of the root directory
    rootdirend      long 0 ' the byte immediately following the root directory.
    dataregion      long 0 ' the start of the data region, offset by two sectors
    clustershift    long 0 ' log base 2 of blocks per cluster
    clustersize     long 0 ' total size of cluster in bytes
    fat1            long 0 ' the block address of the fat1 space
    totclusters     long 0 ' how many clusters in the volume
    sectorsperfat   long 0 ' how many sectors per fat
    endofchain      long 0 ' end of chain marker (with a 0 at the end)
    pdate           long 0 ' current date
    lastread        long 0 ' the block address of the buf2 contents
    dirty           long 0 ' nonzero if buf2 is dirty
    buf2            byte 0[SECTORSIZE]  ' main metadata buffer
    padname         byte 0[11]  ' filename buffer

{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
