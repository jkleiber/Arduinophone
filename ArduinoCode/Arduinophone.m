clear
clc

% Setup the arduino
%a = arduino('Libraries', 'Adafruit/NeoPixel');
%lights = addon(a, 'Adafruit/NeoPixel', 'D6', 24);
%writeColor(lights, 1:24, 'red');

a = arduino();

time = 0;
data = 0;
i = 1;
samplingFreq = 50;
samplingT = 1 / samplingFreq;

minX = 1;
maxX = 250; %Maximum number of points on the plot at a time
maxT = maxX*samplingT; %Max number of seconds on plot at a time
minY = -2.5; %Minimum offset output voltage from microphone
maxY = 2.5; %Maximum offset output voltage from microphone

fig = figure(1);
subplot(3, 1, 1);
raw_data = plot(time, data);

subplot(3, 1, 2);
avg_data = plot(time, data);

subplot(3, 1, 3);
freq_domain = plot(time, data);

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
        minX = time(i - maxX);
        maxX = time(i);
    end
    
    A = avg_filter(amplifyAndOffset(data));
    [f, P1] = transform(data, samplingFreq);
    
    set(raw_data, 'XData', time);
    set(raw_data, 'YData', amplifyAndOffset(data));
    
    set(avg_data, 'XData', time);
    set(avg_data, 'YData', A);
    
    set(freq_domain, 'XData', f);
    set(freq_domain, 'YData', P1);
    
    subplot(3,1,1);
    axis([time(minX) maxX minY maxY]);
    subplot(3,1,2);
    axis([time(minX) maxX minY maxY]);
    subplot(3,1,3);
    axis([-inf inf 0 1]);
    
    pause(samplingT);
end

function A = amplifyAndOffset(data)
    A = 21 * detrend(data,0);
end

function V = avg_filter(data)
    bk = (1/3) * ones(3, 1);
    V = filter(bk, 1, data);
end

function [f, P1] = transform(data, fsamp)
    L = size(data,2);
    
    Y = fft(data);
    f = fsamp*(0:(L/2))/L;
    
    P2 = abs(Y/L);
    P1 = P2(1:floor(L/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);   
end