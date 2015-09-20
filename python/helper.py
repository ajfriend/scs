from glob import glob

def glober(root, names):
    """ For each relative path name in `names`, add the root directory and
    find files matching the resulting glob pattern.
    """
    out = []
    for name in names:
        out += glob(root + name)
    return out
