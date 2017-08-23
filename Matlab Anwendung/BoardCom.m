classdef BoardCom < handle
   % Class for communication between Application and DE1-SoC baord
    
   properties(SetAccess = private)
       processedImg
   end
   
   methods
       function lbp = openCl(self, img)
          % Function for openCl solution with LBP operator
          % img contains the grayscale image
          % lbp should contain the processed image and is saved in maingui
          % as return value
       end
       
       function lbp = vhdlHardware(self, img)
           % Function for hardware solution of LBP operator
           % img contains the grayscale image
           % lbp should contain the processed image and is saved in maingui
           % as return value
       end
   end
end