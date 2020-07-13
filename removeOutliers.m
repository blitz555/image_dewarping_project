%create vector of remaining keypoints
function v_out = removeOutliers(v_in, outliers)
    v_out = v_in;%copy of v_in
    remove_indices = [];
    for i = 1: size(v_in, 2)
        if(outliers(i) == 1)
            remove_indices = [remove_indices i];
        end
    end
   v_out(remove_indices) = []; 
end
