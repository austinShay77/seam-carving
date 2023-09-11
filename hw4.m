baseImage = imread("water.jpg");
[~, W, ~] = size(baseImage);

neighbor = neighborSampling(baseImage);
%bilinear = biLinearInterpolation(baseImage);
%imwrite(neighbor, "450x450neighborWater.jpg")
subplot(1,2,1), imshow(baseImage);
subplot(1,2,2), imshow(neighbor)

%energy = energyFunction(baseImage);
%seam = optimalSeam(energy);
%drawnSeam = drawSeam(baseImage, seam);
%imwrite(drawnSeam, "roadSeam.jpg")

%[shrunk, pad] = seamCarving(baseImage, W-1);

%subplot(1,3,1), imshow(baseImage);
%subplot(1,3,2), imshow(shrunk);
%subplot(1,3,3), imshow(pad);

function img = neighborSampling(image)
    [H, W, ~] = size(image);
    h = round(H/2);
    w = round(W/2);
    resized = zeros(h, w, 3);
    for y = 1: h
        for x = 1: w
            resized(y,x,:) = image(round(y*(H/h)), round(x*(W/w)), :);
        end
    end
    img = uint8(resized);
end

function img = energyFunction(image)
    gray = rgb2gray(image);
    blurred = imgaussfilt(gray, 1);
    [gMag, ~] = imgradient(blurred, 'central');
    img = gMag;
end

% takes in energy image
function [img, cost] = optimalSeam(image)
    [H, W, ~] = size(image);
    costMatrix = zeros(H, W);
    bestSeam = zeros(H, W, 3);
    for y = 1: H
        for x = 1: W
            if y == 1
                costMatrix(y,x) = image(y,x);
            else
                % no left value
                if x-1 < 1
                    costMatrix(y,x) = image(y,x) + min([costMatrix(y-1, x), costMatrix(y-1, x+1)]);
                % no right value
                elseif x+1 > W
                    costMatrix(y,x) = image(y,x) + min([costMatrix(y-1, x-1), costMatrix(y-1, x)]);
                % has all pixels
                else
                    costMatrix(y,x) = image(y,x) + min([costMatrix(y-1, x-1), costMatrix(y-1, x), costMatrix(y-1, x+1)]);
                end
            end
        end
    end

    % get bottom row starting point
    colIndex = W;
    minimum = costMatrix(H,W);
    for x = W: -1: 1
        % IS IT <= OR JUST < ?????
        if costMatrix(H, x) < minimum %&& costMatrix(H, x) ~= 0
            minimum = costMatrix(H, x);
            colIndex = x;
        end
    end
    bestSeam(H, colIndex, :) = 255;

    % every row after get the lowest value pixel from the 
    % top, top-right or top-left of the current pixel
    for y = (H-1): -1: 1
        % no right edge
        if colIndex + 1 > W
            left = costMatrix(y, colIndex-1);
            top = costMatrix(y, colIndex);
            minimun = min([left, top]);
            if minimun == left
                bestSeam(y, colIndex-1, :) = 255;
                colIndex = colIndex - 1;
            else
                bestSeam(y, colIndex, :) = 255;
            end
        % no left edge
        elseif colIndex - 1 < 1
            top = costMatrix(y, colIndex);
            right = costMatrix(y, colIndex+1);
            minimum = min([top, right]);
            if minimum == top
                bestSeam(y, colIndex, :) = 255;
            else
                bestSeam(y, colIndex+1, :) = 255;
                colIndex = colIndex + 1;
            end
        % all edges exists
        else
            left = costMatrix(y, colIndex-1);
            top = costMatrix(y, colIndex);
            right = costMatrix(y, colIndex+1);
            minimum = min([left, top, right]);
            if minimum == left
                bestSeam(y, colIndex-1, :) = 255;
                colIndex = colIndex - 1;
            elseif minimum == top
                bestSeam(y, colIndex, :) = 255;
            else 
                bestSeam(y, colIndex+1, :) = 255;
                colIndex = colIndex + 1;
            end
        end
    end
    cost = uint8(costMatrix);
    img = uint8(bestSeam);
end

function img = drawSeam(image, seam)
    [H, W, ~] = size(image);
    for y = 1: H
        for x = 1: W
            if seam(y,x) > 0
                image(y,x, 1) = 255;
                image(y,x, 2) = 0;
                image(y,x, 3) = 0;
            end
        end
    end
    img = uint8(image);
end

function [img, pad] = removeSeam(image, seam, orgW)
    [H, W, ~] = size(image);
    newImage = zeros(H, W-1, 3);
    paddedImage = zeros(H, orgW, 3);
    
    y = 1;
    while y <= H
        for x = 1: W
            if seam(y,x) > 0
                newImage(y, 1:x-1, :) = image(y, 1:x-1, :);
                newImage(y, x:end, :) = image(y, x+1:end, :);
                break;
            end
        end
        y = y + 1;
    end
    paddedImage(:, 1:W-1, :) = newImage(:,:,:);
    img = uint8(newImage);
    pad = uint8(paddedImage);
end

function [img, pad] = seamCarving(image, numofcarves)
    v = VideoWriter("waterSeamCarving.avi", "MPEG-4");
    open(v);
    [~, orgW, ~] = size(image);
    carvedImage = image;
    
    % write the first frame to the video
    writeVideo(v,image)
    while numofcarves > 0
        % find energy function
        energy = energyFunction(carvedImage);
        % get the best seam to remove
        [foundSeam, ~] = optimalSeam(energy);
        % remove seam
        [carvedImage, paddedImage]  = removeSeam(carvedImage, foundSeam, orgW);
        % write drawn to video
        if size(carvedImage,2) == orgW
            % draw seam
            drawnOnSeam = drawSeam(carvedImage, foundSeam);
            writeVideo(v,drawnOnSeam)
        else
            % draw seam
            drawnOnSeam = drawSeam(carvedImage, foundSeam);
            paddedDrawnOnSeam = paddedImage;
            [~, W, ~] = size(drawnOnSeam);
            paddedDrawnOnSeam(:, 1:W, :) = drawnOnSeam(:, :, :);
            writeVideo(v, paddedDrawnOnSeam)
        end
        % write removed to video
        writeVideo(v,paddedImage)
        % reduce number of carves left
        numofcarves = numofcarves - 1;
    end
    % finish video
    close(v);
    pad = uint8(paddedImage);
    img = uint8(carvedImage);
end

function img = biLinearInterpolation(image)
    [H, W, ~] = size(image);
    h = H*2;
    w = W*2;
    resized = zeros(h, w, 3);
    for y = 1: h
        for x = 1: w
            lowy = floor(y*(H/h));
            lowx = floor(x*(W/w));
            highy = ceil(y*(H/h));
            highx = ceil(x*(W/w));
            % euclidean
            lowValue = sqrt((y-lowy)^2 + (x-lowx)^2);
            highValue = sqrt((y-highy)^2 + (x-highx)^2);
            if lowValue > highValue
                disp(lowValue)
            else
                disp(highValue)
            end
        end
    end
    img = uint8(resized);
end
