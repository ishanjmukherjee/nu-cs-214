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
