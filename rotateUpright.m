y = imread('020_CC_BIN.png');
y_complement = imcomplement(y);
[row_num,col_num] = size(y);
r = 1;%erode circle radius
r_large = 30;
dilate_x = round (20, 0);%morphological dilation size, by 1/30 of page width in pixels 
dilate_y = round (2, 0);%morphological dilation size, by 1/30 of page width in pixels 

SEcircle = strel('sphere',r);
SEcirclelarge = strel('sphere',r_large);
SElineH = strel('line',dilate_x,0);
SElineV = strel('line',dilate_y,90);
SErectangle = strel('rectangle', [30,30] );%dilate by rectangle
imshow(y_complement)
%y2 = imerode(y_complement,SEcircle);%perform erosion, removes salt and pepper noise
%SE = strel('line',dilate_size,0);%morphological structuring element, line, 0 degree orientation  

y3 = imdilate(y_complement,SErectangle);%perform horizontal dilation4
%imshow(y3)
%iteratively erode and dilate to construct text line skeleton
%for index = 1:5
%y3 = imdilate(y2,SElineH);%perform horizontal dilation
%y2 = imerode(y3,SElineV);%perform vertical erosion  
%end
%}
y3 = imrotate(y,5,'bilinear','crop');
% Get BW image
imshowpair(y,y3,'montage');

%{
CC = bwconncomp(y3);%connected component analysis: counts 22 components based on 8 neighbour
imshowpair(y,y3,'montage'); hold on; 

[B,L,N] = bwboundaries(y3);%https://www.mathworks.com/help/images/ref/bwboundaries.html, the following loops highlight the boundaries of connected regions

for k=1:length(B),
   boundary = B{k};
   if(k > N)
     plot(boundary(:,2), boundary(:,1), 'g','LineWidth',2);
   else
     plot(boundary(:,2), boundary(:,1), 'r','LineWidth',2);
   end
end
%}
