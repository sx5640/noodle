import pylab
import numpy
import math
from scipy.optimize import curve_fit
import pdb


###################### Go From Top ######################

# find the top

def find_top(data):
    data_temp = list(data)
    top_value = max(data)
    top_index = data.index(top_value)


    if top_value > 2 * y_average:
        start_time = move_boundary(top_index, -step, step)
        end_time = move_boundary(top_index, step, step)

        zones.append({'start_time': start_time, 'end_time': end_time, 'top_value': top_value})

        print zones

        for i in range(start_time, end_time + 1):
            data_not_zoned[i] = 'stop'
            data_temp[i] = 0

        find_top(data_temp)

    # else:
    #     i = 0
    #     while i in range(data_size):
    #         if data_not_zoned[i] == 'stop':
    #             i += 1
    #         else:
    #             start_time = i
    #
    #             if 'stop' in data_not_zoned[i: data_size]:
    #                 end_time = i + data_not_zoned[i: data_size].index('stop')
    #             else:
    #                 end_time = data_size
    #
    #             print start_time, end_time
    #             print data[start_time: end_time]
    #             top_value_temp = max(data[start_time: end_time])
    #
    #             zones.append({'start_time': start_time, 'end_time': end_time, 'top_value': top_value_temp})
    #
    #             i = end_time + 1

# define a function that move the boundary and see if the slop it is downward over all
def move_boundary(top_index, move_by, step):
    direction = move_by / abs(move_by)

    if top_index + move_by >= data_size - 1:
        return data_size - 1

    if 'stop' in data_not_zoned[top_index: top_index + move_by: direction]:
        return top_index + direction*data_not_zoned[top_index: top_index + move_by: direction].index('stop')

    elif top_index + move_by <=0:
        return 0

    elif top_index + move_by >= data_size - 1:
        return data_size - 1

    else:
        first_difference_average = numpy.average(first_difference[top_index + move_by - direction * step: top_index + move_by: direction])

        if first_difference_average == 0:
            next_direction = 0
        else:
            next_direction = int(-first_difference_average / abs(first_difference_average))

        if direction * next_direction == 1:
            return move_boundary(top_index, move_by + next_direction * step, step)
        elif direction * next_direction == -1 or next_direction == 0:
            if abs(step) == 1:
                return top_index + move_by

            else:
                return move_boundary(top_index, move_by + next_direction + 3*direction, step / 2)


###################### Initialize the program ######################

# import data from txt file
x, y_data = numpy.loadtxt('trump_day.txt', delimiter='    ', unpack=True)

y_data = tuple(y_data)
data_size = len(y_data)
y_average = numpy.average(y_data)

step = 4

# divide into 20 zones
zones = []
data_not_zoned = list(y_data)
first_difference = []

for i in range(data_size-1):
    first_difference.append(y_data[i+1] - y_data[i])
###################### Start the program ######################

find_top(y_data)

print zones

###################### Define a ploting function ######################

def ploting_fun(x, zones):
    for i in range(len(zones)):
        if x in range(zones[i]["start_time"], zones[i]["end_time"]+1):
            return zones[i]['top_value']
    return 0

y = []


for i in x:
    y.insert(int(i), ploting_fun(i, zones))

###################### plot the graph ######################
pylab.plot(x,y_data, x, y)
pylab.grid()
# Add error bars on data as red crosses.
pylab.show()
