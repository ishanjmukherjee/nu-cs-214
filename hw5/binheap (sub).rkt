#lang dssl2

# HW5: Binary Heap

let eight_principles = ["Know your rights.",
"Acknowledge your sources.",
"Protect your work.",
"Avoid suspicion.",
"Do your own work.",
"Never falsify a record or permit another person to do so.",
"Never fabricate data, citations, or experimental results.",
"Always tell the truth when discussing your work with your instructor."]

interface PRIORITY_QUEUE[X]:
    # Returns the number of elements in the priority queue.
    def len(self) -> nat?
    # Returns the smallest element; error if empty.
    def find_min(self) -> X
    # Removes the smallest element; error if empty.
    def remove_min(self) -> NoneC
    # Inserts an element; error if full.
    def insert(self, element: X) -> NoneC

# Class implementing the PRIORITY_QUEUE ADT as a binary heap.
class BinHeap[X] (PRIORITY_QUEUE):
    let _data: VecC[OrC(X, NoneC)]
    let _size: nat?
    let _capacity: nat?
    let _lt?:  FunC[X, X, bool?]

    # Constructs a new binary heap with the given capacity and
    # less-than function for type X.
    def __init__(self, capacity, lt?):
        self._data = [None for i in range(capacity)]
        self._capacity = capacity
        self._size = 0
        self._lt? = lt?
        
    def len(self) -> nat?:
        return self._size
        
    def find_min(self) -> X:
        if self._size == 0:
            error('BinHeap find_min: called on empty heap')
        return self._data[0]
        
    def remove_min(self) -> NoneC:
        if self._size == 0:
            error('BinHeap remove_min: called on empty heap')
        self._data[0] = self._data[self._size - 1]
        self._size = self._size - 1
        
        let cur_id = 0
        let smaller_child_id
        while cur_id < self._size:
             if (2*cur_id + 1) < self._size:
                 smaller_child_id = 2*cur_id+1
             else:
                 cur_id = 2*cur_id + 1
                 continue
             
             if ((2*cur_id+2) < self._size) and (self._lt?(self._data[2*cur_id+2], self._data[2*cur_id+1])):
                 smaller_child_id = 2*cur_id+2
             
             if not self._lt?(self._data[cur_id], self._data[smaller_child_id]):
                 self._swap(cur_id, smaller_child_id)
             
             cur_id = smaller_child_id
    
    def insert(self, element: X) -> NoneC:
        if self._size == self._capacity:
            error('BinHeap insert: called on full heap') 
        # insertion to preserve shape invariant
        let cur_id = self._size
        self._data[cur_id] = element
        
        # restoring ordering invariant
        let parent_id
        while cur_id > 0:
            #compare with parent
            parent_id = ((cur_id - 1)/2).floor()
            if not self._lt?(self._data[parent_id], self._data[cur_id]):
                self._swap(cur_id, parent_id)
            cur_id = parent_id
        
        # update size when heap is reordered
        self._size = self._size + 1
    #   ^ YOUR WORK GOES HERE

# Other methods you may need can go here.
    def _swap(self, a: nat?, b: nat?) -> NoneC:
        let temp = self._data[a]
        self._data[a] = self._data[b]
        self._data[b] = temp
       


# Woefully insufficient test.
test 'BinHeap instructor\'s test: insert, insert, remove_min':
    # The `nat?` here means our elements are restricted to `nat?`s.
    let h = BinHeap[nat?](10, λ x, y: x < y)
    h.insert(1)
    assert h.find_min() == 1
    
test 'BinHeap insert, find and remove single element':
    let h = BinHeap[nat?](10, λ x, y: x < y)
    assert_error h.find_min()
    assert_error h.remove_min()
    h.insert(9)
    assert h.find_min() == 9
    h.remove_min()
    assert_error h.find_min()
    assert_error h.remove_min()
    
test 'BinHeap multiple inserts, finds and removes':
    let h = BinHeap[nat?](10, λ x, y: x < y)
    h.insert(9)
    h.insert(10)
    h.insert(11)
    h.insert(8)
    h.insert(7)
    h.insert(7)
    
    assert h.find_min() == 7
    h.remove_min()
    assert h.find_min() == 7
    h.remove_min()
    assert h.find_min() == 8
    h.insert(4)
    assert h.find_min() == 4
    h.remove_min()
    assert h.find_min() == 8
    h.remove_min()
    assert h.find_min() == 9
    h.insert(12)
    h.remove_min()
    assert h.find_min() == 10
    h.remove_min()
    assert h.find_min() == 11
    h.insert(15)
    h.remove_min()
    assert h.find_min() == 12
    h.remove_min()
    assert h.find_min() == 15
    h.remove_min()
    assert_error h.find_min()
    assert_error h.remove_min()
    
test 'BinHeap inserting into a full heap':
    let h_1 = BinHeap[nat?](0, λ x, y: x < y)
    assert_error h_1.insert(10)
    let h_2 = BinHeap[nat?](3, λ x, y: x < y)
    h_2.insert(10)
    h_2.insert(20)
    h_2.insert(30)
    assert_error h_2.insert(40)


# Sorts a vector of Xs, given a less-than function for Xs.
#
# This function performs a heap sort by inserting all of the
# elements of v into a fresh heap, then removing them in
# order and placing them back in v.
def heap_sort[X](v: VecC[X], lt?: FunC[X, X, bool?]) -> NoneC:
    let h = BinHeap[X](v.len(), lt?)
    for x in v:
        h.insert(x)
    for i in range(v.len()):
        v[i] = h.find_min()
        h.remove_min()
        
#   ^ YOUR WORK GOES HERE

test 'instructor\'s test: heap sort descending':
    let v = [3, 6, 0, 2, 1]
    heap_sort(v, λ x, y: x > y)
    assert v == [6, 3, 2, 1, 0]

test 'heap sort empty vector':
    let v = []
    heap_sort(v, λ x, y: x > y)
    assert v == []
    
test 'heap sort empty vector':
    let v = []
    heap_sort(v, λ x, y: x > y)
    assert v == []
    
test 'heap sort vector of structs with duplicates':
    struct House:
        let id: float?
        let name: str?
        
    let v = [House(3.14, "a"), House(2.34, "a"), House(5.79, "a"), House(-1.1, "a"), House(2.34, "a")]
    heap_sort(v, λ x, y: x.id < y.id)
    assert v == [House(-1.1, "a"), House(2.34, "a"), House(2.34, "a"), House(3.14, "a"), House(5.79, "a")]

# Sorting colleges

struct college:
    let name: str?
    # Where is the college located? Can be "rural", "urban" or "suburban".
    let environment: str?
    # Average salary of graduates five years after graduation.
    let salary: int?
    # Average yearly tuition.
    let tuition: int?
    # Average SAT score of last incoming freshling class: between 400 and 1600.
    let sat: int?
    # Average GPA of last incoming freshling class: between 0.0 and 4.0.
    let gpa: num?
    # Number of full-time students attending the school as of last fall.
    let students: int?
    # Student-to-faculty ratio. E.g., 7000 students and 1000 faculty => 7
    let stf_ratio: num?
    # Acceptance rate. 0.0 = accepts no one. 1.0 = accepts everyone.
    let acceptance: num?

let sample_colleges = \
  [college("Montgomery College", "urban", 70000, 30000, 1500, 3.8, 4000, 8, 0.22),
   college("Vanderwaal University", "rural", 100000, 70000, 1550, 4.0, 1000, 2, 0.01),
   college("Hastings University", "suburban", 70000, 50000, 1530, 3.9, 8500, 6, 0.07),
   college("Marin College", "suburban", 38000, 6000, 1410, 3.9, 1500, 9, 0.39),
   college("Fields University","rural", 54000, 10000, 1360, 3.6, 500, 13, 0.53),
   college("Dilaurentis University", "rural", 58000, 40000, 1400, 3.7, 5000, 8, 0.44)
   ]

# Is `a` a better college than `b`?
# You decide what makes a college better than another, and you can use any
# or all of the information you have about each college to determine that.
def is_better?(a: college?, b: college?) -> bool?:
    def col_score(col: college?) -> float?:
        return ((1.5 * col.salary) * min((col.sat - 400), 10) * min(col.gpa, 0.1)) / (col.stf_ratio * col.tuition * col.acceptance)
    
    if col_score(a) > col_score(b):
        return True
    elif col_score(a) < col_score(b):
        return False
    else:
        # rank a or b higher randomly if both score same (very rare edge case)
        return [True, False].random(2)
#   ^ YOUR WORK GOES HERE

# Rank the sample colleges above, in order from "best" to "worst".
def rank_colleges() -> VecC[college?]:
    heap_sort(sample_colleges, is_better?)
    return sample_colleges
#   ^ YOUR WORK GOES HERE
