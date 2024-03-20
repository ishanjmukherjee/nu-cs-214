#lang dssl2

let a = 3 + 5
a = 3

"hello".len()

def do_something():
    println("condition is right")
    
def do_something_else():
    println("condition is wrong")
    
if 3 > 5:
    do_something()
else:
    do_something_else()
    
def fact(n):
    if (n == 0):
        return 1
    return n * fact(n-1)

#fact(3)

test 'Fact tests':
    assert fact(3) == 6
    println('checking this')
    assert fact(4) == -1





