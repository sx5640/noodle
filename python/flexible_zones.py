import pylab
import numpy
import math
from scipy.optimize import curve_fit
from IPython import embed


###################### Define functions ######################

# def a function that calculate the number of articles in each zone
def count_articles(zone):
    total = 0
    i = zone['start_time']
    while i < zone['end_time']:
        total += y_data[i]
        i += 1
    return total


# defin a function that calculate the "hotness" of each zone
def calculate_hotness(zones, article_count, num_of_zones):
    hotness = []
    for i in range(num_of_zones):
        hotness.insert(i, article_count[i] / (zones[i]['end_time'] - zones[i]['start_time']))
    return math.fsum(hotness)

# define a function that moves the boundaries between zones, and compares the average count before and after moving
def move_boundary(zones, article_count, i, step, min_duration):
    direction = None
    done = False


    def before_and_after_move(zones, article_count, step):
        temp_zones = zones
        temp_count = article_count

        temp_zones[i] = {'start_time': zones[i]['start_time'], 'end_time': zones[i]['end_time'] + step}

        temp_zones[i+1] = {'start_time': zones[i+1]['start_time'] + step, 'end_time': zones[i+1]['end_time']}

        temp_count[i] = count_articles(temp_zones[i])
        temp_count[i+1] = count_articles(temp_zones[i+1])

        current_hotness = calculate_hotness(zones, article_count, num_of_zones)
        temp_hotness = calculate_hotness(temp_zones, temp_count, num_of_zones)

        return current_hotness, temp_hotness

    while (done == False) and (zones[i]['end_time'] - zones[i]['start_time'] > min_duration * step) and (zones[i+1]['end_time'] - zones[i+1]['start_time'] > min_duration * step):

        if direction == 'plus':
            current_hotness, temp_hotness_plus = before_and_after_move(zones, article_count, step)
            if temp_hotness_plus >= current_hotness:
                zones[i]['end_time'] += step
                zones[i+1]['start_time'] += step

                article_count[i] = count_articles(zones[i])
                article_count[i+1] = count_articles(zones[i+1])

                direction = 'plus'
            else:
                done = True
        elif direction == 'minus':
            current_hotness, temp_hotness_minus = before_and_after_move(zones, article_count, -step)
            if temp_hotness_minus >= current_hotness:
                zones[i]['end_time'] -= step
                zones[i+1]['start_time'] -= step

                article_count[i] = count_articles(zones[i])
                article_count[i+1] = count_articles(zones[i+1])

                direction = 'minus'
            else:
                done = True

        elif direction == None:
            current_hotness, temp_hotness_plus = before_and_after_move(zones, article_count, step)
            temp_hotness_minus = before_and_after_move(zones, article_count, -step)[1]

            if max(current_hotness, temp_hotness_minus, temp_hotness_plus) == temp_hotness_plus:
                zones[i]['end_time'] += step
                zones[i+1]['start_time'] += step

                article_count[i] = count_articles(zones[i])
                article_count[i+1] = count_articles(zones[i+1])

                direction = 'plus'
            elif max(current_hotness, temp_hotness_minus, temp_hotness_plus) == temp_hotness_minus:
                zones[i]['end_time'] -= step
                zones[i+1]['start_time'] -= step

                article_count[i] = count_articles(zones[i])
                article_count[i+1] = count_articles(zones[i+1])

                direction = 'minus'
            else:
                done = True

# define a function that moves all boundaries
def move_all_boundaries(zones, article_count, num_of_zones, step, min_duration):
    for i in range(num_of_zones - 1):
        move_boundary(zones, article_count, i, step, min_duration)


###################### Define initial variables ######################

# import data from txt file
x, y_data = numpy.loadtxt('trump_day.txt', delimiter='    ', unpack=True)

step = 1
min_duration = 2

# divide into 20 zones
zones = []
num_of_zones = 10
time_unit = float(len(y_data))/num_of_zones
article_count = []

for i in range(num_of_zones):
    zones.insert(i,{'start_time': int(numpy.ceil(time_unit * i)), 'end_time': int(numpy.ceil(time_unit * (i + 1)))})

    article_count.insert(i, count_articles(zones[i]))

###################### Start the program ######################

move_all_boundaries(zones, article_count, num_of_zones, step, min_duration)

print zones

###################### Define a ploting function ######################

def ploting_fun(x, zones, article_count):
    for i in range(num_of_zones):
        if x in range(zones[i]["start_time"], zones[i]["end_time"]):
            return article_count[i] / (zones[i]["end_time"] - zones[i]["start_time"])
y = []


for i in x:
    y.insert(int(i), ploting_fun(i, zones, article_count))

###################### plot the graph ######################
pylab.plot(x,y_data, x, y)
pylab.grid()
# Add error bars on data as red crosses.
pylab.show()
