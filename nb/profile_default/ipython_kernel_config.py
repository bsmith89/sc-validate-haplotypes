c = get_config()

# On notebook startup,
c.IPKernelApp.exec_lines = [
    # Change PWD to the project root.
    """
import os as _os
_os.chdir('..')
""",
    # Add include/ dirs to the path
    """
import sys as _sys
_include_dir = 'include'
for _d in _os.listdir(_include_dir):
    _sys.path.append(_os.path.join(_include_dir, _d))
""",
]
