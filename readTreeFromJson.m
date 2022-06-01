function tree = readTreeFromJson(fileName)

if nargin < 1
    fileName = 'NPIX01.json';
end

data = loadjson(fileName);

if isstruct(data)
    ff = fields(data);
    data = data.(ff{1});
end

tree = myCell2Struct(data);


end

function out = myCell2Struct(in)

out = in;
if iscell(in)
    try
        out = cell2mat(in);
    catch
        out = in{1};
        out = cell2mat(out);
    end
end

if isstruct(out)
    for i=1:numel(out)
        if isfield(out(i), 'subTree')
            out(i).subTree = myCell2Struct(out(i).subTree);
        end
    end
end

end