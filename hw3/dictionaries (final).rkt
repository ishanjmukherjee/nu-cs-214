#lang dssl2

# HW3: Dictionaries

let eight_principles = ["Know your rights.",
"Acknowledge your sources.",
"Protect your work.",
"Avoid suspicion.",
"Do your own work.",
"Never falsify a record or permit another person to do so.",
"Never fabricate data, citations, or experimental results.",
"Always tell the truth when discussing your work with your instructor."]

import sbox_hash

# A signature for the dictionary ADT. The contract parameters `K` and
# `V` are the key and value types of the dictionary, respectively.
interface DICT[K, V]:
    # Returns the number of key-value pairs in the dictionary.
    def len(self) -> nat?
    # Is the given key mapped by the dictionary?
    # Notation: `key` is the name of the parameter. `K` is its contract.
    def mem?(self, key: K) -> bool?
    # Gets the value associated with the given key; calls `error` if the
    # key is not present.
    def get(self, key: K) -> V
    # Modifies the dictionary to associate the given key and value. If the
    # key already exists, its value is replaced.
    def put(self, key: K, value: V) -> NoneC
    # Modifes the dictionary by deleting the association of the given key.
    def del(self, key: K) -> NoneC
    # The following method allows dictionaries to be printed
    def __print__(self, print)

struct _cons:
    let key
    let value
    let next: OrC(_cons?, NoneC)

class AssociationList[K, V] (DICT):

    let _head: OrC(_cons?, NoneC)
    let _length: nat?
    #   ^ ADDITIONAL FIELDS HERE

    def __init__(self):
        self._head = None
        self._length = 0
        pass
        
    def len(self) -> nat?:
        return self._length
    def mem?(self, key: K) -> bool?:
        let cur = self._head
        while cur != None:
            if cur.key == key:
                return True
            cur = cur.next
        return False
    def get(self, key: K) -> V:
        let cur = self._head
        while cur != None:
            if cur.key == key:
                return cur.value
            cur = cur.next
        error("AssociationList get: key not in dict")
    def put(self, key: K, value: V) -> NoneC:
        if self._head == None:
            self._head = _cons(key,value, None)
            self._length = self._length + 1
            return
        let cur = self._head
        let tail = cur
        while cur != None:
            if cur.key == key:
                cur.value = value
                return
            tail = cur
            cur = cur.next
        tail.next = _cons(key, value, None)
        self._length = self._length + 1
    def del(self, key: K) -> NoneC:
        if self._head == None:
            return
        if self._head.key == key:
            self._head = self._head.next
            self._length = self._length - 1
            return
        let cur = self._head
        let prev = cur
        while cur != None:
            if cur.key == key:
                prev.next = cur.next
                self._length = self._length - 1
                return
            prev = cur
            cur = cur.next
            

    # See above.
    def __print__(self, print):
        print("#<object:AssociationList head=%p>", self._head)

    # Other methods you may need can go here.

test 'AssociationList: length of and deletion from empty list':
    let a = AssociationList()
    assert a.len() == 0
    a.del(9)
    assert a.len() == 0
    assert_error a.get(9)
    
test 'AssociationList: deleting a single element':
    let a = AssociationList()
    a.put(1, 'a')
    assert a.len() == 1
    assert a.mem?(1)
    assert a.get(1) == 'a'
    a.del(1)
    assert a.len() == 0
    assert not a.mem?(1)
    assert_error a.get(1)
     
test 'AssociationList: deleting multiple elements':
    let a = AssociationList()
    a.put(1, 'a')
    a.put(2, 'b')
    a.put(3, 'c')
    a.put(4, 'd')
    assert a.len() == 4
    assert a.mem?(2)
    a.del(2)
    assert a.len() == 3
    assert a.mem?(1)
    assert not a.mem?(2)
    assert a.mem?(3)
    assert a.mem?(4)
    a.del(5)
    assert a.len() == 3
    assert a.mem?(1)
    assert not a.mem?(2)
    assert a.mem?(3)
    assert a.mem?(4)
    a.del(4)
    assert a.len() == 2
    assert a.mem?(1)
    assert not a.mem?(2)
    assert a.mem?(3)
    assert not a.mem?(4)
    a.del(1)
    assert a.len() == 1
    assert not a.mem?(1)
    assert not a.mem?(2)
    assert a.mem?(3)
    assert not a.mem?(4)
    a.del(1)
    assert a.len() == 1
    assert not a.mem?(1)
    assert not a.mem?(2)
    assert a.mem?(3)
    assert not a.mem?(4)
    a.del(3)
    assert a.len() == 0
    assert not a.mem?(1)
    assert not a.mem?(2)
    assert not a.mem?(3)
    assert not a.mem?(4)
    
test 'AssociationList: adding and updating multiple elements':
    let a = AssociationList()
    assert not a.mem?(1)
    assert not a.mem?(2)
    assert not a.mem?(3)
    assert a.len() == 0
    assert_error a.get(1)
    a.put(1, 'a')
    assert a.mem?(1)
    assert not a.mem?(2)
    assert not a.mem?(3)
    assert a.len() == 1
    assert a.get(1) == 'a'
    a.put(2, 'b')
    assert a.len() == 2
    assert a.mem?(1)
    assert a.mem?(2)
    assert not a.mem?(3)
    assert a.get(1) == 'a'
    assert a.mem?(2)
    assert a.get(2) == 'b'
    a.put(3, 'c')
    assert a.len() == 3
    assert a.mem?(1)
    assert a.mem?(2)
    assert a.mem?(3)
    assert a.get(1) == 'a'
    assert a.mem?(2)
    assert a.get(2) == 'b'
    assert a.mem?(3)
    assert a.get(3) == 'c'
    a.put(1, 'd')
    assert a.len() == 3
    assert a.mem?(1)
    assert a.get(1) == 'd'
    assert a.mem?(2)
    assert a.get(2) == 'b'
    assert a.mem?(3)
    assert a.get(3) == 'c'
    

test 'AssociationList: instructor\'s test':
    let a = AssociationList()
    assert not a.mem?('hello')
    a.put('hello', 5)
    assert a.len() == 1
    assert a.mem?('hello')
    assert a.get('hello') == 5


class HashTable[K, V] (DICT):
    let _hash: FunC[AnyC, nat?]
    let _size: nat?
    let _data: VecC[OrC(_cons?, NoneC)]
    let _nbuckets: nat?

    def __init__(self, nbuckets: nat?, hash: FunC[AnyC, nat?]):
        self._hash = hash
        self._size = 0
        self._nbuckets = nbuckets
        self._data = [None; nbuckets]
        pass
        
    def len(self) -> nat?:
        return self._size
    
    def mem?(self, key: K) -> bool?:
        if self._data[self._hash(key) % self._nbuckets] != None:
            let cur = self._data[self._hash(key) % self._nbuckets]
            while cur != None:
                if cur.key == key:
                    return True
                cur = cur.next
        return False
            
    def get(self, key: K) -> V:
        if self._data[self._hash(key) % self._nbuckets] != None:
            let cur = self._data[self._hash(key) % self._nbuckets]
            while cur != None:
                if cur.key == key:
                    return cur.value
                cur = cur.next
        error("HashTable: key not in dict")
    
    def put(self, key: K, value: V) -> NoneC:
        let cur = self._data[self._hash(key) % self._nbuckets]
        while cur != None:
            if cur.key == key:
                cur.value = value
                return
            cur = cur.next
        let new_cons = _cons(key, value, self._data[self._hash(key) % self._nbuckets])
        self._data[self._hash(key) % self._nbuckets] = new_cons
        self._size = self._size + 1
        return
    
    def del(self, key: K) -> NoneC:
        if self._data[self._hash(key) % self._nbuckets] == None:
            return
        if self._data[self._hash(key) % self._nbuckets].key == key:
            self._data[self._hash(key) % self._nbuckets] = self._data[self._hash(key) % self._nbuckets].next
            self._size = self._size - 1
            return
        let cur = self._data[self._hash(key) % self._nbuckets]
        let prev = cur
        while cur != None:
            if cur.key == key:
                prev.next = cur.next
                self._size = self._size - 1
                return
            prev = cur
            cur = cur.next
    #   ^ YOUR WORK GOES HERE

    # This avoids trying to print the hash function, since it's not really
    # printable and isn’t useful to see anyway:
    def __print__(self, print):
        print("#<object:HashTable  _hash=... _size=%p _data=%p>",
              self._size, self._data)

    # Other methods you may need can go here.


# first_char_hasher(String) -> Natural
# A simple and bad hash function that just returns the ASCII code
# of the first character.
# Useful for debugging because it's easily predictable.
def first_char_hasher(s: str?) -> int?:
    if s.len() == 0:
        return 0
    else:
        return int(s[0])

test 'HashTable: adding and deleting a single element':
     let h = HashTable(10, first_char_hasher)
     h.put('q', 0)
     assert h.len() == 1
     assert h.mem?('q')
     assert h.get('q') == 0
     h.del('q')
     assert h.len() == 0
     assert not h.mem?('q')
     assert_error h.get('q') 
     
test 'HashTable: adding and deleting colliding elements':
     let h = HashTable(10, first_char_hasher)
     
     h.put('q', 0)
     assert h.len() == 1
     assert h.mem?('q')
     assert h.get('q') == 0
     
     h.put('quartz', 1)
     assert h.len() == 2
     assert h.mem?('q')
     assert h.get('q') == 0
     assert h.mem?('quartz')
     assert h.get('quartz') == 1
     
     h.put('potassium', 1)
     assert h.len() == 3
     assert h.mem?('q')
     assert h.get('q') == 0
     assert h.mem?('quartz')
     assert h.get('quartz') == 1
     assert h.mem?('potassium')
     assert h.get('potassium') == 1
     
     h.put('perfect', 56)
     assert h.len() == 4
     assert h.mem?('q')
     assert h.get('q') == 0
     assert h.mem?('quartz')
     assert h.get('quartz') == 1
     assert h.mem?('potassium')
     assert h.get('potassium') == 1
     assert h.mem?('perfect')
     assert h.get('perfect') == 56
     
     h.del('quartz')
     assert h.len() == 3
     assert h.mem?('q')
     assert h.get('q') == 0
     assert not h.mem?('quartz')
     assert_error h.get('quartz')
     assert h.mem?('potassium')
     assert h.get('potassium') == 1
     assert h.mem?('perfect')
     assert h.get('perfect') == 56
     
     h.del('potassium')
     assert h.len() == 2
     assert h.mem?('q')
     assert h.get('q') == 0
     assert not h.mem?('quartz')
     assert_error h.get('quartz')
     assert not h.mem?('potassium')
     assert_error h.get('potassium')
     assert h.mem?('perfect')
     assert h.get('perfect') == 56
     
     h.del('perfect')
     assert h.len() == 1
     assert h.mem?('q')
     assert h.get('q') == 0
     assert not h.mem?('quartz')
     assert_error h.get('quartz')
     assert not h.mem?('potassium')
     assert_error h.get('potassium')
     assert not h.mem?('perfect')
     assert_error h.get('perfect')
     
     h.del('q')
     assert h.len() == 0
     assert not h.mem?('q')
     assert_error h.get('q')
     assert not h.mem?('quartz')
     assert_error h.get('quartz')
     assert not h.mem?('potassium')
     assert_error h.get('potassium')
     assert not h.mem?('perfect')
     assert_error h.get('perfect')
        
test 'HashTable: handling collision of elements, no modulo':
     let h = HashTable(10, first_char_hasher)
     assert h.len() == 0
     h.put('a', 1)
     assert h.len() == 1
     assert h.mem?('a')
     assert h.get('a') == 1
     h.put('amigo', 2)
     assert h.len() == 2
     assert h.mem?('a')
     assert h.get('a') == 1
     assert h.mem?('amigo')
     assert h.get('amigo') == 2
     
test 'HashTable: handling collision of elements, with modulo':
     let h = HashTable(10, first_char_hasher)
     assert h.len() == 0
     h.put('p', 3)
     assert h.len() == 1
     assert h.mem?('p')
     assert h.get('p') == 3
     h.put('put', 4)
     assert h.len() == 2
     assert h.mem?('put')
     assert h.get('put') == 4
        
test 'HashTable: instructor\'s test':
    let h = HashTable(10, make_sbox_hash())
    assert not h.mem?('hello')
    h.put('hello', 5)
    assert h.len() == 1
    assert h.mem?('hello')
    assert h.get('hello') == 5


def compose_phrasebook(d: DICT!) -> DICT?:
    d.put('Dolmus', ['Bus', 'Dol-Mush'])
    d.put('Lütfen', ['Please', 'Loot-fen'])
    d.put('Nasilsiniz?', ['How are you?', 'Nah-suhl-suh-nuhz'])
    d.put('Teşekkürler', ['Thank you', 'Tesh-eh-kur-Ler'])
    d.put('Merhaba', ['Hello', 'Mur-Ha-Bah'])
    return d
#   ^ YOUR WORK GOES HERE

test "AssociationList phrasebook":
    let d = AssociationList()
    d = compose_phrasebook(d)
    assert d.get('Merhaba')[1] == 'Mur-Ha-Bah'

test "HashTable phrasebook":
    let d = HashTable(10, make_sbox_hash())
    d = compose_phrasebook(d)
    assert d.get('Merhaba')[1] == 'Mur-Ha-Bah'
