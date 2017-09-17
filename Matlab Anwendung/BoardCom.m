classdef BoardCom < handle
   % Class for communication between Application and DE1-SoC baord
    
   properties(SetAccess = private)
       processedImg
       connection   = 'root@192.168.0.123';
       
       target_root  = '/home/root';
       cmd_aocl_init = {'source ./init_opencl.sh', 'aocl program /dev/acl0 lbp.aocx'};
       cmd_aocl_run = './lbp_host %s %d %d %d %d'; % file width height radius samples
   end
   
   methods(Access = public)
       function [lbp, duration] = openCl(self, img)
          % Function for openCl solution with LBP operator
          % img contains the grayscale image
          % lbp should contain the processed image and is saved in maingui
          % as return value
          if isempty(img)
              disp("No image found!");
          else
              disp("Image found!");              
              
              fname = self.write_lum_data_file(img);       
              
              [pathstr,name,ext] = fileparts(fname);
              
              self.ttd(fname, [self.target_root, '/ocl_data']);
              %self.cmd([self.cmd_aocl_init, sprintf(self.cmd_aocl_run, fname, 256, 256, 1, 8)]);
              self.tth([self.target_root, '/ocl_data/', name, '.res'], [name, '.res']);
          end
          %system('ssh root@192.168.0.123 "source ./init_opencl.sh;aocl program /dev/acl0 boardtest.aocx;./lbp_host"')
          lbp = self.read_result_file([name, '.res']);
       end
       
       function lbp = vhdlHardware(self, img)
           % Function for hardware solution of LBP operator
           % img contains the grayscale image
           % lbp should contain the processed image and is saved in maingui
           % as return value
           if isempty(img)
               disp("No image found!");
           else
               disp("Image found!");
               
               fname = self.write_lum_data_file(img);       
              
               [pathstr,name,ext] = fileparts(fname);
              
               self.ttd(fname, [self.target_root, '/hw_data']);
               %self.cmd([self.cmd_aocl_init, sprintf(self.cmd_aocl_run, fname, 256, 256, 1, 8)]);
               self.tth([self.target_root, '/hw_data/', name, '.res'], [name, '.res']);
           end
           lbp = self.read_result_file([name, '.res']);
       end
   end
   
   methods(Access = private)
       function ret = ttd(self, source, target)
            % transfer to device
            % scp source connection:target
           cmd_scp      = 'scp %s %s:%s';   
           
           ret = system(sprintf(cmd_scp, source, self.connection, target));
       end
       
       function ret = tth(self, source, target)
            % transfer to host
            % scp connection:target source
           cmd_scp      = 'scp %s:%s %s';   
           
           ret = system(sprintf(cmd_scp, self.connection, source, target));
       end
       
       function ret = cmd(self, commands)
            % ssh connection "commands"
           cmd_ssh      = 'ssh %s "%s"';    
           
           ret = system(sprintf(cmd_ssh, self.connection, strjoin(commands, ';')));
       end
       
       function filename = write_lum_data_file(~, img)
           filename = [tempname, '.dat'];

           fileID = fopen(filename,'w');              
           fwrite(fileID, img(:, :, 1), 'uint8');              
           fclose(fileID);
       end
       
       function img = read_result_file(~, filename)
           fileID = fopen(filename,'r');
           array1d = fread(fileID);                        
           fclose(fileID);
           
           array2d = reshape(array1d, [256, 256]);
           
           img = mat2gray(array2d);
           
           figure('Name', 'Processed data'), imshow(img);
       end
   end
end