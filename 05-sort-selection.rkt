#lang dssl2

import cons
import 'sort-utils.rkt'

def selection_sort (unsorted):
    let sorted = None
    while unsorted is not None:
        let largest = find_largest(unsorted)
        unsorted = remove(largest, unsorted)
        sorted = cons(largest, sorted)
    return sorted

def find_largest(lst):
    if lst is None:
        error('empty list has no largest element')
    let best_so_far = lst.data
    while lst is not None:
        if lst.data > best_so_far:
            best_so_far = lst.data
        lst = lst.next
    return best_so_far

# returns a new list, but could also do an
# in-place version
def remove(elt, lst):
    if lst is None:
        error('element not found: %d', elt)
    elif lst.data == elt:
        return lst.next
    else:
        return cons(lst.data,
                    remove(elt, lst.next))

test 'property testing':
    assert test_sorted(100, selection_sort) == True
