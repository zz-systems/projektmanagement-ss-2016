function varargout = maingui(varargin)
% MAINGUI MATLAB code for maingui.fig
%      MAINGUI, by itself, creates a new MAINGUI or raises the existing
%      singleton*.
%
%      H = MAINGUI returns the handle to a new MAINGUI or the handle to
%      the existing singleton*.
%
%      MAINGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAINGUI.M with the given input arguments.
%
%      MAINGUI('Property','Value',...) creates a new MAINGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before maingui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to maingui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help maingui

% Last Modified by GUIDE v2.5 18-Sep-2017 16:52:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @maingui_OpeningFcn, ...
                   'gui_OutputFcn',  @maingui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
               

addpath('LBP Reference implementation');


               
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before maingui is made visible.
function maingui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to maingui (see VARARGIN)

% Choose default command line output for maingui
handles.output = hObject;
handles.core = ImgCore();
handles.com = BoardCom();

global fileCount;
global currentImage;

fileCount = 0;
currentImage = [0,0];

clearvars -global result;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes maingui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = maingui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btnLBPOperations.
function btnLBPOperations_Callback(hObject, eventdata, handles)
% hObject    handle to btnLBPOperations (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global currentImage;
global result;
global fileCount;
if isempty(currentImage)
    msgbox('Please open file first!');
else
    % start LBP with OpenCL solution
    [result(fileCount).oclImage, systemTime, result(fileCount).lbpOclTime] = handles.com.openCl(imresize(currentImage(:, :, 1), [256 256]));
    result(fileCount).lbpOclHist = hist(result(fileCount).oclImage(:),0:255);
    
    % start LBP with VHDL solution
    [result(fileCount).hwImage, systemTime, result(fileCount).lbpHwTime] = handles.com.vhdlHardware(imresize(currentImage(:, :, 1), [256 256]));
    result(fileCount).lbpHwHist = hist(result(fileCount).hwImage(:),0:255);
    
    % display both calculated LBP images on their axis
    handles.core.displayImage(result(fileCount).hwImage, handles.axVHDL);
    handles.core.displayImage(result(fileCount).oclImage, handles.axOCl);
    axis off;
end


% --- Executes on button press in btnResult.
function btnResult_Callback(hObject, eventdata, handles)
% hObject    handle to btnResult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global result;
resultgui(result);


% --- Executes on button press in btnOpen.
function btnOpen_Callback(hObject, eventdata, handles)
% hObject    handle to btnOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global fileCount;
global currentImage;
global result;

handles.core.openImage();
fileCount = fileCount + 1;
set(handles.txtFileCount,'String',fileCount);
handles.core.displayRawImage(handles.axRef);

% convert opened image to grayscale
currentImage = handles.core.grayscale();

% build lbp variant with given algorithm in matlab
tic;
lbp_img = lbp_sir(imresize(currentImage(:, :, 1), [256 256]));
result(fileCount).lbpMlTime = toc;

result(fileCount).mlImage = uint8(cat(3,lbp_img, lbp_img, lbp_img));
result(fileCount).mlHist = hist(result(fileCount).mlImage(:),0:255);
handles.core.displayImage(result(fileCount).mlImage, handles.axMatlabLBP);
axis off;
