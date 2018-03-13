#!/usr/bin/env python

"""Get all the dependencies of an RGBDS assembly file recursively."""

from __future__ import print_function
from __future__ import unicode_literals

import os
import sys

def dependencies_of(asm_file_path):
    dependencies = []
    with open(asm_file_path) as f:
        for line in f:
            dependencies += dependencies_from_line(line)
    return dependencies

def dependencies_from_line(line):
    line = line.lstrip().split(';', 1)[0]
    if not line.startswith('INC'):
        return []
    
    dependencies = []
    path = line[line.index('"') + 1:line.rindex('"')]
    dependencies.append(path)
    if line.startswith('INCLUDE'):
        dependencies += dependencies_of(path)
    
    return dependencies

def main():
    try:
        in_path = sys.argv[1]
    except IndexError:
        print("Usage: {} <path to assembly file>".format(os.path.basename(__file__)))
        exit(1)
    
    for dependency in dependencies_of(in_path):
        print(dependency)

if __name__ == '__main__':
    main()
