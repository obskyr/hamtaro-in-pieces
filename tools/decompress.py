#!/usr/bin/env python

"""Decompress data encoded with the method used in Hamtaro: Ham-Hams Unite!"""

from __future__ import print_function
from __future__ import unicode_literals

import os
import struct
import sys

def decompress_section(f):
    data = b''
    
    chunk_start = ord(f.read(1))
    while chunk_start != 0:
        if chunk_start <= 127:
            data += f.read(chunk_start)
        elif 0xFC <= chunk_start <= 0xFE:
            data += decompress_reference_chunk(f, chunk_start, data)
        else:
            data += decompress_rle_chunk(f, chunk_start)
        
        chunk_start = ord(f.read(1))
    
    return data

def decompress_rle_chunk(f, chunk_start):
    num_bytes = (chunk_start & 0b01111100) >> 1 or 1
    run_length = ((chunk_start & 0b11) << 8) | ord(f.read(1))
    return f.read(num_bytes) * run_length

def decompress_reference_chunk(f, chunk_start, data):
    num_bytes = ((chunk_start & 0b11) << 8) | ord(f.read(1))
    start_index = struct.unpack('<H', f.read(2))[0]
    return data[start_index:start_index + num_bytes]

def main():
    try:
        in_path = sys.argv[1]
        address = int(sys.argv[2], base=0)
    except (IndexError, ValueError):
        print("Usage: {} <input file> <address> "
              "[output file]".format(os.path.basename(__file__)))
        exit(1)
    try:
        out_path = sys.argv[3]
    except IndexError:
        out_path = None
    
    with open(in_path, 'rb') as f:
        f.seek(address)
        data = decompress_section(f)
    
    if out_path:
        print("Decompressing section at "
              "${:06X} in {} to {}...".format(address, in_path, out_path))
        with open(out_path, 'wb') as f:
            f.write(data)
    else:
        try:
            sys.stdout.buffer.write(data)
        except AttributeError: # Python 2
            sys.stdout.write(data)

if __name__ == '__main__':
    main()
