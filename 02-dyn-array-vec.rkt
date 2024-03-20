#lang dssl2

# Uses vectors
class DynamicArray:
    let data
    let len
    
    def __init__(self):
        self.data = []
        self.len = self.data.len()
        
    def get_ith(self, i):
        if i >= self.len:
            error('get_ith: Index out of bounds')
        return self.data[i]
        
    def append(self, value):
        # Create a temporary new array with space for one more element
        let resized_data = [None; self.len + 1]
        for i in range(self.len):
            resized_data[i] = self.data[i]
        resized_data[self.len] = value
        
        self.data = resized_data
        self.len = self.len + 1
       
test 'DynamicArray works correctly?':
    let arr = DynamicArray()
    arr.append(2)
    assert_error arr.get_ith(2)
    assert arr.get_ith(0) == 2
    arr.append(10)
    arr.append(233)
    assert arr.get_ith(2) == 233
    assert arr.get_ith(1) == 10