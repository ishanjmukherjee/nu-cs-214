#lang dssl2

class Posn:
    let x    # fields: initialized by the constructor
    let y

    def __init__ (self, x, y): # constructor: method with a special name
        self.x = x
        self.y = y

    def get_x(self): self.x  #return is optional

    def get_y(self): self.y  


    def distance(self, other):
        let dx = self.x - other.get_x() # some other method    
        let dy = self.y - other.get_y() # fields are private to individual objects; need to use getter for `other`
        return (dx * dx + dy * dy).sqrt()


test 'Class operations':
    let p = Posn(3, 4)
    assert p.get_x() == 3
    assert p.get_y() == 4
    assert_error p.x

    let q = Posn(0, 0)
    assert p.distance(q) == 5