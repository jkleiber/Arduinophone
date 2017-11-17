close all
clear
clc

% Setup the arduino
a = arduino('COM11', 'Uno', 'Libraries', 'Adafruit/NeoPixel');
lights = addon(a, 'Adafruit/NeoPixel', 'D6', 24, 'NeoPixelType', 'RGB');
writeColor(lights, 1:24, 'blue');

%a = arduino();

time = 0;
data = 0;
i = 1;
samplingFreq = 1000;
samplingT = 1 / samplingFreq;

fftStart = 1;

secondsToShow = 10;
minTime = 0;
maxTime = 0;
maxXShow = samplingFreq * secondsToShow; %Maximum number of points on the plot at a time
maxT = maxXShow*samplingT; %Max number of seconds on plot at a time
minY = -2.5; %Minimum offset output voltage from microphone
maxY = 2.5; %Maximum offset output voltage from microphone

fig = figure(1);
set(fig, 'Units', 'pixels');
set(fig, 'Position', [100 100 900 600]);

subplot(3, 1, 1);
raw_data = plot(time, data);
xlabel('t (sec)')
ylabel('Amplitude (Volts)')
title('Raw Input Signal V(t)')

subplot(3, 1, 2);
avg_data = plot(time, data);
xlabel('t (sec)')
ylabel('Amplitude (Volts)')
title('Filtered Input Signal F(t)')

subplot(3, 1, 3);
freq_domain = plot(time, data);
xlabel('f (Hz)')
ylabel('Amplitude (Volts)')
title('Single-Sided Amplitude Spectrum of F(t)')


A = [];
FFT = [];

tic %start the timer
time(1) = toc;
data(1) = readVoltage(a, 'A0');
while ishandle(fig)
    i = i + 1;
    
    data(i) = readVoltage(a, 'A0');
    time(i) = toc;
    
    if time(i) > maxT
        minTime = time(i) - maxT;
        maxTime = time(i);
    else
        maxTime = maxT;
    end
    
    A = avg_filter(amplifyAndOffset(data));
    [P, f] = transform(data, samplingFreq, fftStart, i);
    
    set(raw_data, 'XData', time);
    set(raw_data, 'YData', amplifyAndOffset(data));
    
    set(avg_data, 'XData', time);
    set(avg_data, 'YData', A);
    
    set(freq_domain, 'XData', f);
    set(freq_domain, 'YData', P);
    
    subplot(3,1,1);
    axis([minTime maxTime minY maxY]);
    subplot(3,1,2);
    axis([minTime maxTime minY maxY]);
    subplot(3,1,3);
    axis([-inf inf 0 1]);
    
    pause(samplingT);
    
    if not(ishandle(fig))
        break
    end
end

function A = amplifyAndOffset(data)
    A = 21 * detrend(data,0);
end

function [P, f] = transform(data, fsamp, start, endId)
    signal = detrend(data, 0);
    %len = length(signal);
    len = endId - start + 1;
    signal = splitVector(signal, start, endId);
    
    nfft = 2^nextpow2(len);
    f = (fsamp/2) * linspace(0,1,nfft/2+1);
    
    P = abs(fft(signal, nfft))/len;
    P = 2 * abs(P(1:nfft/2+1)); %Return single-sided spectrum
end

function f = avg_filter(data)
    detrend(data,0);
    bk = (1/3) * ones(3, 1);
    f = filter(bk, 1, data);
end

function V = splitVector(old, start, endId)
    len = endId - start + 1;
    V = zeros(len,0);
    ii = 1;
    for i=start:endId
        V(ii) = old(i);
        ii = ii + 1;
    end
end