#lang dssl2

struct posn:
    let x
    let y
    

test 'test':
    let p = posn(3, 4)
    assert p.x == 3
    p.x = 6
    assert p.x == 6