function varargout = UserInterface(varargin)
% USERINTERFACE MATLAB code for UserInterface.fig
%      USERINTERFACE, by itself, creates a new USERINTERFACE or raises the existing
%      singleton*.
%
%      H = USERINTERFACE returns the handle to a new USERINTERFACE or the handle to
%      the existing singleton*.
%
%      USERINTERFACE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in USERINTERFACE.M with the given input arguments.
%
%      USERINTERFACE('Property','Value',...) creates a new USERINTERFACE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before UserInterface_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to UserInterface_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help UserInterface

% Last Modified by GUIDE v2.5 06-Nov-2017 15:31:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @UserInterface_OpeningFcn, ...
                   'gui_OutputFcn',  @UserInterface_OutputFcn, ...
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
end

function [xx, tt] = generateSignal(handles)
    tt = 0:0.005:2*pi;

    A1 = str2double(get(handles.editAmp1, 'String'));
    P1 = str2double(get(handles.editPhs1, 'String'));
    F1 = str2double(get(handles.editFreq1, 'String'));
    
    A2 = str2double(get(handles.editAmp2, 'String'));
    P2 = str2double(get(handles.editPhs2, 'String'));
    F2 = str2double(get(handles.editFreq2, 'String'));
    
    A3 = str2double(get(handles.editAmp3, 'String'));
    P3 = str2double(get(handles.editPhs3, 'String'));
    F3 = str2double(get(handles.editFreq3, 'String'));
    
    xx = A1*cos(F1*tt + P1) + A2*cos(F2*tt + P2) + A3*cos(F3*tt + P3);
end

function [f, P2] = transform(data, fsamp)
    L = size(data,2);
    
    Y = fft(data);
    f = fsamp*(0:L)/L;
    
    P2 = abs(Y/L);  
end

function V = avg_filter(data)
    detrend(data,0);
    bk = (1/3) * ones(3, 1);
    V = filter(bk, 1, data);
end

% --- Executes just before UserInterface is made visible.
function UserInterface_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to UserInterface (see VARARGIN)

% Choose default command line output for UserInterface
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% This sets up the initial plot - only do when we are invisible
% so window can get raised using UserInterface.
if strcmp(get(hObject,'Visible'),'off')
    [xx,tt] = generateSignal(handles);
    axes(handles.axes1);
    plot(tt, xx)
    xlabel('t (sec)')
    ylabel('Amplitude (Volts)')
    title('Sinusoidal Waveform')
    
    axes(handles.axes2);
    xlabel('f (Hz)')
    ylabel('Amplitude (Volts)')
    title('Frequency Spectrum of Sinusoid')
end

% UIWAIT makes UserInterface wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = UserInterface_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in btnUpdate.
function btnUpdate_Callback(hObject, eventdata, handles)
% hObject    handle to btnUpdate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.axes1);
cla;

[xx, tt] = generateSignal(handles);
plot(tt, avg_filter(xx))
xlabel('t (sec)')
ylabel('Amplitude (Volts)')
title('Sinusoidal Waveform')

axes(handles.axes2);
cla;

[f, P] = transform(avg_filter(xx), 1000);
plot(f, P)
xlabel('f (Hz)')
ylabel('Amplitude (Volts)')
title('Frequency Spectrum of Sinusoid')

end

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    file = uigetfile('*.fig');
    if ~isequal(file, 0)
        open(file);
    end
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.figure1)
end

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)
end

function editAmp1_Callback(hObject, eventdata, handles)
% hObject    handle to editAmp1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmp1 as text
%        str2double(get(hObject,'String')) returns contents of editAmp1 as a double
end

% --- Executes during object creation, after setting all properties.
function editAmp1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmp1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function editPhs1_Callback(hObject, eventdata, handles)
% hObject    handle to editPhs1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPhs1 as text
%        str2double(get(hObject,'String')) returns contents of editPhs1 as a double
end

% --- Executes during object creation, after setting all properties.
function editPhs1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPhs1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function editFreq1_Callback(hObject, eventdata, handles)
% hObject    handle to editFreq1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFreq1 as text
%        str2double(get(hObject,'String')) returns contents of editFreq1 as a double
end

% --- Executes during object creation, after setting all properties.
function editFreq1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFreq1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function editAmp2_Callback(hObject, eventdata, handles)
% hObject    handle to editAmp2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmp2 as text
%        str2double(get(hObject,'String')) returns contents of editAmp2 as a double
end

% --- Executes during object creation, after setting all properties.
function editAmp2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmp2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function editPhs2_Callback(hObject, eventdata, handles)
% hObject    handle to editPhs2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editPhs2 as text
%        str2double(get(hObject,'String')) returns contents of editPhs2 as a double
end

% --- Executes during object creation, after setting all properties.
function editPhs2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPhs2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function editFreq2_Callback(hObject, eventdata, handles)
% hObject    handle to editFreq2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFreq2 as text
%        str2double(get(hObject,'String')) returns contents of editFreq2 as a double
end

% --- Executes during object creation, after setting all properties.
function editFreq2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFreq2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function editAmp3_Callback(hObject, eventdata, handles)
% hObject    handle to editAmp3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAmp3 as text
%        str2double(get(hObject,'String')) returns contents of editAmp3 as a double
end

% --- Executes during object creation, after setting all properties.
function editAmp3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAmp3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end

function editPhs3_Callback(hObject, eventdata, handles)
    % hObject    handle to editPhs3 (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of editPhs3 as text
    %        str2double(get(hObject,'String')) returns contents of editPhs3 as a double
end

% --- Executes during object creation, after setting all properties.
function editPhs3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editPhs3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


function editFreq3_Callback(hObject, eventdata, handles)
% hObject    handle to editFreq3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editFreq3 as text
%        str2double(get(hObject,'String')) returns contents of editFreq3 as a double
end

% --- Executes during object creation, after setting all properties.
function editFreq3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editFreq3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end
