function [result, histogram] = lbp_sir(varargin)

narginchk(1,5);
image=varargin{1};
d_image=double(image);
if nargin==1
    spoints=[-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1]; mapping=0;
    mode='h';
end
if (nargin == 2) && (length(varargin{2}) == 1)
    error('Input arguments!');
end

if (nargin > 2) && (length(varargin{2}) == 1)
    radius=varargin{2};
    neighbors=varargin{3};
    spoints=zeros(neighbors,2);
    a = 2*pi/neighbors;
    for i = 1:neighbors
        spoints(i,1) = -radius*sin((i-1)*a);
        spoints(i,2) = radius*cos((i-1)*a);
    end
    if(nargin >= 4)
        mapping=varargin{4};
    else
        mapping=0;
    end
    if(nargin >= 5)
        mode=varargin{5};
    else
        mode='h';
    end
end
if (nargin > 1) && (length(varargin{2}) > 1)
    spoints=varargin{2};
    if(nargin >= 3)
        mapping=varargin{3};
    else
        mapping=0;
    end
    if(nargin >= 4)
        mode=varargin{4};
    else
        mode='h';
    end
end

% Steps to determine the dimensions of input image
[ysize, xsize] = size(image);
neighbors=size(spoints,1);
miny=min(spoints(:,1));
maxy=max(spoints(:,1));
minx=min(spoints(:,2));
maxx=max(spoints(:,2));

% Steps to define a block size, where each LBP code is computed within a 
% block of size bsizey*bsizex
bsizey=ceil(max(maxy,0))-floor(min(miny,0))+1; 
bsizex=ceil(max(maxx,0))-floor(min(minx,0))+1;

% To assign the coordinates of origin (0,0) in the block
origy=1-floor(min(miny,0));
origx=1-floor(min(minx,0));

% Minimum allowed size for the input image depends on the radius of the used LBP operator
if(xsize < bsizex || ysize < bsizey)
    error('Input image too small for recognition. Dimensions should be at least (2*radius+1) x (2*radius+1)');
end

% To calculate dx and dy
dx = xsize - bsizex;
dy = ysize - bsizey;

% To fill the center pixel matrix C
C = image(origy:origy+dy,origx:origx+dx); d_C = double(C);
bins = 2^neighbors;

% To initialize the result matrix with zeros
result=zeros(dy+1,dx+1);

%To compute the LBP code image
for i = 1:neighbors
    y = spoints(i,1)+origy;
    x = spoints(i,2)+origx;
    
    % Calculation of floors, ceils and rounds for x and y
    fy = floor(y); cy = ceil(y); ry = round(y);
    fx = floor(x); cx = ceil(x); rx = round(x);
    
    % If interpolation is not needed, use original datatypes otherwise
    % use double type images
    if (abs(x - rx) < 1e-6) && (abs(y - ry) < 1e-6)
        N = image(ry:ry+dy,rx:rx+dx);
        D = N >= C; else
        ty = y - fy;
        tx = x - fx;
        
        % Calculate the interpolation weights
        w1 = (1 - tx) * (1 - ty);
        w2= tx *(1-ty);
        w3 = (1 - tx) * ty ;
        w4= tx* ty;
        
        % Compute interpolated pixel values
        N = w1*d_image(fy:fy+dy,fx:fx+dx) + w2*d_image(fy:fy+dy,cx:cx+dx) + w3*d_image(cy:cy+dy,fx:fx+dx) + w4*d_image(cy:cy+dy,cx:cx+dx);
        D = N >= d_C;
    end
    % Update the result matrix
    v = 2^(i-1);
    result = result + v*D;
end

% Apply mapping if it is defined
if length(mapping) > 1
    bins = max(max(mapping)) + 1;
    for i = 1:size(result,1)
        for j = 1:size(result,2)
            result(i,j) = mapping(result(i,j)+1);
        end
    end
end

if (strcmp(mode,'h') || strcmp(mode,'hist') || strcmp(mode,'nh'))
    % Return with LBP histogram if mode equals 'hist'
    histogram=hist(result(:),0:(bins-1)); %bins-1 = 255 with 1 input arg
    if (strcmp(mode,'nh'))
        result=result/sum(result);
    end
end
end
