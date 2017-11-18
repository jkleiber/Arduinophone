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

% Last Modified by GUIDE v2.5 17-Nov-2017 10:07:06

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

function d = deNaN(num)
    if isnan(num)
        d = 0;
    else
        d = num;
    end
end

function [xx, tt] = generateSignal(handles)
    tt = 0:0.001:10;

    A1 = deNaN(str2double(get(handles.editAmp1, 'String')));
    P1 = deNaN(str2double(get(handles.editPhs1, 'String')));
    F1 = deNaN(str2double(get(handles.editFreq1, 'String')));
    
    A2 = deNaN(str2double(get(handles.editAmp2, 'String')));
    P2 = deNaN(str2double(get(handles.editPhs2, 'String')));
    F2 = deNaN(str2double(get(handles.editFreq2, 'String')));
    
    A3 = deNaN(str2double(get(handles.editAmp3, 'String')));
    P3 = deNaN(str2double(get(handles.editPhs3, 'String')));
    F3 = deNaN(str2double(get(handles.editFreq3, 'String')));
    
    xx = A1*cos(2*pi*F1*tt + P1) + A2*cos(2*pi*F2*tt + P2) + A3*cos(2*pi*F3*tt + P3);
end

function [P, f] = transform(data, fsamp)
    signal = detrend(data, 0);
    len = length(signal);
    
    nfft = 2^nextpow2(len);
    f = (fsamp/2) * linspace(0,1,nfft/2+1);
    
    P = abs(fft(signal, nfft))/len;
    P = 2 * abs(P(1:nfft/2+1)); %Return single-sided spectrum
end

function V = avg_filter(data)
    detrend(data,0);
    bk = (1/3) * ones(3, 1);
    V = filter(bk, 1, data);
end

function C = chooseColor(P, ff)
    [pp, f] = findpeaks(P, ff, 'SortStr', 'descend');
    
    C = ones(1,3);
    weightedAmp = 0;
    avg_freq = 0;
    for i=1:3
        if i < length(f)
            text(f(i) + 0.2, pp(i)+0.04, num2str(f(i)));
            
            hold on
            plot(f(i), pp(i), 'rv')
            hold off
            
            weightedAmp = weightedAmp + pp(i)/i;
            avg_freq = avg_freq + ff(i);
        end
    end
    
    weightedAmp = weightedAmp;
    avg_freq = avg_freq / 3;
    
    avg_freq
    weightedAmp
end

function cc = updateParams(handles)
    axes(handles.axes1);
    cla;

    %XXX = rand(1, 10*200 + 1);

    [xx, tt] = generateSignal(handles);

    plot(tt, avg_filter(xx), 'red')
    %plot(tt, avg_filter(XXX))

    xlabel('t (sec)')
    ylabel('Amplitude (Volts)')
    title('Sinusoidal Waveform Input V(t)')

    axes(handles.axes2);
    cla;

    [P, f] = transform(avg_filter(xx), 1000);
    %[P, f] = transform(avg_filter(XXX), 200);
    plot(f, P, 'red')
    xlabel('f (Hz)')
    ylabel('Amplitude (Volts)')
    title('Single-Sided Amplitude Spectrum of V(t)')

    cc = chooseColor(P, f);
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
    plot(tt, xx, 'red')
    xlabel('t (sec)')
    ylabel('Amplitude (Volts)')
    title('Sinusoidal Waveform Input V(t)')
    
    axes(handles.axes2);
    plot(tt, xx, 'red')
    xlabel('f (Hz)')
    ylabel('Amplitude (Volts)')
    title('Single-Sided Amplitude Spectrum of V(t)')
    
    axes(handles.colorBox);
    plot(0);
    title('Color Output');
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

    cc = updateParams(handles);
    
    axes(handles.colorBox);
    set(handles.colorBox, 'Color', cc);
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


% --- Executes on button press in btnArduino.
function btnArduino_Callback(hObject, eventdata, handles)
% hObject    handle to btnArduino (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    % Setup the arduino
    a = arduino('COM11', 'Uno', 'Libraries', 'Adafruit/NeoPixel');
    lights = addon(a, 'Adafruit/NeoPixel', 'D6', 24, 'NeoPixelType', 'RGB');
    
    cc = updateParams(handles);
end
