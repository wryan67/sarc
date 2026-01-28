Streaming Archive
-----------------
This utility is designed to backup multiple streaming inputs vi fifo named pipes.  Stdin is also allowed as an input.  As the name implies, the input is groupped together into a single output stream, which can be stored on disk or tape.  If the output is stored on a random access device, then the archive contents can be viewed without reading the entire file, but obviously, if the archive is stored on tape, then you would need to read the entire archive in order to view the contents.   

Currently, the input streams are read sequentially and stored sequentially in the output archive.  AKA, all of the input will block, except the stream that is being read.  When that stream hits EOF, then the next stream is opened and read in turn.

Input streams can be listed on the command line or read from an input file.  Since streams, especially stdin, may not have a valid filename, each stream should specifiy what the stream should be called in the archive.

## Usage

    $ sarc
    usage: sarc [-h] [-a FILE] [-l] [-x] [-t] [-f FILE] [-d] [-q] [-v] [-b] [-s SIZE] [-V]
                [manifest ...]
    
    Streaming Archiver (sarc) v1.27
    
    positional arguments:
      manifest            Manifest [name::path] or extraction targets
    
    options:
      -h, --help          show this help message and exit
      -a, --archive FILE  Archive filename (default: stdout '-')
      -l, --list          List contents of archive
      -x, --extract       Extract all or specific items
      -t, --tape          Force sequential/tape mode
      -f, --file FILE     Read manifest from file
      -d, --direct        Direct mode: use path as name
      -q, --quiet         Quiet mode (suppress progress)
      -v, --verbose       Verbose (show filenames)
      -b, --bytes         Show sizes in bytes (default: human-readable)
      -s, --size SIZE     Estimated total size (e.g. 10g, 500m)
      -V, --version       show program's version number and exit
    
    Examples:
      Archive:  sarc -a backup.bin root.img::/dev/zvol/root
      Extract:  sarc -a backup.bin -x [item ...]
      List:     sarc -a backup.bin -l

## Exampe Listing


    $ sarc -la fili.20260128.sarc
    Name                       Size      Timestamp            SHA256 Checksum
    --------------------------------------------------------------------------------------------------------------------------
    fili.20260128.conf       782.00 B    2026-01-28 02:27:50  8d2e8dac6df91f2bb7db8b62e6849a4c1124de87da2a0136d2764f7561353b7e
    efi.20260128.img.gz        6.04 KiB  2026-01-28 02:27:50  34221c963d72db806fb5cf5be692e33d9ef7a0fb684a37d83aa5faeaf79e271d
    root.20260128.img.gz      83.93 GiB  2026-01-28 02:27:50  4bb700cb4baca15df5fd0ff53b74f91ccea7a0c59733a2c36413bb3024626dbb
    tpm.20260128.img.gz        7.54 KiB  2026-01-28 02:34:57  f6d93b62c59f0e99c7bda7488404aca370e14b477e2c503690caa274b0d9e4cb


