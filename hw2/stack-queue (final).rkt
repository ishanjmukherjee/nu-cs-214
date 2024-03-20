#lang dssl2

# HW2: Stacks and Queues

let eight_principles = ["Know your rights.",
"Acknowledge your sources.",
"Protect your work.",
"Avoid suspicion.",
"Do your own work.",
"Never falsify a record or permit another person to do so.",
"Never fabricate data, citations, or experimental results.",
"Always tell the truth when discussing your work with your instructor."]


import ring_buffer

interface STACK[T]:
    def push(self, element: T) -> NoneC
    def pop(self) -> T
    def empty?(self) -> bool?

# Defined in the `ring_buffer` library; copied here for reference.
# Do not uncomment! or you'll get errors.
# interface QUEUE[T]:
#     def enqueue(self, element: T) -> NoneC
#     def dequeue(self) -> T
#     def empty?(self) -> bool?

# Linked-list node struct (implementation detail):
struct _cons:
    let data
    let next: OrC(_cons?, NoneC)

###
### ListStack
###

class ListStack[T] (STACK):

    # Any fields you may need can go here.
    let head: _cons?

    # Constructs an empty ListStack.
    def __init__ (self):
        self.head = _cons(None, None)
    #   ^ YOUR WORK GOES HERE

    # Other methods you may need can go here.
    def empty?(self) -> bool?:
        return self.head.data == None
    
    def push(self, element: T) -> NoneC:
       let new_cons = _cons(element, self.head)
       self.head = new_cons
    
    def pop(self) -> T:
       if self.empty?():
           error('ListStack pop: attempted to pop from empty list')
       else:
           let head_elem = self.head.data
           self.head = self.head.next
           return head_elem
                    

test "woefully insufficient":
    let s = ListStack()
    s.push(2)
    assert s.pop() == 2
    
test "ListStack pop empty list test":
    let s = ListStack()
    assert_error s.pop()

test "ListStack empty? test":
    let s = ListStack()
    assert s.empty?() == True
    s.push(1)
    assert s.empty?() == False
    
test "ListStack all methods test":
    let s = ListStack()
    assert s.empty?() == True
    s.push(1)
    assert s.empty?() == False
    s.push(2)
    assert s.empty?() == False
    assert s.pop() == 2
    assert s.empty?() == False
    assert s.pop() == 1
    assert s.empty?() == True
    assert_error s.pop()

###
### ListQueue
###

class ListQueue[T] (QUEUE):

    # Any fields you may need can go here.
    let head: _cons?
    let tail: _cons?

    # Constructs an empty ListQueue.
    def __init__ (self):
        self.head = _cons(None, None)
        self.tail = _cons(None, None)
    #   ^ YOUR WORK GOES HERE

    # Other methods you may need can go here.
    def empty?(self) -> bool?:
       return self.head.data == None
    def enqueue(self, element: T) -> NoneC:
       if self.empty?():
           self.head.data = element
           self.tail = self.head
       else:
           self.tail.next = _cons(element, None)
           self.tail = self.tail.next
    def dequeue(self) -> T:
       if self.empty?():
           error('ListQueue dequeue: attempted to dequeue from empty list')
       elif self.head.next == None:
           let head_elem = self.head.data
           self.head.data = None
           return head_elem
       else:
           let head_elem = self.head.data
           self.head = self.head.next
           return head_elem

test "woefully insufficient, part 2":
    let q = ListQueue()
    q.enqueue(2)
    assert q.dequeue() == 2
    
test "ListQueue dequeue empty list test":
    let q = ListQueue()
    assert_error q.dequeue()

test "ListQueue empty? test":
    let q = ListQueue()
    assert q.empty?() == True
    q.enqueue(2)
    assert q.empty?() == False 
    
test "ListQueue all methods test":
    let q = ListQueue()
    assert q.empty?() == True
    q.enqueue(2)
    assert q.empty?() == False
    q.enqueue(3)
    assert q.empty?() == False
    assert q.dequeue() == 2
    assert q.empty?() == False
    assert q.dequeue() == 3
    assert q.empty?() == True
    assert_error q.dequeue()
    q.enqueue(2)
    assert q.empty?() == False
    q.enqueue(3)
    assert q.empty?() == False
    assert q.dequeue() == 2
    assert q.empty?() == False
    assert q.dequeue() == 3
    assert q.empty?() == True
    assert_error q.dequeue()

###
### Playlists
###

struct song:
    let title: str?
    let artist: str?
    let album: str?

# Enqueue five songs of your choice to the given queue, then return the first
# song that should play.
def fill_playlist (q: QUEUE!):
    q.enqueue(song('Feel It Still', 'Portugal: The Man', 'Woodstock'))
    q.enqueue(song('Tu Hi Hai', 'Ali Zafar', 'Dear Zindagi'))
    q.enqueue(song('How to Save a Life', 'The Fray', 'How to Save a Life'))
    q.enqueue(song('Here For Now', 'Bronze Radio Return', 'Entertain You'))
    q.enqueue(song('Srivalli', 'Sid Sriram', 'Pushpa'))
    return q.dequeue()
#   ^ YOUR WORK GOES HERE

test "ListQueue playlist":
    let q = ListQueue()
    assert fill_playlist(q) == song('Feel It Still', 'Portugal: The Man', 'Woodstock')

# To construct a RingBuffer: RingBuffer(capacity)
test "RingBuffer playlist":
    let q = RingBuffer(5)
    assert fill_playlist(q) == song('Feel It Still', 'Portugal: The Man', 'Woodstock')
