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

% Last Modified by GUIDE v2.5 11-Aug-2017 15:27:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @maingui_OpeningFcn, ...
                   'gui_OutputFcn',  @maingui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
               
global currentImage;
global result;
global fileCount;

fileCount = 0;
result = struct([]);
currentImage = 'empty';
               
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


% --- Executes on button press in btnGrayscale.
function btnGrayscale_Callback(hObject, eventdata, handles)
% hObject    handle to btnGrayscale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global currentImage;
currentImage = handles.core.grayscale();
imagesc(currentImage, 'Parent', handles.axes1);
axis off;


% --- Executes on button press in btnSendOcl.
function btnSendOcl_Callback(hObject, eventdata, handles)
% hObject    handle to btnSendOcl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global currentImage;
global result;
global fileCount;
if currentImage == 'empty'
    msgbox('Please open file and do grayscale first!');
else
    % time measurement of function below
    tic;
    result.image(fileCount) = handles.com.openCl(currentImage);
    result.lbpOclTime(fileCount) = toc;
    fileCount = fileCount + 1;
end


% --- Executes on button press in btnSendHw.
function btnSendHw_Callback(hObject, eventdata, handles)
% hObject    handle to btnSendHw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global currentImage;
global result;
global fileCount;
if currentImage == 'empty'
    msgbox('Please open file and do grayscale first!');
else
    % time measurement of function below
    tic;
    result.image(fileCount) = handles.com.vhdlHardware(currentImage);
    result.lbpHwTime(fileCount) = toc;
    fileCount = fileCount + 1;
end


% --- Executes on button press in btnResult.
function btnResult_Callback(hObject, eventdata, handles)
% hObject    handle to btnResult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btnOpen.
function btnOpen_Callback(hObject, eventdata, handles)
% hObject    handle to btnOpen (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.core.openImage();
handles.core.displayRawImage(handles.axes1);
axis off;
