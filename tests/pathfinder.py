import os
from pathlib import Path
import sys

BASEPATH = Path(os.path.dirname(os.path.realpath(__file__)))
print(BASEPATH.parents[0])
