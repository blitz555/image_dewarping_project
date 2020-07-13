clc;
clear;
warning('off','all');%turn off all warnings
y = imread('037_CC_BIN.png');
y = imrotate(y,15,'bilinear','crop');
y_complement = imcomplement(y);
[row_num,col_num] = size(y);
r = 1;%erode circle radius
dilate_x = round (20, 0);%morphological dilation size, by 1/30 of page width in pixels 
dilate_y = round (2, 0);%morphological dilation size, by 1/30 of page width in pixels 

SEcircle = strel('sphere',r);
SElineH = strel('line',dilate_x,0);
SElineV = strel('line',dilate_y,90);
SErectangle = strel('rectangle', [dilate_x, 5] );%dilate by rectangle
y2 = imerode(y_complement,SEcircle);%perform erosion, removes salt and pepper noise
%SE = strel('line',dilate_size,0);%morphological structuring element, line, 0 degree orientation  

%iteratively erode and dilate to construct text line skeleton
for index = 1:5
y3 = imdilate(y2,SElineH);%perform horizontal dilation
y2 = imerode(y3,SElineV);%perform vertical erosion  
end
SElineH = strel('line',dilate_x*3,0);
y3 = imerode(y2,SElineH);%perform horizontal dilation
CC = bwconncomp(y3);%connected component analysis: counts 22 components based on 8 neighbour
imshowpair(y,y3,'montage'); hold on; 
%------------------------------------------------------------------------------------------------------------
%imshow(y); hold on; 
[row_cellarray, col_cellarray] = size(CC.PixelIdxList);
%row : vector of y coords, of component
%col : vector of x coords, of component
%poly3 : cubic polynomial; S hold error coefficients
%get x, y coordinates of a component and save in row, col vectors
%min_x, max_x : left and right end point of component

count = 0;
%right_points = point([]);%hold x,y coord of left most points of select components
%loop through every component in cell array list and plot best fit curve
for index = 1: col_cellarray
    [row, col] = ind2sub([row_num col_num], CC.PixelIdxList{1,index} ); %save y coord, x coord in arrays, pixel indices do not appear in order
    min_x = min(col);
    max_x = max(col);
    
    %if width of line greater than 60% of width of path, plot on graph
    if(max_x - min_x > round(0.6*col_num, 0) )
        count = count + 1;
        [poly3, S] = polyfit(col,row,3);%fit 3rd degree polynomial
        x_range = linspace(min_x, max_x, 20);%get 20 evenly spaced points in x
        %plot(x_range, polyval(poly3, x_range),'-', 'LineWidth', 1)%plot best fit line over x_range, polyval
        textlines_poly3(count, : )= poly3;
        
        %make component and save component fields in struct, list of components
        min_y = polyval(poly3, min_x);
        max_y = polyval(poly3, max_x);
        
        left_point = makePoint(min_x, min_y);
        right_point = makePoint(max_x, max_y);
        %the componentList here is not sorted by averageY, or anything
        componentList(count) = makeComponent(left_point, right_point, row, col, poly3);
    end
end

%plot left and right text boundaries
%sorted componentList by averageY
componentList = sortComponentList(componentList);

left_xs = [];%hold x-coord of left most points of select components
left_ys = [];%hold y-coord of left most points of select components
right_xs = [];%hold x-coord of right most points of select components
right_ys = [];%hold y-coord of right most points of select components

comp_count = size(componentList, 2);% count of structs in componentList  
for i = 1: comp_count
    left_xs(i) = componentList(i).left_point.x;
    left_ys(i) = componentList(i).left_point.y;
    right_xs(i) = componentList(i).right_point.x;
    right_ys(i) = componentList(i).right_point.y;
end

%fit left/right text boundary
[poly2left, Sleft] = polyfit(left_ys,left_xs,2);%fit 2nd degree polynomial
[poly2right, Sright] = polyfit(right_ys,right_xs,2);%fit 2nd degree polynomial

%get error data for left boundary
left_xdata = polyval(poly2left,left_ys); 
error_left = abs(left_xdata - left_xs);
%remove points that are more far away from fit
if(2*std(error_left) > 10)
    left_check(1:size(left_xdata, 2)) = 2*std(error_left);
else
    left_check(1:size(left_xdata, 2)) = 10;
end
I_left = error_left > left_check;
outliers_left = excludedata(left_xs,left_ys,'indices',I_left);

%get error data for left boundary
right_xdata = polyval(poly2right,right_ys); 
error_right = abs(right_xdata - right_xs);

%remove points that are more far away from fit
if(2*std(error_right) > 10)
    right_check(1:size(right_xdata, 2)) = 2*std(error_right);
else
    right_check(1:size(right_xdata, 2)) = 10;
end
I_right = error_right > right_check; 
outliers_right = excludedata(right_xs,right_ys,'indices',I_right);

%new vectors with outliers removed
left_xs_new = removeOutliers(left_xs, outliers_left);
left_ys_new = removeOutliers(left_ys, outliers_left);
right_xs_new = removeOutliers(right_xs, outliers_right);
right_ys_new = removeOutliers(right_ys, outliers_right);

%fit updated left/right borders
[poly2left, Sleft] = polyfit(left_ys_new,left_xs_new,2);%fit 2nd degree polynomial
[poly2right, Sright] = polyfit(right_ys_new,right_xs_new,2);%fit 2nd degree polynomial

%componentList(1).left_point
%get all intersection on left/right boundaries
for i = 1:comp_count;
    intersectionpoint_left(i) = intersectPoly( componentList(i).poly3, poly2left, componentList(i).left_point);
    intersectionpoint_right(i) = intersectPoly( componentList(i).poly3, poly2right, componentList(i).right_point);
end

%plot updated left/right borders
%---------------------------------------------------------------------------------------------
%plot( polyval(poly2left, [intersectionpoint_left.y]), [intersectionpoint_left.y],'red', 'LineWidth', 1)%plot best fit line over y_range, polyval
%plot( polyval(poly2right, [intersectionpoint_right.y]), [intersectionpoint_right.y],'red', 'LineWidth', 1)%plot best fit line over y_range, polyval

%plot intersection points on left and right borders
%plot([intersectionpoint_left.x],[intersectionpoint_left.y],'x');
%plot([intersectionpoint_right.x],[intersectionpoint_right.y],'x');
%------------------------------------------------------------------------------------------------------
%imshow(y); hold on;
%replot textlines between left/right boundaries
for i= 1: comp_count
    x_range = linspace(intersectionpoint_left(i).x, intersectionpoint_right(i).x, 20);%get 20 evenly spaced points in x
    %plot(x_range, polyval(componentList(i).poly3, x_range),'blue', 'LineWidth', 1)%plot best fit line over x_range, polyval
end

%calculate arc length on left/right borders
poly2left;
diff_poly2left = polyder(poly2left);%derivative of polynomial in y
arc_poly2left = @(y) sqrt(1 + polyval(diff_poly2left,y).^2);%arc length of polynomial in y
arc_left = integral(arc_poly2left,intersectionpoint_left(1).y,intersectionpoint_left(end).y);
[intersectionpoint_left(1).y intersectionpoint_left(end).y arc_left];

poly2right;
diff_poly2right = polyder(poly2right);%derivative of polynomial in y
arc_poly2right = @(y) sqrt(1 + polyval(diff_poly2right,y).^2);%arc length of polynomial in y
arc_right = integral(arc_poly2right,intersectionpoint_right(1).y,intersectionpoint_right(end).y);
[intersectionpoint_right(1).y intersectionpoint_right(end).y arc_right];

%get textline spacings and save in two vectors
arc_left_spacings = [];
arc_right_spacings = [];
for i = 1:comp_count-1
    arc_left_spacings(i) = integral(arc_poly2left,intersectionpoint_left(i).y,intersectionpoint_left(i+1).y);
    arc_right_spacings(i) = integral(arc_poly2right,intersectionpoint_right(i).y,intersectionpoint_right(i+1).y);
end

arc_left_spacings; 
arc_right_spacings;
mat_poly3diff = zeros(15,3);%store coefficients of each textline polynomials' first derivative 

j = 1;%keep count of unique max points found
%calculate arc length on textlines
for i = 1:comp_count
    componentList(i).poly3;
    diff_poly3text = polyder(componentList(i).poly3);%derivative of polynomial in y
    mat_poly3diff(i,:) = diff_poly3text;
    syms x%defines variable x
    fun = poly2sym(diff_poly3text);
    eqn = fun == 0;%equation is first derivative set to 0, look for local min/max
    max_x = double(vpasolve(eqn, x, [componentList(i).left_point.x componentList(i).right_point.x]));%calc numerical solution between left/right borders
    
    if size(max_x, 1) == 1 %save unique solution
        max_xs(j) = max_x;
        max_ys(j) = polyval(componentList(i).poly3, max_xs(j));
        j = j + 1;
    end
    
    arc_poly3text{i} = @(a) sqrt(1 + (polyval(diff_poly3text,a)).^2);%arc length of polynomial in y
    arclen = integral(arc_poly3text{i},intersectionpoint_left(i).x, intersectionpoint_right(i).x);
    text_arclen(i) = arclen;
end

%polynomial fit to max points on textlines
[poly2mid, S] = polyfit(max_ys,max_xs,2)%fit 2nd degree polynomial
mid_x= polyval(poly2mid, max_ys)
for i = 1:comp_count;
    intersectionpoint_mid(i) = intersectPoly( componentList(i).poly3, poly2mid, componentList(i).left_point);
end
plot(polyval(poly2mid,[intersectionpoint_mid.y]),[intersectionpoint_mid.y],'*blue');%plot mid line

%get left max
fun = poly2sym(diff_poly2left);%default variable is x
eqn = fun == 0;%equation is first derivative set to 0, look for local min/max
left_max_y = vpasolve(eqn, x, [intersectionpoint_left(1).y intersectionpoint_left(comp_count).y]);%calc numerical solution between 1st last textlines
left_max_x = polyval(poly2left, double(left_max_y));
if(isempty(left_max_x))
    if(intersectionpoint_left(1).x < intersectionpoint_left(comp_count).x)
        left_max_y = intersectionpoint_left(1).y;
        left_max_x = intersectionpoint_left(1).x;
    else
        left_max_y = intersectionpoint_left(comp_count).y;
        left_max_x = intersectionpoint_left(comp_count).x;
    end
end
%plot(left_max_x,left_max_y,'p');%plot max left border
%-----------------------------------------------------------------------------------------------------
%get right max
fun = poly2sym(diff_poly2right);%default variable is x
eqn = fun == 0;%equation is first derivative set to 0, look for local min/max
right_max_y = vpasolve(eqn, x, [intersectionpoint_right(1).y intersectionpoint_right(comp_count).y]);%calc numerical solution between 1st last textlines
right_max_x = polyval(poly2right, double(right_max_y));
if(isempty(right_max_y))
    if(intersectionpoint_right(1).x > intersectionpoint_right(comp_count).x)
        right_max_y = intersectionpoint_right(1).y;
        right_max_x = intersectionpoint_right(1).x;
    else
        right_max_y = intersectionpoint_right(comp_count).y;
        right_max_x = intersectionpoint_right(comp_count).x;
    end
end
%plot(right_max_x,right_max_y,'p');%plot max right border
%----------------------------------------------------------------------------------------------------
text_arclen;
al = arc_left_spacings'; 
ar = arc_right_spacings';
t = text_arclen';

%make grid points for all textlines
count = 0; 
points_per_line = 40;
for i = 1:comp_count
    x_coords = linspace(intersectionpoint_left(i).x, intersectionpoint_right(i).x, points_per_line);
    y_coords = polyval(componentList(i).poly3, x_coords);
    for j = 1: points_per_line
        count = count + 1;
        gridpoints(count) = makePoint(x_coords(j), y_coords(j));
    end
end
plot([gridpoints.x],[gridpoints.y],'xred');%plot all grid points on polynomials
count = 0;%reset count to 0
for i = 1:comp_count%iterate through every component
    left_x_diff = left_max_x - intersectionpoint_left(i).x; 
    right_x_diff = right_max_x - intersectionpoint_right(i).x; 
    for j = 1: points_per_line%iterate throuhg every point on textline
        count = count + 1;
        %calculate horizontal correction x
        if gridpoints(count).x < intersectionpoint_mid(i).x 
            x_offset = left_x_diff * abs(gridpoints(count).x - intersectionpoint_mid(i).x)/abs(intersectionpoint_left(i).x - intersectionpoint_mid(i).x); 
        else
            x_offset = right_x_diff * abs(gridpoints(count).x - intersectionpoint_mid(i).x)/abs(intersectionpoint_right(i).x - intersectionpoint_mid(i).x); 
        end
        
        %calculate textline correction, x, y
        arclen = integral(arc_poly3text{i}, intersectionpoint_mid(i).x, gridpoints(count).x);
        new_gridpoints(count)= makePoint(intersectionpoint_mid(i).x + arclen + x_offset, intersectionpoint_mid(i).y);
        %save x, y offsets
        x_offsets(count) = new_gridpoints(count).x - gridpoints(count).x;
        y_offsets(count) = new_gridpoints(count).y - gridpoints(count).y; 
    end
end
%plot([new_gridpoints.x],[new_gridpoints.y],'xgreen');%plot all grid points on polynomials
%experiment with polynomial vs linear transform

for i = 1: comp_count * points_per_line%iterate through all control points
    moving_row = [gridpoints(i).x gridpoints(i).y];
    fixed_row = [new_gridpoints(i).x new_gridpoints(i).y];
    
    movingPoints(i, : )= moving_row;%fill x and y coords into rows
    fixedPoints(i, : )= fixed_row;%fill x and y coords into rows
end
%imshow(y); hold on;
%quiver([gridpoints.x], [gridpoints.y], x_offsets, y_offsets);

tform = fitgeotrans(movingPoints,fixedPoints,'polynomial',4)
y_final = imwarp(y,tform);
%imshowpair(y,y_final,'montage')
imshow(y_final);
%imwrite(y_final,'n4.png')
