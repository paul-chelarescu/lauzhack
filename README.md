<<<<<<< HEAD
# lauzhack

Machine Learning project that identifies cloud shadows on a map field.

We made use of both clustering and gradient descent algorithms.

Code written in MATLAB.
=======
# Lauzhack - Cloud shadow removal

Farmers want to take batter decisions about how to manage their crops.

How do they do that?

[Gamaya](http://gamaya.com/) scans the crops with low altitude drones using high spectroscopy cameras.

Cameras that not only take pictures in red, green, blue, but in many, many other wavelenghts - useful for detecting what materials is in that area.

The better the data is about the crops the better the estimates are.

The challenged we face is that clouds cast shadows over the land, which skew the data, so we need to process the images to try and remove the cloud shadows as much as possible.

Why is this a challenge? Because cloud shadows look very similar to patches of water and dark vegetation.

In the initial implementation of the shadow removal algorthm, we make the assumption that the whole picture has the same reflactance and therefore we calculate the geometric mean of the channels of each band. 

Although this method proved to perform well overall, we can improve it even further as we made a slightly wrong assumption when we initially established that the reflectance has the same in whole picture (assumption which is false since it is higher for the sunny parts of the field and lower for the cloudy bits.)

Therefore we can use clustering to normalize the mean squared value between the geometric calcuations on smaller portions, and obtaining both more accurate radiances and lower error estimates.
