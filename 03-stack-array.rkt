#lang dssl2

interface STACK[T]:
    def push(self, element: T ) -> NoneC 
    def pop(self) -> T
    def empty?(self ) -> bool?
    
class StackArray[T] (STACK):
    let data: VecC[OrC(T, NoneC)]
    let length: int?

    def __init__(self, cap):
        self.data = [None; cap]
        self.length = 0
        
    def cap(self):
        return self.data.len()
        
    def len(self):
        return self.length
        
    def push(self, element: T) -> NoneC:
        if self.length == self.data.len():
            error('StackArray.push: full')
        self.data[self.length] = element
        self.length = self.length + 1
        
    def pop(self) -> T:
        if self.empty?():
            error('StackArray.pop: empty')
        self.length = self.length - 1
        return self.data[self.length] # returns automatically
        
    def empty?(self ) -> bool?:
        return self.len() == 0

# Test cases
test 'generic stack integer test':
    let s = StackArray[int](5)
    assert_error s.pop()
    s.push(4)
    assert(not s.empty?())
    assert(s.pop() == 4)
    assert(s.empty?())
    
#Testing with more complex data
struct browser_click:
    let url
    let timestamp
    
test 'generic stack browser_click test':
    let s = StackArray[browser_click?](5)
    assert_error s.pop()
    s.push(browser_click('www.google.com', '3/31/2023'))
    assert(not s.empty?())
    assert(s.pop() == 
        browser_click('www.google.com', '3/31/2023'))
    assert(s.empty?())