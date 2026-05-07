function dataName = getDataName(path, num)
    files = dir([path, '/*.mat']); 
    file_sizes = [files.bytes];
    [~, idx] = sort(file_sizes);
    dataName = files(idx(num)).name;
end

