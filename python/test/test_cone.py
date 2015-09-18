
def test_import():
    import scs

def test_cone():
    from scs import show_cone
    d = dict(f=1, l=20, ep=4, ed=7, q=[3,4,9,10], s=[0,1,4], p=[.1, -.7])
    show_cone(d)

def test_version():
    import scs
    import pkg_resources

    # pkg_resources.require("scs")[0].version set in setup.py
    # scs.version set in constants.h
    assert scs.version() == pkg_resources.require("scs")[0].version
