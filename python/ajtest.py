import cyscs

import numpy as np

a = np.random.rand(4)
b = np.array([1,2,3,4])

cyscs.hello()

cyscs.howdy(a, b)
cyscs.howdy(a, b[2:])


b = np.array(b, dtype=np.int32)

try:
    cyscs.howdy(a, b[2:])
except Exception as e:
    print 'We got the error we were expecting!'
    print "should be something like: Buffer dtype mismatch, expected 'scs_int' but got 'int'"
    print e

b = np.array(b, dtype=np.int16)

try:
    cyscs.howdy(a, b[2:])
except Exception as e:
    print "should be something like: Buffer dtype mismatch, expected 'scs_int' but got 'short'"
    print e
