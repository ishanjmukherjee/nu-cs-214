#lang dssl2

import plot
import sbox_hash

interface DICT[K, V]:
    def len(self) -> nat?
    def mem?(self, key: K) -> bool?
    def get(self, key: K) -> V
    def put(self, key: K, value: V) -> NoneC

######################################################################
###
### Open-addressing, linear probing hash table
###
### Resolve collisions by trying the next bucket.
###

let _FILL_FACTOR = 0.75

struct _entry:
    let key
    let value

class HashTable[K, V] (DICT):
    let _hash
    let _size
    let _data

    def __init__(self, nbuckets: nat?, hash: FunC[AnyC, nat?]):
        self._hash = hash
        self._size = 0
        self._data = [ None; max(1, nbuckets) ]

    def len(self):
        return self._size

    def _initial_bucket_index(self, key: K) -> nat?:
        return self._hash(key) % self._data.len()

    def _find_bucket(self, key: K) -> OrC(nat?, False):
        let start = self._initial_bucket_index(key)
        let n_buckets = self._data.len()
        for offset in range(n_buckets):
            let index = (start + offset) % n_buckets
            let bucket = self._data[index]
            if bucket == None or key == bucket.key:
                return index
        return False

    def mem?(self, key: K) -> bool?:
        let bucket_index = self._find_bucket(key)
        return int?(bucket_index) and _entry?(self._data[bucket_index])

    def get(self, key: K) -> V:
        let bucket_index = self._find_bucket(key)
        if int?(bucket_index):
            let bucket = self._data[bucket_index]
            if _entry?(bucket):
                return bucket.value
        error('HashTable.get: key not found')

    def put(self, key: K, value: V) -> NoneC:
        self._ensure_capacity()
        self._real_put(key, value)

    def _ensure_capacity(self) -> NoneC:
        let fill_factor = (self.len() + 1) / self._data.len()
        if fill_factor > _FILL_FACTOR:
            self._double_capacity()

    def _double_capacity(self) -> NoneC:
        let old_data = self._data
        self._size = 0
        self._data = [ None; max(1, 2 * self._data.len()) ]
        for bucket in old_data:
            if _entry?(bucket):
                self._real_put(bucket.key, bucket.value)

    def _real_put(self, key: K, value: V) -> NoneC:
        let bucket_index = self._find_bucket(key)
        let bucket = self._data[bucket_index]
        if _entry?(bucket):
            bucket.value = value
        else:
            self._size = self._size + 1
            self._data[bucket_index] = _entry(key, value)

######################################################################
###
### Sorted vector dictionary
###

struct assoc:
    let key
    let value

class VectorDict (DICT):
    let _contents: VecC[assoc?]

    def __init__(self):
        self._contents = []

    def len(self):
        return self._contents.len()

    def mem?(self, k):
        if self.binary_search(k) is not False: return True
        return False

    def get(self, k):
        let idx = self.binary_search(k)
        if idx is not False:
            return self._contents[idx].value
        error('VectorDict.get: key not found')

    # returns the index (if found) or False (if not)
    def binary_search(self, key) -> OrC(nat?, False):
        let vec = self._contents
        def bin(lo, hi):
            if lo > hi:
                return False
            let mid = (lo + hi) // 2
            if vec[mid].key == key:
                return mid
            elif vec[mid].key > key:
                bin(lo, mid - 1)
            else:
                bin(mid + 1, hi)
        bin(0, vec.len() - 1)

    def put(self, k, v):
        let new_length = self.len() + 1
        let old_contents = self._contents
        self._contents = [None; new_length]
        let offset = 0
        for i in range(new_length):
            if offset == 0 and (i + 1 == new_length or \
                    old_contents[i].key > k):
                self._contents[i] = assoc(k, v)
                offset = 1
            else:
                self._contents[i] = old_contents[i - offset]

######################################################################
###
### AVL Tree Dictionary
###

# a _balance? is one of:
#  - -1
#  - 0
#  - 1
let _balance? = OrC(-1, 0, 1)

# Below we will define a class to enclose our trees, but the
# tree itself is either a node or None:
let _tree? = OrC(_node?, NoneC)

struct _node:
    let key
    let balance: _balance?
    let left:    _tree?
    let right:   _tree?

# The main AVL tree operation is defined in _insert_helper, which
# does a leaf insertion and then rebalances. It needs to communicate
# two pieces of information to its caller, so we use a struct:
struct _grew:
    # The resulting tree (never None):
    let node: _node?

def _GROW(key, balance, left, right):
    return _grew(_node(key, balance, left, right))

let _maybe_grew? = OrC(_tree?, _grew?)

# Inserts `key` into `tree`, using comparision `lt?`. Returns an
# `_insert_result` containing the updated tree and whether it grew
# in height.
def _insert_helper(tree: _tree?, key, lt?) -> _maybe_grew?:
    if tree is None:
        return _GROW(key, 0, None, None)
    elif lt?(key, tree.key):
        return _rebalance(tree.key,
                          tree.balance,
                          _insert_helper(tree.left, key, lt?),
                          tree.right)
    elif lt?(tree.key, key):
        return _rebalance(tree.key,
                          tree.balance,
                          tree.left,
                          _insert_helper(tree.right, key, lt?))
    else:
        return _node(key, tree.balance, tree.left, tree.right)

def _rebalance(key,
               balance: _balance?,
               left: _maybe_grew?,
               right: _maybe_grew?) -> _maybe_grew?:
    if _grew?(left):
        return _rebalance_left(key, balance, left.node, right)
    elif _grew?(right):
        return _rebalance_right(key, balance, left, right.node)
    else:
        return _node(key, balance, left, right)

# Rebalances the given node parts, where `left0` is an
# `_insert_result?` that may invalidate `balance`. In particular,
# `balance` is correct if `_grew?(left0)` is false, and needs to
# be decreased by 1 if `_grew?(left0)` is true (in which case
# rebalancing may be required).
def _rebalance_left(key, balance: _balance?,
                    left: _node?, right: _tree?) -> _maybe_grew?:
    if balance == 1:
        return _node(key, 0, left, right)
    elif balance == 0:
        return _GROW(key, -1, left, right)
    elif left.balance == -1:
        return _node(left.key, 0, left.left,
                     _node(key, 0, left.right, right))
    elif left.balance == 1:
        return _node(left.right.key, 0,
                     _node(left.key,
                           _adjust_balance(-1, left.right),
                           left.left,
                           left.right.left),
                     _node(key,
                           _adjust_balance(1, left.right),
                           left.right.right,
                           right))
    else: error('Impossible!')

# Like _rebalance_left, but for when inserting into a right subtree.
def _rebalance_right(key, balance: _balance?,
                     left: _tree?, right: _tree?) -> _maybe_grew?:
    if balance == -1:
        return _node(key, 0, left, right)
    elif balance == 0:
        return _GROW(key, 1, left, right)
    elif right.balance == 1:
        return _node(right.key, 0,
                     _node(key, 0, left, right.left),
                     right.right)
    elif right.balance == -1:
        return _node(right.left.key, 0,
                     _node(key,
                           _adjust_balance(-1, right.left),
                           left,
                           right.left.left),
                     _node(right.key,
                           _adjust_balance(1, right.left),
                           right.left.right,
                           right.right))
    else: error('Impossible!')

def _adjust_balance(side, node):
    let bal = node.balance
    return -bal if -bal == side else 0

# See class `AvlTree` below for the actual way of constructing AVL
# trees. This is the class for representing AVL trees, but it's
# private so that it cannot be constructed from outside this module
# (file). The idea is that the constructor of this class is used by
# the `insert` method of this class to create new instances with
# the same comparison, but different roots and lengths. So, we don't
# want the constructor to be available to clients directly. Instead,
# The `AvlTree` class defined below knows how to call the private
# `_AvlTree` constructor to create an AVL tree.

class _AvlTree:
    let _root: _tree?
    let _len:  nat?
    let _lt?#: FunC[T, T, AnyC]

    # This isn't for the client to create objects, but for methods
    # of this class to create new objects.
    def __init__(self, root, len, lt?):
        self._root = root
        self._len = len
        self._lt? = lt?

    # Is this AVL tree empty?
    def empty?(self) -> bool?:
        return self._root is None

    # How many elements are in this AVL tree?
    def len(self) -> nat?:
        return self._len

    # Is the given `key` an element of this AVL tree?
    def mem?(self, key) -> bool?:
        let curr = self._root
        while curr:
            if self._lt?(key, curr.key):
                curr = curr.left
            elif self._lt?(curr.key, key):
                curr = curr.right
            else:
                return True
        return False

    def __contains__(self, key):
        return self.mem?(key)

    # Lookup the given `key` in the AVL tree, returning the
    # matching key if found (rather than the one given). If
    # `key` is not found, calls `or_else()` and returns the
    # result of that instead. This can be used to call `error`
    # or provide a default.
    def lookup(self, key, or_else: FunC[AnyC]) -> AnyC:
        let curr = self._root
        while curr:
            if self._lt?(key, curr.key):
                curr = curr.left
            elif self._lt?(curr.key, key):
                curr = curr.right
            else:
                return curr.key
        return or_else()

    # Inserts the given key into this AVL tree, returning the updated
    # tree while leaving `self` unchanged.
    def insert(self, key) -> _AvlTree?:
        let maybe_grew = _insert_helper(self._root, key, self._lt?)
        let new_root   = maybe_grew.node if _grew?(maybe_grew) else maybe_grew
        let Δlen       = 0 if self.mem?(key) else 1
        return _AvlTree(new_root, self._len + Δlen, self._lt?)

class _dict_entry:
    let _key
    let _val

    def __init__(self, key, val):
        self._key = key
        self._val = val

    def key(self): return self._key
    def val(self): return self._val

    def __cmp__(self, other):
        return cmp(self.key(), other.key())

# A dictionary class built on top of `_AvlTree`.
class AvlTree (DICT):
    let _repr: _AvlTree?

    def __init__(self, lt?):
        self._repr = _AvlTree(None, 0, lt?)

    def empty?(self) -> bool?:
        return self._repr.empty?()

    def len(self) -> nat?:
        return self._repr.len()

    def mem?(self, key) -> bool?:
        return self._repr.mem?(_dict_entry(key, None))

    def get(self, key) -> AnyC:
        def not_found():
            error('AvlTree.lookup: not found: %p', key)
        return self._repr.lookup(_dict_entry(key, None), not_found).val()

    def put(self, key, val) -> NoneC:
        self._repr = self._repr.insert(_dict_entry(key, val))

    def __contains__(self, key): return self.mem?(key)

    def __index_ref__(self, key): return self.get(key)


######################################################################
###
### Benchmarking
###

# Takes (any kind of!) empty dictionary as input.
def benchmark(title, d, n_iterations, n_insertions_per_iteration):
    let insert_data = [None; n_iterations]
    let lookup_data = [None; n_iterations]
    for i in range(n_iterations):
        print("running iteration %p of %p\n", i+1, n_iterations)
        for j in range(n_insertions_per_iteration - 1):
            d.put(d.len(), True)
        def do_insert(): d.put(d.len(), True)
        def do_lookup(): d.get(0)
        insert_data[i] = [i, (time: do_insert()).cpu]
        lookup_data[i] = [i, (time: do_lookup()).cpu]
    let title = '%s Benchmarks'.format(d.__class__)
    let data = [['insert', insert_data], ['lookup', lookup_data]]
    return plot(title, data, 'iters', 'time (ms)')

# benchmark("Association List",  # Your job to implement in Homework 3!
#           AssociationList(),
#           50,
#           50)
benchmark("Sorted Vector",
           VectorDict(),
           50,
           20)
# benchmark("Hash Table",
#           HashTable(100000, SboxHash64().hash),
#           50,
#           500)
# benchmark("AVL Tree",
#           AvlTree(lambda x, y: return x < y),
#           50,
#           500)
