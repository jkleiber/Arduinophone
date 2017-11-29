%Clear everything
close all
clear
clc

% Setup the arduino
a = arduino('COM11', 'Uno', 'Libraries', 'Adafruit/NeoPixel');

%Declare and setup the lights
%We use the RGB lights, not the GRB lights, and the strip is 24 LED lights
%long.
lights = addon(a, 'Adafruit/NeoPixel', 'D6', 24, 'NeoPixelType', 'RGB');

%Set the default color to white until there is a signal
writeColor(lights, 1:24, 'white');

%Set the time to 0.
time = 0;

%set the first data point to 0.
data = 0;

%Set data index to 1. We will increment this value to collect data for our
%matrix
i = 1;

%Sampling frequency is 1000
samplingFreq = 1000;

%Sampling period is 1/sampling frequency
samplingT = 1 / samplingFreq;

%Set start point of FFT data. This tracks the minimum index for the fast
%fourier transform
fftStart = 1;

secondsToShow = 10; %Show 10 seconds of data on the real time plot
minTime = 0; %Minimum time to show
maxTime = 0; %Maximum time to show
maxXShow = samplingFreq * secondsToShow; %Maximum number of points on the plot at a time
maxT = maxXShow*samplingT; %Max number of seconds on plot at a time
minY = -2.5; %Minimum offset output voltage from microphone
maxY = 2.5; %Maximum offset output voltage from microphone

%Keep track of latest 100 points
subvector_len = 100; %Take the 100 most recent data points and FFT to find frequency
minIndex = 1; %This should always be i, as it is the most recent data index

fig = figure(1); %open the figure
set(fig, 'Units', 'pixels'); %Make the figure a certain unit
set(fig, 'Position', [100 100 900 600]); %Make the figure a certain size

%First subplot is raw data
subplot(3, 1, 1);
raw_data = plot(time, data); %Set the variable so we can use set() in the loop
xlabel('t (sec)') %Time on x-axis
ylabel('Amplitude (dB)') %Decibels on y-axis
title('Raw Input Signal V(t)') %The raw signal will be displayed

%The second subplot is filtered data
subplot(3, 1, 2);
avg_data = plot(time, data); %Set the variable to be the avg data plot
xlabel('t (sec)') %Time on X
ylabel('Amplitude (dB)') %Decibels on Y
title('Filtered Input Signal L(t)') %title of the subplot is a filtered input

%The third subplot is the frequency domain representation
subplot(3, 1, 3);
freq_domain = plot(time, data); %The variable to track this subplot
xlabel('f (Hz)') %frequency on the X axis
ylabel('Amplitude (dB)') %the amplitude of the signal on the Y axis
title('Single-Sided Amplitude Spectrum of L(t)') %Title is the frequency domain

A = []; %This vector is for the averaged data
FFT = []; %this vector is for the FFT data

tic %start the timer
time(1) = toc; %get the first time
data(1) = getDecibels(readVoltage(a, 'A0'));%get the first amplitude

%Run the program while the user hasn't closed the figure
while ishandle(fig)
    i = i + 1;%increment the index for a new vector addition
    
    data(i) = getDecibels(readVoltage(a, 'A0'));%get the i-th voltage reading
    time(i) = toc;%get the i-th time reading
    
    %If the more than the allowed time to show has passed, set a reference 
    %for a moving plot display
    if time(i) > maxT
        minTime = time(i) - maxT; %The minimum time to display should be 
                                  %made a reference point
        maxTime = time(i); %The maximum time should be the current time
    else
        maxTime = maxT; %Otherwise, business as usual until the first maxT has passed
    end
    
    %Sets the minimum index for the FFT by waiting for the number of points
    %to exceed the length of the allowed sample of FFT. We don't want the
    %FFT to use too old data because that is not a representation of the
    %current input
    if i > subvector_len
        minIndex = i - subvector_len; %update the minimum index
    end
    
    A = avg_filter(data);%Average the data 
    [P, f] = transform(data(minIndex:i), samplingFreq); %Find the frequency spectrum of the data
    
    %Only write color to the LEDs if there are 3 data points which is the
    %minimum for chooseColor() to work
    if i > 3
        %Write Color to the LEDs
    	writeColor(lights, 1:24, chooseColor(P, f, samplingFreq));
    end
    
    %We only update the graph every five samples in order to save
    %processing power
    if mod(i, 5) == 0
        set(raw_data, 'XData', time); %update the rawdata X (time)
        set(raw_data, 'YData', data); %update the rawdata Y
    
        set(avg_data, 'XData', time); %update averaged data time
        set(avg_data, 'YData', A); %update the plot to show the averaged values
    
        set(freq_domain, 'XData', f); %Update to show frequency domain frequencies
        set(freq_domain, 'YData', P); %update to show the decibel peaks
        
        subplot(3,1,1); %set subplot 1 to active
        axis([minTime maxTime -inf inf]); %set the bounds of the first subplot
        
        subplot(3,1,2); %set subplot 2 to active
        axis([minTime maxTime -inf inf]); %Set subplot 2 bounds
        
        subplot(3,1,3); %set subplot 3 to active
        axis([-inf inf -inf inf]); %set subplot 3 bounds
    end
    pause(samplingT); %pause for the sampling frequency amounts
    
    %If the user has closed the window, end the program
    if not(ishandle(fig))
        break
    end
end

%Bandstop filter
function B = bandstop(P, f)
% This function implements a bandstop filter. Our microphone cannot read
% frquencies under 100Hz, however the FFT will detect some noise as under
% 100Hz. Therefore, these values need to be attenuated before output to the
% lights
%
% Arguments:
%   P: Power spectrum (amplitude)
%   f: frequency where amplitude occurs
%
%Returns:
%   B: the power spectrum after the bandstop filter has been applied.

    %Set index to 1
    ii = 1;
    
    %While the frequency is less than 100Hz...
    while f(ii) < 100
        P(ii) = 0; %set power to 0
        ii = ii + 1;%increment index
    end
    
    B = P; %Return the new power spectrum
end

%Fast Fourier Transform:
%Credit to: https://www.mathworks.com/help/matlab/ref/fft.html
%for teaching us how to do this
function [P, f] = transform(data, fsamp)
%This function finds the frequency domain representation of an input signal
%and returns a single sided spectrum analysis. This will be used by the
%LEDs to choose the color
%
%Arguments:
%   data: the decibel inputs
%   fsamp: the sampling frequency
%
%Returns:
%   P: amplitudes of all signals
%   f: frequencies where the amplitudes occur

    signal = detrend(data, 0);%Remove trending from the signal (set the middle value to 0)
    len = length(signal); %Get signal length
    Y = fft(signal); %Perform the fast fourier transform
    
    P2 = abs(Y/len); %Get the magnitude of the fourier transform
    P1 = P2(1:floor(len/2)+1); %Set the negative side to be the positive side
    P1(2:end-1) = 2*P1(2:end-1); %Double amplitude to merge values to single side
    
    f = fsamp*(0:(len/2))/len; %Find the possible frequencies for the FFT
    P = bandstop(P1, f); %Apply a bandstop filter to clear the incorrect frequencies
end

%Chooses the color of the LED output
function C = chooseColor(P, ff, fsamp)
%This function takes the single sided spectrum as input, and returns the
%correct color for the lights to output to

    %Find the top frequencies that the signal produces
    [pp, f] = findpeaks(P, ff, 'SortStr', 'descend');
    
    %Set the RGB to [1 1 1], or black (off)
    C = ones(1,3);
    topFreq = 0; %set top frequency to default
    topAmp = 0; %set top amplitude to default
    
    %loop through the best frequencies
    for fs = 1:length(f)
        if f(fs) > 100 %only consider a frequency greater than 100 Hz (readable)
            topFreq = f(fs); %set as top frequency
            topAmp = pp(fs); %Set as top amplitude
            break; %break out of the loop if acceptable value found
        end
    end
    
    scale = 1; %Create variable to adjust brightness
    if topAmp <= 1 %Reduce brightness if input signal is very quiet
        scale = 0.5; %cut brightness to 1/2
    elseif topAmp <= 2 %Reduce brightness less if it is a bit louder
        scale = 0.667; %cut brightness to 2/3
    elseif topAmp <= 3 %Almost loud enough to not be cut
        scale = 0.75; %Reduce brightness to 3/4
    end
    
    R = [0.9, 0.1, 0.1]; %Red
    O = [0.9, 0.5, 0.1]; %Orange
    Y = [0.9, 0.9, 0]; %Yellow
    G = [0.1, 0.9, 0.1]; %Green
    B = [0.25, 0.25, 0.9]; %Blue
    I = [0.5, 0.1, 0.9]; %Indigo
    V = [0.9, 0.1, 0.9]; %Violet
    
    %Colors form a lookup table. Make sure to scale the output accordingly
    %using vector multiplication
    COLORS = scale * [R; O; Y; G; B; I; V];
    
    %The size of each region in the table should be determined by the
    %usable frequency region
    stepSize = ((fsamp/2) - 100)*7;
    
    %Go through the values until we find the correct region
    for i=1:7
       if topFreq < stepSize*i %if we are in the right region
           C = COLORS(i, :);%set C to the corresponding color
           break; %break the loop
       end
    end
    
    %Disregard all amplitudes less than 0.1 (background noise)
    if topAmp < 0.1
        C = [0, 0, 0]; %Color will be OFF
    end

end

%3 point averaging filter
function f = avg_filter(data)
    detrend(data,0); %trend the data to zero to avoid weird offsetting
    bk = (1/3) * ones(3, 1); %apply the 3 point filter coefficients
    f = filter(bk, 1, data); %apply the filter
end

%Credit to: http://www.sengpielaudio.com/calculator-gainloss.htm
%for help learning how to convert from voltage to decibels with our
%microphone.
function db = getDecibels(v)
    db = 20 * log(v); %use the db = 20 * log10(v/v0) v0 = 1 equation to convert
end