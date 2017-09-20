classdef ImgCore < handle
   %Class for all image functions including opening of files 
    
   properties(SetAccess = private)
       fileName
       rawImage
   end
   
   methods
       function openImage(self)
           % Shows windows explorer window to select and open a file
           [filename, dirname] = uigetfile({'*.jpg';'*.bmp';'*.png'},'Image Selector');
           self.fileName = [ dirname filename ];
           self.rawImage = imread(self.fileName);
       end
       
       function displayRawImage(self, target)
           % displays the rwa image of last opened file
           imagesc(self.rawImage, 'Parent', target);
       end
       
       function displayImage(self, img, target)
           % used to display any given image in a specified axis
           imagesc(img, 'Parent', target);
       end
       
       function gs = grayscale(self)
           % convert the last opened picture into an grayscale image
           lum = self.rawImage(:, :, 1) * .2126 + self.rawImage(:, :, 2) * .7152 + self.rawImage(:, :, 3) * .0722;
            
           gs = cat(3, lum, lum, lum);
           gs = imresize(gs,[256 256]);
       end
       
       function relErr = relError(self, img1, img2)
           % Returns relative Error in percent
            re = abs(img1 - img2);
            relErr = (sum(re)*100) / sum(img1);
       end
   end
end