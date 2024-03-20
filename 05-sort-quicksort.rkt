#lang dssl2

import cons
import 'sort-utils.rkt'

# : List[Number] -> List[Number]
def list_quick_sort_first_pivot(lst):
    if lst is None or lst.next is None: return lst
    let pivot = lst.data # first element
    let below = list_quick_sort_first_pivot(filter(lambda x: x <  pivot, lst.next))
    let above = list_quick_sort_first_pivot(filter(lambda x: x >= pivot, lst.next))
    return append(below, cons(pivot, above))

def filter(f, lst):
    if lst is None: return None
    if f(lst.data): return cons(lst.data, filter(f, lst.next))
    else: filter(f, lst.next)

def append(lst1, lst2):
    if lst1 is None: return lst2
    if lst2 is None: return lst1
    return cons(lst1.data, append(lst1.next, lst2))

# test 'property testing list_quick_sort_first_pivot':
#     assert test_sorted(100, list_quick_sort_first_pivot) == True

# : List[Number] -> List[Number]
def list_quick_sort_random_pivot(lst):
    if lst is None or lst.next is None: return lst
    let pivot_index = random(Cons.len(lst))
    let pivot = list_nth(lst, pivot_index)
    lst = list_remove_nth(lst, pivot_index)
    let below = list_quick_sort_random_pivot(filter(lambda x: x <  pivot, lst))
    let above = list_quick_sort_random_pivot(filter(lambda x: x >= pivot, lst))
    return append(below, cons(pivot, above))

def list_nth(lst, n):
    for i in range(n):
        if lst is None: error('list_nth: out of bounds')
        lst = lst.next
    return lst.data

def list_remove_nth(lst, n):
    if lst is None: error('list_remove_nth: removing from an empty list')
    if lst.next is None: return None
    let prev = None
    for i in range(n-1):
        if lst is None: error('list_remove_nth: out of bounds')
        prev = lst
        lst = lst.next
    if lst.next is None: error('list_remove_nth: out of bounds')
    lst.next = lst.next.next

# test 'property testing list_quick_sort_random_pivot':
#     assert test_sorted(100, list_quick_sort_random_pivot) == True

def in_place_quick_sort (v):
    def helper (lo, hi):
        # print('helper: %d %d %d\n', lo, hi, v)
        if hi-lo == 0 or hi-lo == -1: # length 1 or 0
            return
        let pivot = partition(v, lo, hi)
        # pivot already in the right place
        helper(lo, pivot-1)
        helper(pivot+1, hi)
    helper(0, v.len()-1)

def partition(v, lo, hi):
    let pivot = v[lo] # first element
    # print('  pivot: %d\n', pivot)
    let i = hi+1 # temporary pivot index
    for j in range(hi, lo, -1): # starts at index hi, inclusively
        # print('  i=%d j=%d\n', i, j)
        if v[j] >= pivot:
            i = i-1
            swap(v, i, j)
            # print('    swap i=%d, j=%d  %d\n', i, j, v)
    # move pivot to the right place
    i = i-1
    swap(v, i, lo)
    # print('  pivot goes to %d\n', i)
    return i

def swap(v, i, j):
    let tmp = v[i]
    v[i] = v[j]
    v[j] = tmp

def in_place_quick_sort_adapter(l):
    let v = Cons.to_vec(l)
    in_place_quick_sort(v)
    return Cons.from_vec(v)

# test 'property testing in_place_quick_sort':
#     assert test_sorted(100, in_place_quick_sort_adapter) == True

def in_place_quick_sort_random_pivot(v):
    def helper (lo, hi):
        if hi-lo == 0 or hi-lo == -1: # length 1 or 0
            return
        let pivot = partition_random_pivot(v, lo, hi) # only line that changed
        # pivot already in the right place
        helper(lo, pivot-1)
        helper(pivot+1, hi)
    helper(0, v.len()-1)

# modified lomuto partition scheme, with random element as pivot
def partition_random_pivot(v, lo, hi):
    let pivot_index = random(lo, hi+1)
    let tmp = v[pivot_index] # swap with first element
    v[pivot_index] = v[lo]
    v[lo] = tmp
    # rest is unchanged
    let pivot = v[lo] # first element
    let i = hi+1 # temporary pivot index
    for j in range(hi, lo, -1): # goes to index hi, inclusively
        if v[j] >= pivot:
            i = i-1
            swap(v, i, j)
    # move pivot to the right place
    i = i-1
    swap(v, i, lo)
    return i

def in_place_quick_sort_random_pivot_adapter(l):
    let v = Cons.to_vec(l)
    in_place_quick_sort_random_pivot(v)
    return Cons.from_vec(v)

# test 'property testing in_place_quick_sort_random_pivot':
#     assert test_sorted(100, in_place_quick_sort_random_pivot_adapter) == True
