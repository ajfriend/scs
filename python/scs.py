import numpy as np
import _scs

class Workspace(object):
    def __init__(self):
        self.work = _scs.Workspace()


def scs(data, cone, **settings):
    """ This should follow the same API as the current SCS python interface.
    """
    print "Implement me!"
    return np.zeros(4)