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
    
    def __init__(self, segs: VecC[RawSeg?], POIs: VecC[RawPOI?]):
        let unique_pos_count
        self._pos_to_node_id = HashTable(32, make_sbox_hash())
        self._node_id_to_pos = HashTable(32, make_sbox_hash())
        for seg in segs:
            let modified_seg = Seg(Pos(seg[0], seg[1]), Pos(seg[2], seg[3]))
            unique_pos_count = self._pos_to_node_id.len()
            for pos in [modified_seg.a, modified_seg.b]:
                if not self._pos_to_node_id.mem?(pos):
                    unique_pos_count = unique_pos_count + 1
                    self._pos_to_node_id.put(pos, unique_pos_count)
                    self._node_id_to_pos.put(unique_pos_count, pos)
        
        self._graph = WUGraph(self._pos_to_node_id.len())    
        
        # initialize names and cats dicts
        self._names_dict = HashTable(32, make_sbox_hash())
        self._cats_dict = HashTable(32, make_sbox_hash())
        for POI in POIs:
            let modified_POI = POI(Pos(POI[0], POI[1]), POI[3], POI[2])
            self._names_dict.put(modified_POI.name, modified_POI)
            self._cats_dict.put(modified_POI.cat, modified_POI)
        
    #
    # locate_all
    #
        
    def locate_all(
            self,
            dst_cat:  Cat?           # point-of-interest category
        )   ->        ListC[RawPos?]: # positions of the POIs
            pass

    #
    # plan_route
    #
            
    def plan_route(
            self,
            src_lat:  Lat?,          # starting latitude
            src_lon:  Lon?,          # starting longitude
            dst_name: Name?          # name of goal
        )   ->        ListC[RawPos?]: # path to goal
            pass

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
            pass
#   ^ YOUR WORK GOES HERE


def my_first_example():
    return TripPlanner([[0,0, 0,1], [0,0, 1,0]],
                       [[0,0, "bar", "The Empty Bottle"],
                        [0,1, "food", "Pierogi"]])

test 'My first locate_all test':
    assert my_first_example().locate_all("food") == \
        cons([0,1], None)

test 'My first plan_route test':
   assert my_first_example().plan_route(0, 0, "Pierogi") == \
       cons([0,0], cons([0,1], None))

test 'My first find_nearby test':
    assert my_first_example().find_nearby(0, 0, "food", 1) == \
        cons([0,1, "food", "Pierogi"], None)
