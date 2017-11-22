close all
clear
clc

% Setup the arduino
a = arduino('COM11', 'Uno', 'Libraries', 'Adafruit/NeoPixel');
lights = addon(a, 'Adafruit/NeoPixel', 'D6', 24, 'NeoPixelType', 'RGB');
writeColor(lights, 1:24, 'white');

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

%Keep track of latest 100 points
subvector_len = 100; %Take the 100 most recent data points and FFT to find frequency
minIndex = 1; %This should always be i, as it is the most recent data index

fig = figure(1);
set(fig, 'Units', 'pixels');
set(fig, 'Position', [100 100 900 600]);

subplot(3, 1, 1);
raw_data = plot(time, data);
xlabel('t (sec)')
ylabel('Amplitude (dB)')
title('Raw Input Signal V(t)')

subplot(3, 1, 2);
avg_data = plot(time, data);
xlabel('t (sec)')
ylabel('Amplitude (dB)')
title('Filtered Input Signal L(t)')

subplot(3, 1, 3);
freq_domain = plot(time, data);
xlabel('f (Hz)')
ylabel('Amplitude (dB)')
title('Single-Sided Amplitude Spectrum of L(t)')


A = [];
FFT = [];

tic %start the timer
time(1) = toc;
data(1) = getDecibels(readVoltage(a, 'A0'));
while ishandle(fig)
    i = i + 1;
    
    data(i) = getDecibels(readVoltage(a, 'A0'));
    time(i) = toc;
    
    if time(i) > maxT
        minTime = time(i) - maxT;
        maxTime = time(i);
    else
        maxTime = maxT;
    end
    
    if i > subvector_len
        minIndex = i - subvector_len;
    end
    
   % data = detrend(data, 0);
    
    A = avg_filter(data);
    [P, f] = transform(data(minIndex:i), samplingFreq);
    
    if i > 3
        %Write Color to the LEDs
    	writeColor(lights, 1:24, chooseColor(P, f, samplingFreq));
    end
    
    if mod(i, 5) == 0
        set(raw_data, 'XData', time);
        set(raw_data, 'YData', data);
    
        set(avg_data, 'XData', time);
        set(avg_data, 'YData', A);
    
        set(freq_domain, 'XData', f);
        set(freq_domain, 'YData', P);
        
        subplot(3,1,1);
        axis([minTime maxTime -inf inf]);
        subplot(3,1,2);
        axis([minTime maxTime -inf inf]);
        subplot(3,1,3);
        axis([-inf inf -inf inf]);
    end
    pause(samplingT);
    
    if not(ishandle(fig))
        break
    end
end

function A = amplify(data)
    A = 21 * data;
end

% function [P, f] = transform(data, fsamp, start, endId)
%     signal = detrend(data, 0);
%     %len = length(signal);
%     len = endId - start + 1;
%     signal = splitVector(signal, start, endId);
%     
%     nfft = 2^nextpow2(len);
%     f = (fsamp/2) * linspace(0,1,nfft/2+1);
%     
%     P = abs(fft(signal, nfft))/len;
%     P = 2 * abs(P(1:nfft/2+1)); %Return single-sided spectrum
% end
function [P, f] = transform(data, fsamp)
    signal = detrend(data, 0);
    len = length(signal);
    Y = fft(signal);
    
    P2 = abs(Y/len);
    P1 = P2(1:floor(len/2)+1);
    P1(2:end-1) = 2*P1(2:end-1);
    
    f = fsamp*(0:(len/2))/len;
    P = P1;
end

function C = chooseColor(P, ff, fsamp)
    [pp, f] = findpeaks(P, ff, 'SortStr', 'descend');
    
    C = ones(1,3);
    topFreq = 0;
    topAmp = 0;
    
    for fs = 1:length(f)
        if f(fs) > 100
            topFreq = f(fs);
            topAmp = pp(fs);
        end
    end
    
    
    R = [0.9, 0.1, 0.1];
    O = [0.9, 0.5, 0.1];
    Y = [0.9, 0.9, 0];
    G = [0.1, 0.9, 0.1];
    B = [0.25, 0.25, 0.9];
    I = [0.5, 0.1, 0.9];
    V = [0.9, 0.1, 0.9];
    
    COLORS = [R; O; Y; G; B; I; V];
    
    stepSize = ((fsamp-100)*1/(2*7));
    
    for i=1:7
       if topFreq < stepSize*i
           C = COLORS(i, :);
           break;
       end
    end
    
    if topAmp < 0.1
        C = [0, 0, 0];
    end

end

function f = avg_filter(data)
    detrend(data,0);
    bk = (1/3) * ones(3, 1);
    f = filter(bk, 1, data);
end

%http://www.sengpielaudio.com/calculator-gainloss.htm
function db = getDecibels(v)
    db = 20 * log(v); 
end