import pylab
import numpy
import math
from scipy.optimize import curve_fit

# import data from txt file
x, y_data = numpy.loadtxt('data.txt', delimiter='    ', unpack=True)

# divide into 20 zones
zones = []
num_of_zones = 20
time_unit = (zones[len(zones)-1]+1)/20
for i in range(num_of_zones):
    zones[i] = {'start_time': time_unit * i, 'end_time': time_unit * (i + 1)}

article_count = []

# def a function that calculate the number of articles in each zone
def count_articles(zone):
    total = 0
    i = numpy.ceil(zones['start_time'])
    while i < zones['end_time']:
        total += y_data[i]
        i += 1
    return total

# defin a function that calculate the "hotness" of each zone
def calculate_hotness(article_count, zones):
    hotness = []
    for i in range(num_of_zones):
        hotness[i] = article_count[i] / (zones[i]['end_time'] - zones[i]['start_time'])
    return math.fsum(hotness)

# define a function that moves the boundaries between zones, and compares the average count before and after moving
def move_boundary(i):
    direction = None
    done = False
    temp_count = article_count

    def 

    while done == False and zones[i]['end_time'] - zones[i]['start_time'] >= 3:
        if direction = 'plus':
            temp_zone_before = {'start_time': zone[i]['start_time'], 'end_time': zone[i]['end_time'] + 3}
            temp_zone_after = {'start_time': zone[i]['start_time'] + 3, 'end_time': zone[i]['end_time']}
        elif direction = 'minus':


    temp_count_minus = article_count

# define a function that moves all boundaries

def move_all_boundaries(zones):
    for i in range(num_of_zones - 1):
        move_boundary(i)

# plot the graph
pylab.plot(x,y_data)
pylab.grid()
# Add error bars on data as red crosses.
pylab.show()
