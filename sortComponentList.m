%sort componentList by averageY in ascending order
function Asorted = sortComponentList(A)
    Afields = fieldnames(A);    
    Acell = struct2cell(A);
    sz = size(Acell);
    % Convert to a matrix
    Acell = reshape(Acell, sz(1), []);      % Px(MxN)
    % Make each field a column
    Acell = Acell';                        % (MxN)xP
    % Sort by first field "averageY", field #6
    Acell = sortrows(Acell, 6);
    % Put back into original cell array format
    Acell = reshape(Acell', sz);
    % Convert to Struct
    Asorted = cell2struct(Acell, Afields, 1);
end
