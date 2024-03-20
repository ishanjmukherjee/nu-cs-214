#lang dssl2

# HW4: Graph

import cons
import 'hw4-lib/dictionaries.rkt'
import sbox_hash

let eight_principles = ["Know your rights.",
"Acknowledge your sources.",
"Protect your work.",
"Avoid suspicion.",
"Do your own work.",
"Never falsify a record or permit another person to do so.",
"Never fabricate data, citations, or experimental results.",
"Always tell the truth when discussing your work with your instructor."]


###
### REPRESENTATION
###

# A Vertex is a natural number.
let Vertex? = nat?

# A VertexList is either
#  - None, or
#  - cons(v, vs), where v is a Vertex and vs is a VertexList
let VertexList? = Cons.ListC[Vertex?]

# A Weight is a real number. (It’s a number, but it’s neither infinite
# nor not-a-number.)
let Weight? = AndC(num?, NotC(OrC(inf, -inf, nan)))

# An OptWeight is either
# - a Weight, or
# - None
let OptWeight? = OrC(Weight?, NoneC)

# A WEdge is WEdge(Vertex, Vertex, Weight)
struct WEdge:
    let u: Vertex?
    let v: Vertex?
    let w: Weight?

# A WEdgeList is either
#  - None, or
#  - cons(w, ws), where w is a WEdge and ws is a WEdgeList
let WEdgeList? = Cons.ListC[WEdge?]

# A weighted, undirected graph ADT.
interface WUGRAPH:

    # Returns the number of vertices in the graph. (The vertices
    # are numbered 0, 1, ..., k - 1.)
    def len(self) -> nat?

    # Sets the weight of the edge between u and v to be w. Passing a
    # real number for w updates or adds the edge to have that weight,
    # whereas providing providing None for w removes the edge if
    # present. (In other words, this operation is idempotent.)
    def set_edge(self, u: Vertex?, v: Vertex?, w: OptWeight?) -> NoneC

    # Gets the weight of the edge between u and v, or None if there
    # is no such edge.
    def get_edge(self, u: Vertex?, v: Vertex?) -> OptWeight?

    # Gets a list of all vertices adjacent to v. (The order of the
    # list is unspecified.)
    def get_adjacent(self, v: Vertex?) -> VertexList?

    # Gets a list of all edges in the graph, in an unspecified order.
    # This list only includes one direction for each edge. For
    # example, if there is an edge of weight 10 between vertices
    # 1 and 3, then exactly one of WEdge(1, 3, 10) or WEdge(3, 1, 10)
    # will be in the result list, but not both.
    def get_all_edges(self) -> WEdgeList?

class WUGraph (WUGRAPH):
    let _matrix: VecC[VecC[OptWeight?]]
    let _length: nat?
    #   ^ ADD YOUR FIELDS HERE

    def __init__(self, size: nat?):
        self._matrix = [[None; size] for i in range(size)]
        self._length = size
        
    def len(self) -> nat?:
        return self._length
        
    def set_edge(self, u: Vertex?, v: Vertex?, w: OptWeight?) -> NoneC:
        if u >= self._length or v >= self._length:
            error("WUGraph set_edge: attempted to access vertex out of bounds")
        self._matrix[u][v] = w
        self._matrix[v][u] = w
        
    def get_edge(self, u: Vertex?, v: Vertex?) -> OptWeight?:
        if u >= self._length or v >= self._length:
            error("WUGraph get_edge: attempted to access vertex out of bounds")
        return self._matrix[u][v]
    
    def get_adjacent(self, v: Vertex?) -> VertexList?:
        let adjacents = None
        for i in range(self._length):
            if self._matrix[v][i] != None:
                adjacents = cons(i, adjacents)
        return Cons.rev(adjacents)
            
    def get_all_edges(self) -> WEdgeList?:
        let edges = None
        let w
        for i in range(self._length):
            for j in range(i, self._length):
                w = self.get_edge(i, j)  
                if w != None:
                    edges = cons(WEdge(i, j, w), edges)
        
        return edges
    #   ^ YOUR WORK GOES HERE
    
# Other methods you may need can go here.


###
### List helpers
###

# To test methods that return lists with elements in an unspecified
# order, you can use these functions for sorting. Sorting these lists
# will put their elements in a predictable order, order which you can
# use when writing down the expected result part of your tests.

# sort_vertices : ListOf[Vertex] -> ListOf[Vertex]
# Sorts a list of numbers.
def sort_vertices(lst: Cons.list?) -> Cons.list?:
    def vertex_lt?(u, v): return u < v
    return Cons.sort[Vertex?](vertex_lt?, lst)

# sort_edges : ListOf[WEdge] -> ListOf[WEdge]
# Sorts a list of weighted edges, lexicographically
# ASSUMPTION: There's no need to compare weights because
# the same edge can’t appear with different weights.
def sort_edges(lst: Cons.list?) -> Cons.list?:
    def edge_lt?(e1, e2):
        return e1.u < e2.u or (e1.u == e2.u and e1.v < e2.v)
    return Cons.sort[WEdge?](edge_lt?, lst)

###
### GRAPH CLASS TESTS
###
test 'WUGraph: single edge set, get and remove':
    let g = WUGraph(3)
    assert g.len() == 3
    g.set_edge(1,2,3)
    assert g.len() == 3
    assert g.get_edge(0,0) == None
    assert g.get_edge(0,1) == None
    assert g.get_edge(0,2) == None
    assert_error g.get_edge(0,3)
    assert g.get_edge(1,0) == None
    assert g.get_edge(1,1) == None
    assert g.get_edge(1,2) == 3
    assert_error g.get_edge(1,3)
    assert g.get_edge(2,0) == None
    assert g.get_edge(2,1) == 3
    assert g.get_edge(2,2) == None
    assert_error g.get_edge(2,3)
    assert_error g.get_edge(3,0)
    g.set_edge(1,2,None)
    assert g.len() == 3
    assert g.get_edge(0,0) == None
    assert g.get_edge(0,1) == None
    assert g.get_edge(0,2) == None
    assert_error g.get_edge(0,3)
    assert g.get_edge(1,0) == None
    assert g.get_edge(1,1) == None
    assert g.get_edge(1,2) == None
    assert_error g.get_edge(1,3)
    assert g.get_edge(2,0) == None
    assert g.get_edge(2,1) == None
    assert g.get_edge(2,2) == None
    assert_error g.get_edge(2,3)
    assert_error g.get_edge(3,0)
    
test 'WUGraph: edge update':
    let g = WUGraph(3)
    assert g.get_edge(1,0) == None
    assert g.get_edge(0,1) == None
    g.set_edge(1,0,10)
    assert g.len() == 3
    assert g.get_edge(1,0) == 10
    assert g.get_edge(0,1) == 10
    g.set_edge(1,0,20)
    assert g.len() == 3
    assert g.get_edge(1,0) == 20
    assert g.get_edge(0,1) == 20
    
test 'WUGraph: get_adjacent':
    let g= WUGraph(3)
    g.set_edge(1,0,10)
    g.set_edge(1,1,20)
    assert g.len() == 3
    assert sort_vertices(g.get_adjacent(1)) == cons(0, cons(1, None))
    assert sort_vertices(g.get_adjacent(0)) == cons(1, None)
    assert sort_vertices(g.get_adjacent(2)) == None
    
test 'WUGraph: single edge get_all_edges':
    let g = WUGraph(3)
    g.set_edge(1,0,10)
    assert g.len() == 3
    assert g.get_all_edges() == cons(WEdge(0, 1, 10), None)
    
test 'WUGraph: multiple edges get_all_edges':
    let g = WUGraph(5)
    # (i, i, 10*i) are edges
    g.set_edge(0,0,0)
    g.set_edge(0,3,11)
    g.set_edge(3,1,22)
    assert g.len() == 5
    assert sort_edges(g.get_all_edges()) == cons(WEdge(0,0,0), cons(WEdge(0,3,11), cons(WEdge(1,3,22), None)))
    assert g.len() == 5
    
###
### BUILDING GRAPHS
###

def example_graph() -> WUGraph?:
    let result = WUGraph(6) # 6-vertex graph from the assignment
    result.set_edge(0,1,12)
    result.set_edge(1,2,31)
    result.set_edge(1,3,56)
    result.set_edge(3,5,1)
    result.set_edge(3,4,9)
    result.set_edge(2,5,7)
    result.set_edge(2,4,-2)
    return result
#   ^ YOUR WORK GOES HERE

struct CityMap:
    let graph
    let city_name_to_node_id
    let node_id_to_city_name

def my_neck_of_the_woods():
    let cities = ["Varanasi", "Karaundi", "Sigra", "Lanka", "Mirzapur"]
    let h_c_to_id = HashTable(10, make_sbox_hash())
    let h_id_to_c = HashTable(10, make_sbox_hash())
    for i in range(cities.len()):
        h_c_to_id.put(cities[i], i)
        h_id_to_c.put(i, cities[i])
        
    let g = WUGraph(5)
    for i in range(cities.len() - 1):
        g.set_edge(0,i+1,10*(i+1))
    return CityMap(g, h_c_to_id, h_id_to_c)
    
test 'my_neck_of_woods':
    let map = my_neck_of_the_woods()
    let cities = ["Varanasi", "Karaundi", "Sigra", "Lanka", "Mirzapur"]
    for i in range(1,cities.len()):
        assert map.graph.get_edge(map.city_name_to_node_id.get(map.node_id_to_city_name.get(0)), map.city_name_to_node_id.get(map.node_id_to_city_name.get(i))) == 10 * i
    
    
#   ^ YOUR WORK GOES HERE

###
### DFS
###

# dfs : WUGRAPH Vertex [Vertex -> any] -> None
# Performs a depth-first search starting at `start`, applying `f`
# to each vertex once as it is discovered by the search.
def dfs(graph: WUGRAPH!, start: Vertex?, f: FunC[Vertex?, AnyC]) -> NoneC:
    let seen = [False for i in range(graph.len())]
    
    def dfs_traverse(w: Vertex?, f: FunC[Vertex?, AnyC]) -> NoneC:
        if not seen[w]:
            seen[w] = True
            f(w)
            for neighbor in Cons.to_vec(graph.get_adjacent(w)):
                dfs_traverse(neighbor, f)
           
    
    dfs_traverse(start, f)
#   ^ YOUR WORK GOES HERE

# dfs_to_list : WUGRAPH Vertex -> ListOf[Vertex]
# Performs a depth-first search starting at `start` and returns a
# list of all reachable vertices.
#
# This function uses your `dfs` function to build a list in the
# order of the search. It will pass the test below if your dfs visits
# each reachable vertex once, regardless of the order in which it calls
# `f` on them. However, you should test it more thoroughly than that
# to make sure it is calling `f` (and thus exploring the graph) in
# a correct order.
def dfs_to_list(graph: WUGRAPH!, start: Vertex?) -> VertexList?:
    let list = None
    # Add to the front when we visit a node
    dfs(graph, start, lambda new: list = cons(new, list))
    # Reverse to the get elements in visiting order.
    return Cons.rev(list)

###
### TESTING
###

## You should test your code thoroughly. Here is one test to get you started:

test 'sorted dfs_to_list(example_graph())':
    # Cons.from_vec is a convenience function from the `cons` library that
    # allows you to write a vector (using the nice vector syntax), and get
    # a linked list with the same elements.
    for i in range(6):
        assert sort_vertices(dfs_to_list(example_graph(), i)) \
        == Cons.from_vec([0, 1, 2, 3, 4, 5])
        
test 'unsorted dfs_to_list(example_graph())':
    assert dfs_to_list(example_graph(), 1) \
        == Cons.from_vec([1, 0, 2, 4, 3, 5])
        
    assert dfs_to_list(example_graph(), 2) \
        == Cons.from_vec([2, 1, 0, 3, 4, 5])
        
    assert dfs_to_list(example_graph(), 3) \
        == Cons.from_vec([3, 1, 0, 2, 4, 5])
        
    assert dfs_to_list(example_graph(), 4) \
        == Cons.from_vec([4, 2, 1, 0, 3, 5])
        
    assert dfs_to_list(example_graph(), 5) \
        == Cons.from_vec([5, 2, 1, 0, 3, 4])
