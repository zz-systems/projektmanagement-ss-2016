classdef ImgCore < handle
   %Class for all image functions including opening of files 
    
   properties(SetAccess = private)
       fileName
       rawImage
   end
   
   methods
       function openImage(self)
           [filename, dirname] = uigetfile({'*.jpg';'*.bmp';'*.png'},'Image Selector');
           self.fileName = [ dirname filename ];
           self.rawImage = imread(self.fileName);
       end
       
       function displayRawImage(self, target)
           imagesc(self.rawImage, 'Parent', target);
       end
       
       function displayImage(img, target)
           imagesc(img, 'Parent', target);
       end
       
       function gs = grayscale(self)
           lum = self.rawImage(:, :, 1) * .2126 + self.rawImage(:, :, 2) * .7152 + self.rawImage(:, :, 3) * .0722;
            
           gs = cat(3, lum, lum, lum);
           gs = imresize(gs,[256 256]);
       end
       
       function relErr = relativError(img1, img2)
           % Returns relative Error in percent
           for i = 0:255
               if img1(i)>=img2(i)
                   relErr = relErr + (img1 - img2);
               else
                   relErr = relErr + (img2 - img1);
               end
           end
           relErr = relErr * 100 / sum(img1);
       end
   end
end