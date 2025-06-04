clc;
close all;
clear;

% Select image
[filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp'}, 'Select an image file');
if isequal(filename,0)
    disp('User canceled the file selection.');
    return;
else
    im = imread(fullfile(pathname, filename));
end

im = imresize(im, [480 NaN]);
imshow(im), title("Original Image");

imgray = rgb2gray(im);
imbin = imbinarize(imgray);
im = edge(imgray, 'sobel');
im = imdilate(im, strel('diamond', 2));
im = imfill(im, 'holes');
im = imerode(im, strel('diamond', 10));

Iprops = regionprops(im, 'BoundingBox', 'Area', 'Image');
boundingBox = Iprops(1).BoundingBox;
maxa = Iprops(1).Area;
for i = 1:numel(Iprops)
    if maxa < Iprops(i).Area
        maxa = Iprops(i).Area;
        boundingBox = Iprops(i).BoundingBox;
    end
end

im = imcrop(imbin, boundingBox);
im = imresize(im, [240 NaN]);
im = imopen(im, strel('rectangle', [4 4]));
im = bwareaopen(~im, 500);
[h, w] = size(im);

figure;
imshow(im), title("Extracted No. Plate with Isolated Character");

Iprops = regionprops(im, 'BoundingBox', 'Area', 'Image');
count = numel(Iprops);
noPlate = '';

hold on;
for i = 1:count
    ow = size(Iprops(i).Image, 2);
    oh = size(Iprops(i).Image, 1);
    if ow < (h/2) && oh > (h/3)
        rectangle('Position', Iprops(i).BoundingBox, 'EdgeColor', 'g', 'LineWidth', 2);
    end
end

for i = 1:count
    ow = size(Iprops(i).Image, 2);
    oh = size(Iprops(i).Image, 1);
    if ow < (h/2) && oh > (h/3)
        letter = readLetter(Iprops(i).Image);
        noPlate = [noPlate letter];
    end
end

% ... [previous code remains unchanged until after 'Detected Plate' is printed]

disp("Detected Plate: " + noPlate);

% Load database
db = readtable('database.csv');

% Check if plate is in database
rowIdx = find(strcmp(db.Plate, noPlate));

if isempty(rowIdx)
    disp("Plate not found in database.");
else
    chat_id = string(db.chat_id(rowIdx));


    % ---- DYNAMIC PARKING FEE LOGIC ----
    % Example: Random fee between 20 and 100 (or replace with your real fee calculation)
    parkingFee = randi([20, 100]);

    % Compose message
    message = sprintf("Your vehicle with plate %s has exited the parking lot.\nYour parking fee is ₹%d. Please proceed with the payment.", noPlate, parkingFee);

    % ---- TELEGRAM MESSAGE SEND ----
    token = ''; % Your bot token
    url = sprintf('https://api.telegram.org/bot%s/sendMessage', token);
    data = struct('chat_id', chat_id, 'text', message);

    try
        response = webwrite(url, data);
        disp("Message sent to " + chat_id + " with fee ₹" + parkingFee);
    catch ME
        disp("Failed to send message: " + ME.message);
    end
end
