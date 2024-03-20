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
    
### Return Type for Pathfinder Algos (Dijkstra and Bellman-Ford) ###
    
struct PathDist:
    let path: List?
    let dist: VecC[num?]
    
### Buckets in Hash Tables ###
    
let NBUCKETS = 100

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
        self._pos_to_node_id = HashTable(NBUCKETS, make_sbox_hash())
        self._node_id_to_pos = HashTable(NBUCKETS, make_sbox_hash())
        
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
            # convert raw Seg to a Seg struct representation
            let modified_seg = Seg(Pos(seg[0], seg[1]), Pos(seg[2], seg[3]))
            
            # set edge between endpoints of given Seg
            # edge weight is Euclidean distance
            self._graph.set_edge(self._pos_to_node_id.get(modified_seg.a),
                                 self._pos_to_node_id.get(modified_seg.b),
                                 self._dist(modified_seg.a, modified_seg.b))
        
        # initialize names and cats dicts
        # bucket count is twice the number of unique positions to  
        self._names_dict = HashTable(NBUCKETS, make_sbox_hash())
        self._cats_dict = HashTable(NBUCKETS, make_sbox_hash())
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
            # return empty linked list if given category not among POIs
            if not self._cats_dict.mem?(dst_cat):
                return None
            else:
                let cur = self._cats_dict.get(dst_cat)
                let result = None
                while cur != None:
                    if (not self._pos_in(cur.data.pos, result)):
                        result = cons([cur.data.pos.lat, cur.data.pos.lon], result)
                    cur = cur.next
                return result
    
    # helper function to check if given position is not already in a Cons list of raw positions
    def _pos_in(self, pos: Pos?, list: Cons.ListC[RawPos?]) -> bool?:
        let cur = list
        # iterate through list
        while cur != None:
            # if match found
            if pos.lat == cur.data[0] and pos.lon == cur.data[1]:
                return True
            cur = cur.next
        
        # reaching here means position was not already in list of raw positions
        return False
    
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
            # if destination POI not in database
            if not self._names_dict.mem?(dst_name):
                return None
            else:
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
            struct Dest:
                let poi: POI?
                let dist: num?
            
            let src_pos = Pos(src_lat, src_lon)
            
            # no POIs in given category
            if not self._cats_dict.mem?(dst_cat):
                return None
            let dsts = self._cats_dict.get(dst_cat)
            
            # sort dsts into binary heap ordered by distance
            let dsts_hp = BinHeap[Dest?](Cons.len(dsts), λ x, y: x.dist < y.dist)
            
            # get distances to all nodes using a pathfinding algorithm
            let dist_vec = self._dijkstra(src_pos, dsts.data.pos).dist
            
            # add all relevant POIs to min-heap by distance
            let cur = dsts
            while cur != None:
                let cur_node_id = self._pos_to_node_id.get(cur.data.pos)
                let cur_dist = dist_vec[cur_node_id]
                dsts_hp.insert(Dest(cur.data, cur_dist))
                cur = cur.next
                    
            # output n closest POIs
            let results = None
            for i in range(n):
                
                if dsts_hp.len() > 0:
                    let dst = dsts_hp.find_min()
                    # binheap min is now an unreachable node
                    # so, next min will also be unreachable, and so on
                    # break out of loop
                    if dst.dist == inf:
                        break
                    let dst_poi = dst.poi
                    dsts_hp.remove_min()
                    results = cons([dst_poi.pos.lat, dst_poi.pos.lon, dst_poi.cat, dst_poi.name], results)
                else:
                    break
            
            # sort from nearest to farthest
            results = Cons.rev(results)
            return results
    #
    # _dist
    # helper function to return Euclidean distance between two given positions      
    #          
    def _dist(self, a: Pos?, b: Pos?) -> num?:
         return ((a.lat - b.lat)**2+(a.lon - b.lon)**2).sqrt()
    #
    # _bellmanford
    # helper function to return shortest path and distance between two given positions using Bellman-Ford     
    #     
    def _bellmanford(self, src_pos: Pos?, dst_pos: Pos?) -> PathDist?:
            # nonexistent src or dst
            if not self._pos_to_node_id.mem?(src_pos) or not self._pos_to_node_id.mem?(dst_pos):
                return PathDist(None, [inf])
        
            # getting src and dst node ids
            let src_node = self._pos_to_node_id.get(src_pos)
            let dst_node = self._pos_to_node_id.get(dst_pos)
        
            # initialization
            let num_vertices = self._graph.len()
            let dist: VecC[num?] = [inf for i in range(num_vertices)]
            let pred: VecC[OrC(nat?, NoneC)] = [None for i in range(num_vertices)]
        
            # src node is 0 distance away from src node
            dist[src_node] = 0
        
            # bellman-fording
            for i in range(num_vertices-1):
                let edges = self._graph.get_all_edges()
                edges = Cons.to_vec(edges)
                for edge in edges:
                    let u = edge.u
                    let v = edge.v
                    let w = edge.w
                    if dist[v] + w < dist[u]:
                        dist[u] = dist[v] + w
                        pred[u] = v
                    if dist[u] + w < dist[v]:
                        dist[v] = dist[u] + w
                        pred[v] = u
                         
            # finding path between src node and dst node
            let cur_node = pred[dst_node]
            let path = None
            while cur_node != None:
                let cur_pos = self._node_id_to_pos.get(cur_node) 
                path = cons([cur_pos.lat, cur_pos.lon], path)
                cur_node = pred[cur_node]
        
            # if path exists
            if path != None:
                # add dst to end of path
                path = Cons.app(path, cons([dst_pos.lat, dst_pos.lon], None))
        
            return PathDist(path, dist)
    
         
    #
    # _dijkstra
    # helper function to return shortest path and distance between two given positions using Dijkstra's      
    #     
    def _dijkstra(self, src_pos: Pos?, dst_pos: Pos?) -> PathDist?:
        struct vert:
            let dist: num?
            let node: nat?
    
        # nonexistent src or dst
        if not self._pos_to_node_id.mem?(src_pos) or not self._pos_to_node_id.mem?(dst_pos):
            return PathDist(None, [inf])
    
        # getting src and dst node ids
        let src_node = self._pos_to_node_id.get(src_pos)
        let dst_node = self._pos_to_node_id.get(dst_pos)
    
        # initialization
        let num_vertices = self._graph.len()
        let dist: VecC[num?] = [inf for i in range(num_vertices)]
        let pred: VecC[OrC(nat?, NoneC)] = [None for i in range(num_vertices)]
    
        # src node is 0 distance away from src node
        dist[src_node] = 0
            
        # binheap of nodes with their dists
        let todo = BinHeap[vert?](num_vertices * 2, λ x, y: x.dist < y.dist)
        let done = [False for i in range(num_vertices)]
    
        # finding path between src node and dst node
        todo.insert(vert(0, src_node))
        while todo.len() != 0:
            # pop min from todo heap
            let v = todo.find_min()
            todo.remove_min()
        
            if not done[v.node]:
                done[v.node] = True
                let adjs = self._graph.get_adjacent(v.node)
                let cur = adjs
                while cur != None:
                    let i = cur.data
                    cur = cur.next
                    # slight optimization:
                    # if done[i]:
                        # continue
                    
                    let w = self._graph.get_edge(v.node, i)
                    let new_dist = dist[v.node] + w
                    if new_dist < dist[i]:
                        dist[i] = new_dist
                        pred[i] = v.node
                        todo.insert(vert(dist[i], i))
                    
                     
        # finding path between src node and dst node
        let cur_node = pred[dst_node]
        let path = None
        while cur_node != None:
            let cur_pos = self._node_id_to_pos.get(cur_node) 
            path = cons([cur_pos.lat, cur_pos.lon], path)
            cur_node = pred[cur_node]
    
        # if path exists
        if path != None:
            # add dst to end of path
            path = Cons.app(path, cons([dst_pos.lat, dst_pos.lon], None))
    
        return PathDist(path, dist)
#   ^ YOUR WORK GOES HERE
        
# reimplementing grading report tests
            
test 'gr1':
    let tp = TripPlanner(
      [[0, 0, 1, 0]],
      [[1, 0, 'bank', 'Union']])
    let result = tp.locate_all('food')
    result = Cons.to_vec(result)
    assert result == []
    
test 'gr2':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy'],
       [5, 0, 'barber', 'Lily']])
    let result = tp.locate_all('barber')
    result = Cons.to_vec(result)
    assert result == [[3, 0], [5, 0]]

test 'gr3':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony']])
    let result = tp.plan_route(0, 0, 'Judy')
    result = Cons.to_vec(result)
    assert result == []

test 'gr4':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.plan_route(0, 0, 'Judy')
    result = Cons.to_vec(result)
    assert result == []
  
test 'gr5':
    let tp = TripPlanner(
      [[0, 0, 0, 9],
       [0, 9, 9, 9],
       [0, 0, 1, 1],
       [1, 1, 2, 2],
       [2, 2, 3, 3],
       [3, 3, 4, 4],
       [4, 4, 5, 5],
       [5, 5, 6, 6],
       [6, 6, 7, 7],
       [7, 7, 8, 8],
       [8, 8, 9, 9]],
      [[7, 7, 'haberdasher', 'Archit'],
       [8, 8, 'haberdasher', 'Braden'],
       [9, 9, 'haberdasher', 'Cem']])
    let result = tp.plan_route(0, 0, 'Cem')
    result = Cons.to_vec(result)
    assert result == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9]]
    
test 'gr6':
    let tp = TripPlanner(
      [[0, 0, 0, 1],
       [0, 1, 3, 0],
       [0, 1, 4, 0],
       [0, 1, 5, 0],
       [0, 1, 6, 0],
       [0, 0, 1, 1],
       [1, 1, 3, 0],
       [1, 1, 4, 0],
       [1, 1, 5, 0],
       [1, 1, 6, 0],
       [0, 0, 2, 1],
       [2, 1, 3, 0],
       [2, 1, 4, 0],
       [2, 1, 5, 0],
       [2, 1, 6, 0]],
      [[0, 0, 'blacksmith', "Revere's Silver Shop"],
       [6, 0, 'church', 'Old North Church']])
    let result = tp.plan_route(0, 0, 'Old North Church')
    result = Cons.to_vec(result)
    assert result == [[0, 0], [2, 1], [6, 0]]
    
test 'gr7':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [4, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(0, 0, 'barber', 2)
    result = Cons.to_vec(result)
    assert result == [[3, 0, 'barber', 'Tony']]
    
test 'gr8':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(0, 0, 'food', 1)
    result = Cons.to_vec(result)
    assert result == []
    
test 'gr9':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [4, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(0, 0, 'food', 1)
    result = Cons.to_vec(result)
    assert result == []
    
test 'gr10':
    let tp = TripPlanner(
      [[0, 0, 0, 9],
       [0, 9, 9, 9],
       [0, 0, 1, 1],
       [1, 1, 2, 2],
       [2, 2, 3, 3],
       [3, 3, 4, 4],
       [4, 4, 5, 5],
       [5, 5, 6, 6],
       [6, 6, 7, 7],
       [7, 7, 8, 8],
       [8, 8, 9, 9]],
      [[7, 7, 'haberdasher', 'Archit'],
       [8, 8, 'haberdasher', 'Braden'],
       [9, 9, 'haberdasher', 'Cem']])
    let result = tp.find_nearby(0, 0, 'haberdasher', 2)
    result = Cons.to_vec(result)
    assert result == [[7, 7, 'haberdasher', 'Archit'], [8, 8, 'haberdasher', 'Braden']]
    
    
test 'gr11':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [4, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(0, 0, 'barber', 3)
    result = Cons.to_vec(result)
    assert result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Judy']]
    
test 'gr12':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy'],
       [5, 0, 'barber', 'Lily']])
    let result = tp.find_nearby(0, 0, 'barber', 2)
    result = Cons.to_vec(result)
    assert result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Judy']] \
      or result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Lily']]
                      
test 'gr13':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [0, 0, 'barber', 'Lily'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(2.5, 0, 'barber', 2)
    result = Cons.to_vec(result)
    assert result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Judy']] \
      or result == [[3, 0, 'barber', 'Tony'], [0, 0, 'barber', 'Lily']]
  
test 'gr14':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy'],
       [5, 0, 'bar', 'Pasta']])
    let result = tp.find_nearby(0, 0, 'barber', 2)
    result = Cons.to_vec(result)
    assert result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Judy']]
  
# all tests
    
let N_ELEMS = 45
time 'initialization stress with N_ELEMS = %p'.format(N_ELEMS):
    let segs = [None for i in range(N_ELEMS)]
    let pois = [None for i in range(N_ELEMS)]
    for i in range(N_ELEMS):
        segs[i] = [i, i, i+1, i+1]
        pois[i] = [i, i, "coffee", "Starbucks #%p".format(i + 1)]
    
    let t = TripPlanner(segs, pois)
        
time 'full stress with N_ELEMS = %p'.format(N_ELEMS):
    let segs = [None for i in range(N_ELEMS)]
    let pois = [None for i in range(N_ELEMS)]
    for i in range(N_ELEMS):
        segs[i] = [i, i, i+1, i+1]
        pois[i] = [i, i, "coffee", "Starbucks #%p".format(i + 1)]
    
    let t = TripPlanner(segs, pois)
    let result = t.find_nearby(0, 0, "coffee", 1)
    result = Cons.to_vec(result)

test 'grading report: find_nearby stress test':
    time 'stress test time':
        let N_ELEMS = 1
        let segs = [None for i in range(N_ELEMS)]
        let pois = [None for i in range(N_ELEMS)]
        for i in range(N_ELEMS):
            segs[i] = [i, i, i+1, i+1]
            pois[i] = [i, i, "coffee", "Starbucks #%p".format(i + 1)]
        
        let t = TripPlanner(segs, pois)
        let result = t.find_nearby(0, 0, "coffee", 1)
        result = Cons.to_vec(result)
        assert result == [[0, 0, "coffee", "Starbucks #1"]]

test 'grading report: find_nearby POI is 2nd of 3 in that location':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy'],
       [5, 0, 'bar', 'Pasta']])
    let result = tp.find_nearby(0, 0, 'barber', 2)
    result = Cons.to_vec(result)
    assert result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Judy']]
        
test 'grading report: find_nearby 3 relevant POIs; farther 2 equidistant; limit 2':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [0, 0, 'barber', 'Lily'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(2.5, 0, 'barber', 2)
    result = Cons.to_vec(result)
    assert result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Judy']] \
      or result == [[3, 0, 'barber', 'Tony'], [0, 0, 'barber', 'Lily']]
        
test 'grading report: find_nearby 3 relevant POIs; farther 2 at same location; limit 2':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy'],
       [5, 0, 'barber', 'Lily']])
    let result = tp.find_nearby(0, 0, 'barber', 2)
    result = Cons.to_vec(result)
    assert result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Judy']] \
      or result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Lily']]      
        
test 'grading report: find_nearby BFS is not SSSP (nearby)':
    let tp = TripPlanner(
      [[0, 0, 0, 9],
       [0, 9, 9, 9],
       [0, 0, 1, 1],
       [1, 1, 2, 2],
       [2, 2, 3, 3],
       [3, 3, 4, 4],
       [4, 4, 5, 5],
       [5, 5, 6, 6],
       [6, 6, 7, 7],
       [7, 7, 8, 8],
       [8, 8, 9, 9]],
      [[7, 7, 'haberdasher', 'Archit'],
       [8, 8, 'haberdasher', 'Braden'],
       [9, 9, 'haberdasher', 'Cem']])
    let result = tp.find_nearby(0, 0, 'haberdasher', 2)
    result = Cons.to_vec(result)
    # order doesn't matter for find_nearby
    assert result == [[7, 7, 'haberdasher', 'Archit'], [8, 8, 'haberdasher', 'Braden']] or result == [[8, 8, 'haberdasher', 'Braden'], [7, 7, 'haberdasher', 'Archit']]

test 'grading report: find_nearby 2 relevant POIs; limit 3':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0],
       [3, 0, 4, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [4, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(0, 0, 'barber', 3)
    result = Cons.to_vec(result)
    assert result == [[5, 0, 'barber', 'Judy'], [3, 0, 'barber', 'Tony']] or result == [[3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Judy']]
            
test 'grading report: find_nearby relevant POI isn\'t reachable':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [4, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(0, 0, 'food', 1)
    result = Cons.to_vec(result)
    assert result == []
        
test 'grading report: find_nearby No POIs in requested category':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(0, 0, 'food', 1)
    result = Cons.to_vec(result)
    assert result == []

        
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

test 'grading report: locate_all with no POI':
    let t = TripPlanner([[0, 0, 1, 0]], [])
    let result = t.locate_all("bank")
    assert result == None
    result = Cons.to_vec(result)
    assert result == [] 
    
test 'grading report: locate_all with single POI, wrong category':
    let t = TripPlanner([[0, 0, 1, 0]], [[1, 0, "bank", "Union"]])
    let result = t.locate_all("food")
    assert result == None
    result = Cons.to_vec(result)
    assert result == []
    
test 'grading report: locate_all with 3 relevant POIs, 2 at same location':
    let t = TripPlanner([[0, 0, 1.5, 0], [1.5, 0, 2.5, 0], [2.5, 0, 3, 0], [4, 0, 5, 0], [3, 0, 4, 0]], [[1.5, 0, 'bank', 'Union'], [3, 0, 'barber', 'Tony'], [5, 0, 'barber', 'Judy'], [5, 0, 'barber', 'Lily']])
    let result = t.locate_all("barber")
    # sort in increasing order of latitudes
    result = Cons.to_vec(Cons.sort(λ x, y: x[0] < y[0], result))
    assert result == [[3, 0], [5, 0]]
   
    
test 'instructor\'s test':
    assert my_first_example().plan_route(0, 0, "Pierogi") == \
       cons([0,0], cons([0,1], None))

test 'grading report: plan_route with nonexistent destination':
    let t = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony']])  
    let result = t.plan_route(0, 0, "Judy")
    assert result == None
    result = Cons.to_vec(result)
    assert result == []

test 'plan_route with destination one node away':
    let t = TripPlanner([[0, 0, 1, 0]], [[1, 0, "food", "Blaze"]])
    let result = t.plan_route(0, 0, "Blaze")
    result = Cons.to_vec(result)
    assert result == [[0, 0], [1, 0]]

test 'plan_route with destination two nodes away':
    let t = TripPlanner([[0, 0, 1, 0], [1, 0, 2, 0]], [[2, 0, "food", "Blaze"], [1, 0, "food", "Mod"]])
    let result = t.plan_route(0, 0, "Blaze")
    result = Cons.to_vec(result)
    assert result == [[0, 0], [1, 0], [2, 0]]    

test 'plan_route with nonexistent destination':
    let t = TripPlanner([[0,0, 0,1], [0,0, 1,0]], [[0,0, "bar", "The Empty Bottle"], [0,1, "food", "Pierogi"], [0,1, "food", "Burritos"], [1,0, "food", "Tacos"], [2,2, "food", "Pizza"]])
    assert t.plan_route(0,0,"Dosas") == None
    
test 'grading report: plan_route with unreachable destination':
    let t = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [5, 0, 'barber', 'Judy']])
    let result = t.plan_route(0, 0, 'Judy')
    result = Cons.to_vec(result)
    assert result == []
    
test 'plan_route with destination unconnected to any positions':
    let t = TripPlanner([[0, 0, 1, 0]], [[2, 0, "food", "Tacos"]])
    let result = t.plan_route(0, 0, "Tacos")
    assert result == None
    result = Cons.to_vec(result)
    assert result == []

test 'plan_route with destination unreachable but connected to another position':
    let t = TripPlanner([[0, 0, 1, 0], [2, 0, 3, 0]], [[3, 0, "food", "Tacos"]])
    let result = t.plan_route(0, 0, "Tacos")
    result = Cons.to_vec(result)
    assert result == []
    
test 'plan_route with destination unreachable but connected to other positions':
    let t = TripPlanner([[0, 0, 1, 0], [2, 0, 3, 0], [2, 0, 2, 1], [3, 0, 3, 1]], [[3, 0, "food", "Tacos"]])
    let result = t.plan_route(0, 0, "Tacos")
    result = Cons.to_vec(result)
    assert result == []
    
test 'plan_route with unreachable destination':
    let t = TripPlanner([[0,0, 0,1], [0,0, 1,0]], [[0,0, "bar", "The Empty Bottle"], [0,1, "food", "Pierogi"], [0,1, "food", "Burritos"], [1,0, "food", "Tacos"], [2,2, "food", "Pizza"]])
    assert t.plan_route(0,0,"Pizza") == None
    assert t.plan_route(-1,-1, "The Empty Bottle") == None
    assert t.plan_route(-1,-1, "Pizza") == None

test 'plan_route where BFS is not SSSP (3)':
    let t = TripPlanner([[0, 0, 0, 3], [0, 3, 3, 3], [0, 0, 1, 1], [1, 1, 2, 2], [2, 2, 3, 3]], [[1.5, 1.5, "food", "Domino's"], [2, 2, "food", "Mod"], [3, 3, "food", "Blaze"]])
    let result = t.plan_route(0, 0, "Blaze")
    result = Cons.to_vec(result)
    assert result == [[0, 0], [1, 1], [2, 2], [3, 3]]

test 'plan_route where BFS is not SSSP (4)':
    let t = TripPlanner([[0, 0, 0, 4], [0, 4, 4, 4], [0, 0, 1, 1], [1, 1, 2, 2], [2, 2, 3, 3], [3, 3, 4, 4]], [[1.5, 1.5, "food", "Domino's"], [2, 2, "food", "Mod"], [4, 4, "food", "Blaze"]])
    let result = t.plan_route(0, 0, "Blaze")
    result = Cons.to_vec(result)
    assert result == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4]]    

test 'grading report: plan_route where BFS is not SSSP (9)':
    let tp = TripPlanner(
      [[0, 0, 0, 9],
       [0, 9, 9, 9],
       [0, 0, 1, 1],
       [1, 1, 2, 2],
       [2, 2, 3, 3],
       [3, 3, 4, 4],
       [4, 4, 5, 5],
       [5, 5, 6, 6],
       [6, 6, 7, 7],
       [7, 7, 8, 8],
       [8, 8, 9, 9]],
      [[7, 7, 'haberdasher', 'Archit'],
       [8, 8, 'haberdasher', 'Braden'],
       [9, 9, 'haberdasher', 'Cem']])
    let result = tp.plan_route(0, 0, 'Cem')
    assert Cons.len(result) == 10
    result = Cons.to_vec(result)
    assert result == [[0, 0], [1, 1], [2, 2], [3, 3], [4, 4], [5, 5], [6, 6], [7, 7], [8, 8], [9, 9]]
    
test 'grading report: plan_route where BinHeap needs capacity > |V|)':
    let tp = TripPlanner(
      [[0, 0, 0, 1],
       [0, 1, 3, 0],
       [0, 1, 4, 0],
       [0, 1, 5, 0],
       [0, 1, 6, 0],
       [0, 0, 1, 1],
       [1, 1, 3, 0],
       [1, 1, 4, 0],
       [1, 1, 5, 0],
       [1, 1, 6, 0],
       [0, 0, 2, 1],
       [2, 1, 3, 0],
       [2, 1, 4, 0],
       [2, 1, 5, 0],
       [2, 1, 6, 0]],
      [[0, 0, 'blacksmith', "Revere's Silver Shop"],
       [6, 0, 'church', 'Old North Church']])
    let result = tp.plan_route(0, 0, 'Old North Church')
    result = Cons.to_vec(result)
    assert result == [[0, 0], [2, 1], [6, 0]] 
    
test 'plan_route to assess grading report test below':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [4, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy']])
    let results = tp.plan_route(0, 0, "Judy")
    results = Cons.to_vec(results)
    assert results == []

test 'grading report: find_nearby with 2 relevant POIs; 1 reachable':
    let tp = TripPlanner(
      [[0, 0, 1.5, 0],
       [1.5, 0, 2.5, 0],
       [2.5, 0, 3, 0],
       [4, 0, 5, 0]],
      [[1.5, 0, 'bank', 'Union'],
       [3, 0, 'barber', 'Tony'],
       [4, 0, 'food', 'Jollibee'],
       [5, 0, 'barber', 'Judy']])
    let result = tp.find_nearby(0, 0, 'barber', 2)
    # sort POIs by latitude
    result = Cons.to_vec(Cons.sort(λ x, y: x[0] < y[0], result))
    assert result == [[3, 0, 'barber', 'Tony']]
    
test 'My first find_nearby test':
    assert my_first_example().find_nearby(0, 0, "food", 1) == \
        cons([0,1, "food", "Pierogi"], None)       