The name of the script is hw4.m

The first function I created is neighborSampling on line 21. It contains the code responsible for
performing the nearest neighbor resizing. It takes in the original image and resizes it depending on
the height and width specified in the function on lines 23-24.
The function creates a new image the size of the newly specified w and h and loops through and assigns 
every pixel to the originals images location at the (current row pixel location * (the original images height/the new images width)).
The same process is done to find the column pixel location. This value within the original image is then 
assigned to the resized image. This continues until there is no more pixels to be written to in the resized
image.

To create the energy function I created a function on line 34 called energyFunction. This method
converts the image to grey, performs a guassian blur and finally finds the gradient magnitude of said image.
I chose a sigma of 1 and a central difference gradient kernel.

I contain all of the code that finds the optimal seam of an image within the function called optimal seam
on line 42. It takes in the energy function of the original image and returns the cost matrix and a black and 
white image thatcontains the seam in all white on a black background. To find the seam I begin by creating the 
cost matrixfor the passed image. I do this by first assigning the base case where the first row is assigned to 
the original energy function. I then go down a row and from that current pixel location I find the smallest pixel 
value within the possible options of top-left, top-right and top and add that to the current pixel location. I
do this until there is no more pixels to add. With that newly created cost function I back track from the bottom
of the image and find the smallest pixel value on the bottom row. From that position, I look up-left, up-right and up
and go to (assign a white pixel) the smallest of those three options. I continue that process until there is no more
rows.
To draw the red seam on the original image, I created a function on line 123 that loops through the pixels in the
found seam image and assigns a red pixel to the orignal image at any location where there is a seam to be found (255). 

To finally perform the seam carving, I made a function called seamCarving on line 158 that takes in the orignal image
and the desired amount of carves to perform on said image. I use a helper function called removeSeam on line 137 that
takes in the found seam, current craved image, and the original images width. With that I create a padded image of the 
original width and another image that is the new size after a carving. I loop through all the pixles in the seam image.
Once I find the seam, I take everything before and after the seam and assign it to the the new image. The I apply that 
new image to the padded image so I can create the video. It returns the image without padding and with. It loops
until the specified amount of carves and removes that seam for each iteration of that image.
