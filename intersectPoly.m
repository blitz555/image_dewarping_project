%solves for intersection point of textline(h_poly) and border (v_poly)
%h_poly: polynomial of textline
%v_poly: polynomial of vertical border
%initial_point
function intersect_point = intersectPoly(h_poly, v_poly, initial_point)
    x_in = 0;
    y_in = 0;
    x_out = initial_point.x;
    y_out = initial_point.y;
    while( abs(y_out - y_in) > 0.01 || abs(x_out - x_in) > 0.01)
        %[x_in, x_out, y_in,  y_out]
        y_in = y_out;%update in value to new result
        x_in = x_out;%update in value to new result
        y_out = polyval(h_poly, x_in);%calculate new y from textline
        x_out = polyval(v_poly, y_out);%calculate new x from vertical border
        
    end %end of while
    %[x_in, x_out, y_in,  y_out]
    intersect_point = makePoint(x_out, y_out);
end

