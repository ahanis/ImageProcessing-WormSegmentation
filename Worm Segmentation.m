%Hanis Athirah

%clear unnecessary items
close all;
clear;
clc;

%access image folder
imgFolder = dir('*.png');

%load file that contains the images and does processing on each image
for total_images = 1 : length(imgFolder)
  
 %if image exist read image 
 %if exist(imgFolder, 'file') 
 %read current image in the loop
 image = imread(imgFolder(total_images).name);
 oriImg = image;
 %else
 %show warning message if image is unavailable
 %warningMessage = sprintf('Warning: image file does not exist:\n%s', imgDirectory);
 %uiwait(warndlg(warningMessage)); 
 %end
  
  %sharpening image
  i = 0;
  while i < 5
    image = imsharpen(image);
    i =  i+1;
  end
  
  %convert all the black to white
  %done to remove especially the black on the outer lens
  %mask black parts
  M = repmat(all(~image,3),[1 1 3]);
  %turn the black pixel to white
  image(M) = 255; 
  
  %increase the black intensity
  M = repmat(all(image<100,3),[1 1 3]);
  image(M) = 0; 
  
  %converting RGB to YCrCb
  image = rgb2ycbcr(image);
  
  %adjust intensity of the image
  %image = double(image); 
  %image = image/130;
  %image(:,:,1) = image(:,:,1);
  
  %removing noise
  
  %filter the image with a Gaussian filter with standard deviation of 2
  image = imgaussfilt(image,2);
  
  %save mask overlaid area image
  blurImg = image;
  
  %determine threshold to use in binarization operation
  threshImage = adaptthresh(image , 0.80);
  
  %convert image to binary image
  image  = imbinarize(image ,threshImage);
  
  %bridges unconnected pixels, that is, sets 0-valued pixels to 1
  %if they have two nonzero neighbours that are not connected
  image = bwmorph(image(:,:,1), 'bridge', Inf);
  %image = bwmorph(image, 'thicken');
  
  %create a circle mask
  %get the dimensions of the image
  [rows, columns, numberOfColorBands] = size(image);
  % initialize parameters for the circle
  circleCenterX = 1010; 
  % square area 0f 500*500
  circleCenterY = 550; 
  % radius 
  circleRadius = 580;    
  % initialize an image to a logical image of the circle 
  circleImage = false(rows, columns); 
  [x, y] = meshgrid(1:columns, 1:rows); 
  circleImage((x - circleCenterX).^2 + (y - circleCenterY).^2 <= circleRadius.^2) = true; 
  % mask the image with the circle
  if numberOfColorBands == 1
 	% initialize with the entire image
      maskedImage = image;
      %one because to make the circle outside the lens is white
      maskedImage(~circleImage) = 1; 
  else
      %mask the image
      maskedImage = bsxfun(@times, image, cast(circleImage,class(image)));
  end
  
  %extract biggest blob
  image = bwareafilt(maskedImage, 1); 
  
  %fill the worm's body with line se
  i = 0;
  se = strel('line',3,5);
  while i < 4
      image = imerode(image,se);
      %image = imopen(image,se);
      i =  i+1;
  end
  
  %fill the worm's body with disk se
  se = strel('disk',5);
  image = imclose(image,se);
  
  %final b&w image
  bnwImg = image;

  %edge detection
  edgeImg = edge(image,'canny');
  
  %turn the worm into white
  areaImg = ~image;
  %white worm filled
  whiteWorm  = imfill(areaImg ,'holes'); 
  
  %calculate perimeter
  perimeter = regionprops(whiteWorm,'Perimeter');
  perimeter = struct2cell(perimeter);
  perimeter = cat(2,perimeter{:});
  sprintf('The perimeter of worm in image %d = %.3f pixels\n', total_images,perimeter)
  
  %calculate area
  area = bwarea(areaImg);
  sprintf('The area of worm in image %d = %.3f pixels\n', total_images, area)

  %display edge detection image
  figure, imshow(edgeImg);
  %figure title
  title(sprintf('Edge DetectionImage %d', total_images));
  %display images retrieved
  montage({oriImg,bnwImg;blurImg,whiteWorm})
  title({['Original Image (Top Left), Mask Image (Top Right), B&W Images (Bottom)' ] 
    ['Area = ' num2str(area)]})
    
end
 
