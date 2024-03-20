#lang dssl2

# Final project: Trip Planner

let eight_principles = ["Know your rights.",
"Acknowledge your sources.",
"Protect your work.",
"Avoid suspicion.",
"Do your own work.",
"Never falsify a record or permit another person to do so.",
"Never fabricate data, citations, or experimental results.",
"Always tell the truth when discussing your work with your instructor."]

import cons
import sbox_hash
import 'project-lib/dictionaries.rkt'
import 'project-lib/graph.rkt'
import 'project-lib/binheap.rkt'

### Basic Types ###

#  - Latitudes and longitudes are numbers:
let Lat?  = num?
let Lon?  = num?

#  - Point-of-interest categories and names are strings:
let Cat?  = str?
let Name? = str?

### Raw Item Types ###

#  - Raw positions are 2-element vectors with a latitude and a longitude
let RawPos? = TupC[Lat?, Lon?]

#  - Raw road segments are 4-element vectors with the latitude and
#    longitude of their first endpoint, then the latitude and longitude
#    of their second endpoint
let RawSeg? = TupC[Lat?, Lon?, Lat?, Lon?]

#  - Raw points-of-interest are 4-element vectors with a latitude, a
#    longitude, a point-of-interest category, and a name
let RawPOI? = TupC[Lat?, Lon?, Cat?, Name?]

### Contract Helpers ###

# ListC[T] is a list of `T`s (linear time):
let ListC = Cons.ListC
# List of unspecified element type (constant time):
let List? = Cons.list?

### Internal Item Representations ###

struct Pos:
    let lat: Lat?
    let lon: Lon?
    
struct Seg:
    let a: Pos?
    let b: Pos?
    
struct POI:
    let pos: Pos?
    let name: Name?
    let cat: Cat?
    
### Return Type for Dijkstra ###
    
struct Dijkstra:
    let path: List?
    let dist: num?

interface TRIP_PLANNER:

    # Returns the positions of all the points-of-interest that belong to
    # the given category.
    def locate_all(
            self,
            dst_cat:  Cat?           # point-of-interest category
        )   ->        ListC[RawPos?] # positions of the POIs

    # Returns the shortest route, if any, from the given source position
    # to the point-of-interest with the given name.
    def plan_route(
            self,
            src_lat:  Lat?,          # starting latitude
            src_lon:  Lon?,          # starting longitude
            dst_name: Name?          # name of goal
        )   ->        ListC[RawPos?] # path to goal

    # Finds no more than `n` points-of-interest of the given category
    # nearest to the source position.
    def find_nearby(
            self,
            src_lat:  Lat?,          # starting latitude
            src_lon:  Lon?,          # starting longitude
            dst_cat:  Cat?,          # point-of-interest category
            n:        nat?           # maximum number of results
        )   ->        ListC[RawPOI?] # list of nearby POIs


class TripPlanner (TRIP_PLANNER):
    let _graph: WUGraph?
    let _pos_to_node_id: HashTable?
    let _node_id_to_pos: HashTable?
    let _names_dict: HashTable?
    let _cats_dict: HashTable?
    
    #
    # constructor
    #
    
    def __init__(self, segs: VecC[RawSeg?], pois: VecC[RawPOI?]):
        let unique_pos_count = 0
        self._pos_to_node_id = HashTable(3, make_sbox_hash())
        self._node_id_to_pos = HashTable(3, make_sbox_hash())
        
        # determining number of nodes in graph
        for seg in segs:
            let modified_seg = Seg(Pos(seg[0], seg[1]), Pos(seg[2], seg[3]))
            for pos in [modified_seg.a, modified_seg.b]:
                if not self._pos_to_node_id.mem?(pos):
                    self._pos_to_node_id.put(pos, unique_pos_count)
                    self._node_id_to_pos.put(unique_pos_count, pos)
                    unique_pos_count = unique_pos_count + 1
                else:
                    pass
        
        # initializing graph with number of nodes
        self._graph = WUGraph(unique_pos_count)  
        
        # populating graph
        for seg in segs:
            let modified_seg = Seg(Pos(seg[0], seg[1]), Pos(seg[2], seg[3]))
            self._graph.set_edge(self._pos_to_node_id.get(modified_seg.a),
                                 self._pos_to_node_id.get(modified_seg.b),
                                 self._dist(modified_seg.a, modified_seg.b))
        
        # initialize names and cats dicts
        self._names_dict = HashTable(3, make_sbox_hash())
        self._cats_dict = HashTable(3, make_sbox_hash())
        for poi in pois:
            let modified_POI = POI(Pos(poi[0], poi[1]), poi[3], poi[2])
            self._names_dict.put(modified_POI.name, modified_POI)
            if not self._cats_dict.mem?(modified_POI.cat):
                self._cats_dict.put(modified_POI.cat, cons(modified_POI, None))
            else:
                self._cats_dict.put(modified_POI.cat, cons(modified_POI, self._cats_dict.get(modified_POI.cat)))
        
    #
    # locate_all
    #
        
    def locate_all(
            self,
            dst_cat:  Cat?           # point-of-interest category
        )   ->        ListC[RawPos?]: # positions of the POIs
            let cur = self._cats_dict.get(dst_cat)
            let result = None
            while cur != None:
                result = cons([cur.data.pos.lat, cur.data.pos.lon], result)
                cur = cur.next
            return result

    #
    # plan_route
    #
            
    def plan_route(
            self,
            src_lat:  Lat?,          # starting latitude
            src_lon:  Lon?,          # starting longitude
            dst_name: Name?          # name of goal
        )   ->        ListC[RawPos?]: # path to goal
            let src_pos = Pos(src_lat, src_lon)
            let dst_pos = self._names_dict.get(dst_name).pos
            return self._dijkstra(src_pos, dst_pos).path

    #
    # find_nearby
    #
            
    def find_nearby(
            self,
            src_lat:  Lat?,          # starting latitude
            src_lon:  Lon?,          # starting longitude
            dst_cat:  Cat?,          # point-of-interest category
            n:        nat?           # maximum number of results
        )   ->        ListC[RawPOI?]: # list of nearby POIs
            # initialization
            let src_pos = Pos(src_lat, src_lon)
            let dsts = self._cats_dict.get(dst_cat)
            let dsts_hp = BinHeap[TupC[POI?, num?]](Cons.len(dsts), λ x, y: x[1] < y[1])
            
            # add all relevant POIs to min-heap by distance
            let cur = dsts
            while cur != None:
                let cur_dist = self._dijkstra(src_pos, cur.data.pos).dist
                dsts_hp.insert([cur.data, cur_dist])
                cur = cur.next
            # output n closest POIs
            let results = None
            for i in range(n):
                if dsts_hp.len() > 0:
                    let dst = dsts_hp.find_min()[0]
                    results = cons([dst.pos.lat, dst.pos.lon, dst.cat, dst.name], results)
                else:
                    break
            return results
    #
    # _dist
    # helper function to return Euclidean distance between two given positions      
    #          
    def _dist(self, a: Pos?, b: Pos?) -> num?:
         return ((a.lat - b.lat)**2+(a.lon - b.lon)**2).sqrt()
    
    #
    # _dijkstra
    # helper function to return shortest path and distance between two given positions      
    #     
    def _dijkstra(self, src_pos: Pos?, dst_pos: Pos?) -> Dijkstra?:
        if not self._pos_to_node_id.mem?(src_pos) or not self._pos_to_node_id.mem?(dst_pos):
            return Dijkstra(None, inf)
        let src_node = self._pos_to_node_id.get(src_pos)
        let dst_node = self._pos_to_node_id.get(dst_pos)
        
        let num_vertices = self._graph.len()
        
        let dist = [inf for i in range(num_vertices)]
        let pred = [None for i in range(num_vertices)]
        
        dist[src_node] = 0
        let todo = BinHeap[TupC[num?, nat?]](num_vertices, λ x, y: x[0] < y[0])
        let done = [None for i in range(num_vertices)]
        let done_nodes = 0
        
        todo.insert([0, src_node])
        while todo.len() != 0:
            let v = todo.find_min()
            todo.remove_min()
            let is_done = False
            for i in range(done.len()):
                if done[i] == v[1]:
                    is_done = True
                    break
            if not is_done:
                done[done_nodes] = v
                done_nodes = done_nodes + 1
                for i in range(self._graph.len()):
                    let w = self._graph.get_edge(v[1], i)
                    if w != None and dist[v[1]] + w < dist[i]:
                        dist[i] = dist[v[1]] + w
                        pred[i] = v[1]
                        todo.insert([dist[i], i])
        
        let total_dist = 0
        let cur_node = dst_node
        let path = None
        while cur_node != None:
            total_dist = total_dist + dist[cur_node]
            let cur_pos = self._node_id_to_pos.get(cur_node) 
            path = cons([cur_pos.lat, cur_pos.lon], path)
            cur_node = pred[cur_node]
            
        return Dijkstra(path, total_dist)
#   ^ YOUR WORK GOES HERE


def my_first_example():
    return TripPlanner([[0,0, 0,1], [0,0, 1,0]],
                       [[0,0, "bar", "The Empty Bottle"],
                        [0,1, "food", "Pierogi"]])

test 'My first locate_all test':
    assert my_first_example().locate_all("food") == \
        cons([0,1], None)
        
test 'locate_all with repeats and POIs not in segment endpoints':
    let t = TripPlanner([[0,0, 0,1], [0,0, 1,0]], [[0,0, "bar", "The Empty Bottle"], [0,1, "food", "Pierogi"], [0,1, "food", "Burritos"], [1,0, "food", "Tacos"], [2,2, "food", "Pizza"]])
    assert t.locate_all("food")

test 'My first plan_route test':
   assert my_first_example().plan_route(0, 0, "Pierogi") == \
       cons([0,0], cons([0,1], None))

test 'My first find_nearby test':
    assert my_first_example().find_nearby(0, 0, "food", 1) == \
        cons([0,1, "food", "Pierogi"], None)
