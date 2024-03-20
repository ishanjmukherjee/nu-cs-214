#lang dssl2

import sbox_hash

###
### Open-addressing, linear probing hash table
###
### Resolve collisions by trying the next bucket.
###

let _FILL_FACTOR = 0.75

struct _entry:
    let key
    let value

interface DICT[K, V]:
    def len(self) -> nat?
    def mem?(self, key: K) -> bool?
    def get(self, key: K) -> V
    def put(self, key: K, value: V) -> NoneC

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


# first_char_hasher(String) -> Natural
# A simple and bad hash function that just returns the ASCII code
# of the first character.
# Useful for debugging because it's easily predictable.
def first_char_hasher(s: str?) -> int?:
    if s.len() == 0:
        return 0
    else:
        return int(s[0])

test 'first_char_hasher':
    assert first_char_hasher('') == 0
    assert first_char_hasher('A') == 65
    assert first_char_hasher('Apple') == 65
    assert first_char_hasher('apple') == 97

test 'growing':
    let h = HashTable(1, make_sbox_hash())
    assert h.len() == 0
    h.put('a', 1)
    assert h.len() == 1
    assert h.get('a') == 1
    assert_error h.get('b')
    h.put('b', 2)
    assert h.get('a') == 1
    assert h.get('b') == 2
    h.put('a', 3)
    assert h.get('a') == 3
    assert h.get('b') == 2
    assert h.len() == 2
