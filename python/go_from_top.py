import pylab
import numpy
import math
from scipy.optimize import curve_fit
import pdb
import datetime

###################### Go From Top ######################

# find the top

def find_top(data):
    data_temp = list(data)
    top_value = max(data)
    top_index = data.index(top_value)

    if top_value > 3 * y_average:
        start_index = move_boundary(top_index, -step/2, step)
        end_index = move_boundary(top_index, step, step)

        zones.append({'start_index': start_index, 'end_index': end_index, 'top_value': top_value})

        for i in range(start_index, end_index + 1):
            data_not_zoned[i] = 'stop'
            data_temp[i] = 0

        find_top(data_temp)

    # else:
        # i = 0
        # while i in range(data_size):
        #     if data_not_zoned[i] == 'stop':
        #         i += 1
        #     else:
        #         start_index = i
        #
        #         if 'stop' in data_not_zoned[i: data_size]:
        #             end_index = i + data_not_zoned[i: data_size].index('stop')
        #         else:
        #             end_index = data_size
        #
        #         print start_index, end_index
        #         print data[start_index: end_index]
        #         top_value_temp = max(data[start_index: end_index])
        #
        #         zones.append({'start_index': start_index, 'end_index': end_index, 'top_value': top_value_temp})
        #
        #         i = end_index + 1

# define a function that move the boundary and see if the slop it is downward over all
def move_boundary(top_index, move_by, step):
    direction = move_by / abs(move_by)

    if top_index + move_by >= data_size - 1:
        return data_size - 1

    if 'stop' in data_not_zoned[top_index: top_index + move_by + direction: direction]:
        return top_index + direction*data_not_zoned[top_index: top_index + move_by + direction: direction].index('stop')

    elif top_index + move_by <=0:
        return 0

    elif top_index + move_by >= data_size - 1:
        return data_size - 1

    else:
        selected_indices = range(top_index + move_by - direction * step, top_index + move_by + direction, direction)

        selected_indices.sort()

        selected_indices.pop()

        selected_first_difference = []

        for i in range(0, len(selected_indices)):
            selected_first_difference.append(first_difference[selected_indices[i]])

        first_difference_average = numpy.average(selected_first_difference)

        if first_difference_average == 0:
            next_direction = 0
        else:
            next_direction = int(first_difference_average / abs(first_difference_average))

        if direction * next_direction == -1:
            return move_boundary(top_index, move_by + direction * step, step)
        elif direction * next_direction == 1 or next_direction == 0:
            if abs(step) == 1:
                return top_index + move_by

            else:
                return move_boundary(top_index, move_by + next_direction + step*direction/2, step / 2)


###################### Initialize the program ######################

# import data from txt file
x, y_data = numpy.loadtxt('elon musk_2week.txt', delimiter='    ', unpack=True)

y_data = tuple(y_data)
data_size = len(y_data)
y_average = numpy.average(y_data)

start_date = datetime.date(2013,01,13)
duration = datetime.timedelta(days =4)
time = []
for i in range(0, data_size):
    time.append(start_date + i*duration)

print "sum:", sum(y_data)
print "y_average:", y_average

step = 2

# divide into 20 zones
zones = []
data_not_zoned = list(y_data)
first_difference = []

for i in range(data_size-1):
    first_difference.append(y_data[i+1] - y_data[i])
###################### Start the program ######################

find_top(y_data)

zones.sort(key=lambda zone: zone["start_index"])
for i in range(len(zones)):
    start = time[zones[i]['start_index']]
    print start, zones[i]['top_value']

###################### Define a ploting function ######################

def ploting_fun(x, zones):
    for i in range(len(zones)):
        if x in range(zones[i]["start_index"], zones[i]["end_index"]+1):
            return zones[i]['top_value']
    return 0

y = []


for i in x:
    y.insert(int(i), ploting_fun(i, zones))

###################### plot the graph ######################
pylab.plot_date(time,y_data, '-', tz=None, xdate=True, ydate=False)
pylab.plot_date(time,y, '-', tz=None, xdate=True, ydate=False)

pylab.grid()
# Add error bars on data as red crosses.
pylab.show()
