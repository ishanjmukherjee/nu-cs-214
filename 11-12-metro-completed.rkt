#lang dssl2

import cons
import sbox_hash
import 'project-lib/dictionaries.rkt'
import 'project-lib/graph.rkt'
import 'project-lib/binheap.rkt'

# Data-wise, let's keep things simple:
# - Raw input format: csv-like (spreadsheet)
# - Small data set

# name, founded, population, area, state
let city_data = \
    [['Chicago', 1780, 2705994, 227.63, "IL"],
     ['Evanston', 1872, 74486, 7.80, "IL"],
     ['Skokie', 1888, 64784, 10.06, "IL"],
     ['Oak Park', 1902, 51878, 4.70, "IL"],
     ['Cicero', 1867, 83895, 5.87, "IL"],
     ['Gary', 1906, 80294, 57.21, "IN"],
     ['Orland Park', 1892, 56767, 22.27, "IL"],
     ['Waukegan', 1829, 89078, 24.50, "IL"],
     ['Wilmette', 1872, 27087, 5.41, "IL"],
     ['Wheaton', 1831, 52894, 11.48, "IL"],
     ['Naperville', 1831, 141853, 39.24, "IL"],
     ['Aurora', 1834, 197899, 45.77, "IL"],
     ['Joliet', 1833, 147433, 65.09, "IL"],
     ['Kenosha', 1835, 99218, 27.99, "WI"],
     ['Racine', 1834, 78860, 15.66, "WI"],
     ['Milwaukee', 1846, 592025, 96.82, "WI"],
     ['Waukesha', 1834, 70718, 25.07, "WI"],
     ['Menomonee Falls', 1870, 35626, 33.30, "WI"]]

# city1, city2, distance in miles
let road_data = \
    [['Chicago', 'Evanston', 13.7],
     ['Chicago', 'Skokie', 14.4],
     ['Chicago', 'Oak Park', 9.1],
     ['Chicago', 'Cicero', 8.5],
     ['Chicago', 'Gary', 29.4],
     ['Chicago', 'Orland Park', 27.5],
     ['Evanston', 'Waukegan', 29.5],
     ['Evanston', 'Skokie', 3.5],
     ['Evanston', 'Wilmette', 3.3],
     ['Oak Park', 'Wheaton', 21.3],
     ['Wheaton', 'Naperville', 10.3],
     ['Wheaton', 'Aurora', 18.3],
     ['Naperville', 'Aurora', 10.3],
     ['Orland Park', 'Joliet', 19.7],
     ['Waukegan', 'Kenosha', 16.0],
     ['Kenosha', 'Racine', 10.6],
     ['Racine', 'Milwaukee', 24.8],
     ['Milwaukee', 'Waukesha', 19.5],
     ['Milwaukee', 'Menomonee Falls', 20.6]]
     
#Read in raw city data and put them into structs and then 
#store each city struct in the dictionary against its name 
#OR store all structs in an array
struct city:
    let name
    let pop
    
# need map of city name to node ID
let n_cities = city_data.len()
let cities = HashTable(n_cities, make_sbox_hash())
let cities_to_node_IDs = HashTable(n_cities, make_sbox_hash())
let node_IDs_to_cities = [None; n_cities]
for i, c in city_data:
    let this_city = city(c[0], c[2])
    cities.put(this_city.name, this_city)
    cities_to_node_IDs.put(this_city.name, i)
    node_IDs_to_cities[i] = this_city.name
     
#Read in raw road city, build a WU graph, set all the edges according to the road data and add weights according to the length
let road_graph = WUGraph(n_cities)
for r in road_data:
    let city1 = cities_to_node_IDs.get(r[0])
    let city2 = cities_to_node_IDs.get(r[1])
    let length = r[2]
    road_graph.set_edge(city1, city2, length)
    
    
#For every city in our dataset, maintain a metro struct. Find all that city’s neighbors in the graph, identify if their population is lower, and if so, store as part of the member cities for that metro struct
#For every member city in a metro, compute total population
struct metro:
    let name
    let members
    let total_pop
    
let all_metros = [None; n_cities]
for i, c in city_data:
    # put the data into a metro struct
    let city_name = c[0]
    let city = cities.get(city_name) #gets the city struct
    let this_metro = metro(city.name, cons(city_name, None), city.pop)
    
    # find node in graph, find its adjacents, check populations
    let city_node = cities_to_node_IDs.get(city_name)
    let neighbors = road_graph.get_adjacent(city_node)
    let curr = neighbors
    while curr is not None:
        let neighbor = curr.data
        #println("This neighbor: %p", neighbor)
        let neighbor_name = node_IDs_to_cities[neighbor]
        let neighbor_struct = cities.get(neighbor_name)
        println("This neighbor name: %p", neighbor_struct)
        
        if neighbor_struct.pop < city.pop:
            # add it to the metro linked list
            this_metro.members = cons(neighbor_name, this_metro.members)
            
            # add population to total population
            this_metro.total_pop = this_metro.total_pop + neighbor_struct.pop
            
        curr = curr.next
    all_metros[i] = this_metro
    
test 'created metros correctly':
    for i, m in all_metros:
        assert m.name == city_data[i][0]
        
# much better test: identify members and total populations and test values of
# metro structs
        
# Goal 2: Given the above set of metro areas identified above, for a given n, determine the 𝑛 
#most populated metro areas by the total population across all the cities in the metro area
        
# Sort the all_metros array according to total_population and take the first n
def get_n_most_pop(metros, n):
    let largest_metros = [None; n]
    heap_sort(metros, lambda m1, m2: return m1.total_pop > m2.total_pop)
    
    for i in range(n):
        # extract metros[i]
        largest_metros[i] = metros[i]
        
    return largest_metros

test 'largest_metros':
    let top_5 = get_n_most_pop(all_metros, 5)
    assert top_5[0].name == "Chicago"
    assert top_5[0].total_pop == 3118098
    
    assert top_5[1].name == "Milwaukee"
    assert top_5[1].total_pop == 777229
    
    assert top_5[2].name == "Aurora"
    assert top_5[2].total_pop == 392646
    
    assert top_5[3].name == "Kenosha"
    assert top_5[3].total_pop == 267156
    
    assert top_5[4].name == "Joliet"
    assert top_5[4].total_pop == 204200