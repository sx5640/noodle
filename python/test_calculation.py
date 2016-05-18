import pylab
import numpy
from scipy.optimize import curve_fit

## Function to fit: 'x' is the independent variable(s), 'p' the parameter vector
#   Note:   A one line lambda function definition  can be used for very simple
#           functions, but using "def" always works.
#   Note:   "*p" unpacks p into its elements; needed for curvefit
n = 0
def gauss_fit(x,*p) :
    def degree_n(n):
        return p[4*n]+p[4*n+1]*numpy.exp(-1*(x-p[4*n+2])**2/(2*p[4*n+3]**2))
    def recursive(n):
        if n == -1:
            return 0
        else:
            return degree_n(n) + recursive(n-1)
    return recursive(n)

def poly_fit(x,*p) :
    def recursive(n):
        if n == 0:
            return 0
        else:
            return p[n]*x**n + recursive(n-1)
    return recursive(n)

## Load data to fit
x, y_data = numpy.loadtxt('data.txt', delimiter='    ', unpack=True)

average = sum(y_data)/len(y_data)

y_manipulated = numpy.zeros(len(y_data))

for i in range(0, len(y_manipulated)):
    if y_data[i] > average:
        y_manipulated[i] = round(y_data[i] - average)
    else:
        y_manipulated[i] = 0


## Fit function to data

# For information of curve_fit.py, see
#   http://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.curve_fit.html
# This fits the function "func" to the data points (x, y_data) with y
#   uncertainties "y_sigma", and initial parameter values p0.
p, cov = curve_fit(gauss_fit, x, y_data, p0=[1,1,600,100])

## Output results

print "Covariance Matrix : \n", cov, "\n"
print "Estimated parameters: ", p
try:
    print "Estimated uncertainties: ", numpy.sqrt(cov.diagonal())
# If cov has not been calculated because of a bad fit, the above print
#   statement will cause a python AttributeError which is caught by
#   this try-except. This could be checked with an if statement, but
#   Python leans to asking forgiveness afterwards, not permission before.
except AttributeError:
    print "Not calculated; fit is bad."

# Plot data as red circles, and fitted function as (default) line
pylab.plot(x,y_data, x, gauss_fit(x,*p))
pylab.grid()
# Add error bars on data as red crosses.
pylab.show()
