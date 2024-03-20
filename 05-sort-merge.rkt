#lang dssl2

import cons
import 'sort-utils.rkt'

# : List[Number] -> List[Number]
def merge_sort(lst):
    if lst is None or lst.next is None: return lst
    let o = merge_sort(odds(lst))
    let e = merge_sort(evens(lst))
    return merge(o, e)

# 0th element, 2nd, 4th, etc.
def evens(lst):
    if lst is None: return None
    else: return cons(lst.data, odds(lst.next))

# 1st element, 4rd, 5th, etc.
def odds(lst):
    if lst is None: return None
    else: return evens(lst.next)

# : List[Number] List[Number] -> List[Number]
def merge(l1, l2):
    if l1 is None:
        return l2
    elif l2 is None:
        return l1
    elif l1.data < l2.data:
        return cons(l1.data, merge(l1.next, l2))
    else:
        return cons(l2.data, merge(l1, l2.next))

test 'property testing':
    assert test_sorted(100, merge_sort) == True
