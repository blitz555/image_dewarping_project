%struct constructor: component
function component = makeComponent( left_point, right_point, row, col, poly3)
    component.left_point = left_point;
    component.right_point = right_point;
    component.row = row;
    component.col = col;
    component.poly3 = poly3; 
    component.averageY = mean(row);
end

