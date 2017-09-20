function varargout = resultgui(varargin)
% RESULTGUI MATLAB code for resultgui.fig
%      RESULTGUI, by itself, creates a new RESULTGUI or raises the existing
%      singleton*.
%
%      H = RESULTGUI returns the handle to a new RESULTGUI or the handle to
%      the existing singleton*.
%
%      RESULTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RESULTGUI.M with the given input arguments.
%
%      RESULTGUI('Property','Value',...) creates a new RESULTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before resultgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to resultgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help resultgui

% Last Modified by GUIDE v2.5 29-Aug-2017 15:30:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @resultgui_OpeningFcn, ...
                   'gui_OutputFcn',  @resultgui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before resultgui is made visible.
function resultgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to resultgui (see VARARGIN)

% Choose default command line output for resultgui
handles.output = hObject;
handles.core = ImgCore();

[m,n] = size(varargin{1,1});
col1=zeros(m,n);
col2=zeros(m,n);
col3=zeros(m,n);
col4=zeros(m,n);
col5=zeros(m,n);
for i = 1:n
    col1(i) = sprintf("%.2f ms", varargin{1,1}(i).lbpOclTime);
    col2(i) = sprintf("%.2f ms", varargin{1,1}(i).lbpHwTime);
    col3(i) = sprintf("%.2f ms", varargin{1,1}(i).lbpMlTime);
    col4(i) = handles.core.relError(varargin{1,1}(i).mlHist, varargin{1,1}(i).lbpOclHist);
    col5(i) = handles.core.relError(varargin{1,1}(i).mlHist, varargin{1,1}(i).lbpHwHist);
end
colNames = {'OpenCl', 'VHDL', 'Matlab Reference', 'Relative Error Matlab/OpenCL', 'Relative Error Matlab/VHDL'};
set(handles.tblResult, 'Data', [col1',col2',col3',col4',col5'], 'ColumnName', colNames);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes resultgui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = resultgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
