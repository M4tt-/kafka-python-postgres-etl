# -*- coding: utf-8 -*-
"""
:author: runyon

Description: Let Python's sys.path variable be sufficiently populated to run
             all code in this repository, regardless of where the user
             houses the code on their local machine.

             This script should be executed prior to other code in this repo.
"""

# %% IMPORTS

import os
import sys

# %% CONSTANTS

VERBOSITY = False
BASEPATH = os.path.dirname(os.path.realpath(__file__))

# %% SCRIPT

# Get all sub directories, excluding hidden ones
sub_dirs = []
for root, dirs, files in os.walk(BASEPATH):

    # Declare top directory
    top = root[len(BASEPATH) + 1:]

    # Skip all hidden directories
    if top.startswith('.') or top.startswith('_'):
        continue

    # Declare top level folder of subdirectory
    root_path, top_folder = os.path.split(root)

    if not top_folder.startswith('.') and not top_folder.startswith('_'):
        sub_dirs.append(root)

if VERBOSITY:
    print("\nFolders found:\n")

# Add sub directories to the system path
for path in sub_dirs:
    if VERBOSITY:
        print(os.path.join(BASEPATH, path))
    sys.path.append(os.path.join(BASEPATH, path))
