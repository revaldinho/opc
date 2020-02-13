#!/usr/bin/env python

from math import pi, sin, cos, sqrt

# simplistic taylor series calculation for sin(x)
# using 16.16 fixed point arithmetic
# which is a bit limiting as it turns out because
# a taylor series of a large argument needs large factorials
# perhaps halving the input and using a double-angle formula?
#   sin(x)-2*sin(x/2)*sqrt(1-sin(x/2)**2)
# if needed, but it seems not to be
# we can range-reduce to pi/2
#
# we could even range-reduce to pi/4 for better convergence
# then do either sin or cos
# where cos needs an extra squaring and square root
# which is just two operations vs three per taylor term

def conv16(x):
  # convert a floating point value to the 16.16 approximation
  # not worrying too much about the sign bit or rounding

  if abs(x) > 2**15:
    print "overflow!"
    return 0

  return float(int(2**16 * x)) / (2**16)


def sin1(x):
  
  # our 16.16 format means we must do some range reduction
  # so we need to keep track of which quadrant we're in
  # of course we could do this much more efficiently
  # which would cost about as much as a division
  sign = 1 if x>0 else -1
  quadrant = 0
  x = abs(x)
  while x > pi/2:
    x = x - conv16(pi/2)
    quadrant = (quadrant + 1) % 4

  print "sign:", sign, " quadrant:", quadrant, " final x:", x

  if quadrant % 2 == 1:
    x = conv16(pi/2) - x

  if quadrant / 2 == 1:
    sign = -sign

  # s is sum, the running series so far
  # t is term, to be added to the sum
  # n is the number of the term (cost is three ops per term)
  # e is the exponent of x for this term, an odd number
  # p is the power, x raised to e
  # 
  s = 0
  p = x
  p2 = conv16(x*x)
  e = 1
  n = 1
  t = p
  t = conv16(t)

  while True:
    if (conv16(s) == conv16(s + t)):
      break

    s = conv16(s + t)

    e = e + 1
    t = conv16(t/e)
    e = e + 1
    t = conv16(t/e)

    t = conv16(-t*p2)

    n = n + 1

  print "number of terms:", n

  return s * sign

def test(x):
  r = sin1(x)
  print "done:", x, " our sin():", r, " actual sin():", sin(x), " error %:", abs(100-100*r/sin(x))
  print
  return

def main():
  test(0.1)
  test(0.5)
  test(-pi/4)
  test(pi/2)
  test(1.0)
  test(3.0)
  test(4.0)
  test(5.0)
  test(7.0)
  test(8.0)
  test(10.0)
  test(100)

if __name__ == "__main__":
  main()

