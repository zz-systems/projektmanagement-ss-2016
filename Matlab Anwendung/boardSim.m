classdef boardSim < handle
    
    properties
        
    end
    
    methods(Access = public)
       function [lbp, system_time, kernel_time] = openCl(self, img)
          lbp = img;
          system_time = 0.0;
          kernel_time = 49.378;
       end
       
       function [lbp, system_time, kernel_time] = vhdlHardware(self, img)
          lbp = img;
          system_time = 0.0;
          kernel_time = 0.356;
       end
    end
end