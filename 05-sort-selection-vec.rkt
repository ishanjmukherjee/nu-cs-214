#lang dssl2

import 'sort-utils.rkt'

def selection_sort_vec(unsorted):
    for i in range(unsorted.len()-1):
        let max = find_largest_vec(unsorted, i)
        swap(unsorted, i, max) 

def find_largest_vec(vec, idx):
    let max = idx
    for i in range(idx+1, vec.len()):
        if vec[i] > vec[max]:
            max = i
    return max

def swap(vec, idx1, idx2):
    let temp = vec[idx1]
    vec[idx1] = vec[idx2]
    vec[idx2] = temp
   
test 'simple test':
    let vec = [6, 12, 44, 0, 1]
    selection_sort_vec(vec)

    assert vec[0] == 44
    assert vec[1] == 12
    assert vec[2] == 6
    assert vec[3] == 1
    assert vec[4] == 0