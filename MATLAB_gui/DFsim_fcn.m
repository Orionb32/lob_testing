function [avg1, avg2, avg3, avg4, lobEstimate] = DFsim_fcn(lobDeg,iq_flip,switch_pattern_index)
% 4 Antenna Pseudo-doppler DF Simulation
% Jim McCloskey
% (c) 2013 Geon Technologies, LLC
% 3 Dec 2013

%close all;
%clear all;

Fs = 100000; %complex baseband sample rate
Fc = 35000; % carrier frequency
%rotationFreq = 625;
%antennaDwell = 1/(rotationFreq*4); %Observation time in sec for each
%antenna
antennaDwell = 4.8e-4; %Observation time in sec for each antenna
numSamps = 10000; 

antenna = zeros(4,numSamps); % Array of 4 antennas separated by 1/4 wavelength
antennaSwitchOut = zeros(1,numSamps); %Output of 4:1 antenna switch

% antennaMarker - Used to create the red square wave on the plot. The square wave is high
% for antennas 1 & 2 and low for 3 & 4. Most pseudo-doppler systems compare
% the time between this antenna switch reference and the resulting doppler
% tone to determine LOB
antennaMarker = zeros(1,numSamps);

%lobDeg = 45 %Enter a LOB. See diagram for angle and antenna orientation
lobRad = lobDeg*pi/180;

% Generate a complex sinusoid that reaches each antenna at a delay
% determined by the LOB in radians and 1/4 of the signal wavelength.
% Here 1/4 wavelength = 1/4 sinewave cycle = pi/2
antenna(1,:) = complexCarrier(numSamps,Fs,Fc,0);
antenna(2,:) = complexCarrier(numSamps,Fs,Fc,-pi/2*sin(lobRad));
antenna(3,:) = complexCarrier(numSamps,Fs,Fc,-pi/2*(sin(lobRad)+cos(lobRad)));
antenna(4,:) = complexCarrier(numSamps,Fs,Fc,-pi/2*(cos(lobRad)));

%if(iq_flip==1)
%    antenna=complex(imag(antenna),real(antenna));
%end

% # samples to dwell on each antenna
%numSampsToDwell = Fs * antennaDwell;
%numSampsToDwell = numSampsToDwell/6;
numSampsToDwell = 10;

startSamp = 1;
stopSamp  = numSampsToDwell;
antennaSelect = 1;
counter = 1;
select_pattern = zeros(1,96,'int8');
% select_pattern(1,:) = [     1, 2, 1, 2, 1, 2, ...
%                                        2, 3, 2, 3, 2, 3, ...
%                                        3, 4, 3, 4, 3, 4, ...
%                                        4, 1, 4, 1, 4, 1];
% select_pattern(1,:) = [     1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, ...
%                                        3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, ...
%                                        3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, ...
%                                        1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4];
% select_pattern(1,:) = [     1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, ...
%                                        2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, ...
%                                        3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, ...
%                                        4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1];
select_pattern(1,:) = [     1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, ...
                                       2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, ...
                                       2, 4, 2, 4, 2, 4, 2, 4, 2, 4, 2, 4, 2, 4, 2, 4, 2, 4, 2, 4, 2, 4, 2, 4, ...
                                       4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1, 4, 1];


while true
    %Select a dwell's worth of data from each antenna in order
%     if counter == 1
%         switch_pattern_index
%         counter
%         startSamp
%         stopSamp
%     end
    antennaSwitchOut(startSamp:stopSamp) = antenna(select_pattern(switch_pattern_index,counter),startSamp:stopSamp);
    
    % Update the sample indices to get the next dwell worth of data
    startSamp = startSamp + numSampsToDwell;
    stopSamp  = stopSamp  + numSampsToDwell;
    if stopSamp > numSamps
        break
    end
    if (counter < length(select_pattern(switch_pattern_index,:)))
        counter = counter+1;
    else
        counter = 1;
    end 
    %antennaSelect = mod(counter,4)+1;
    
end %while

% Add a some noise if desired
SNR = 15;
noise_scale = 1/(10^((SNR)/20));
noise = noise_scale*randn(size(antennaSwitchOut));
noise = 0; % No noise
antennaSwitchOut = antennaSwitchOut + noise;

if(iq_flip==1)
    antennaSwitchOut =complex(imag(antennaSwitchOut ),real(antennaSwitchOut));
end

% Plot complex FFT of spectrum
%figure();
%plot_cfft (antennaSwitchOut,-Fs/2,Fs/2,1024,4,'Complex Input Spectra');

% Downconvert the samples to complex baseband
f_lpf = 10000; %Probably too wide baseband LPF
if(iq_flip==1)
    baseband = ddc(antennaSwitchOut, Fs, -Fc, f_lpf);
else
    baseband = ddc(antennaSwitchOut, Fs, Fc, f_lpf);
end

%figure();
%plot_cfft (baseband,-Fs/2,Fs/2,1024,4,'Complex Baseband Spectra');

demodData = FMDemod(baseband);
start_index = 961+32; %193;
%stop_index = start_index+959;
stop_index = start_index+719;

%Average values for plot (should be averages of peak detects)
avg1=max(demodData(start_index+100:start_index+200));
avg2=max(demodData(start_index+300:start_index+400));
avg3=max(demodData(start_index+500:start_index+600));
avg4=max(demodData(start_index+700:start_index+800));

%Lob Calc (derived from excel work)
lobEstimate = 15.60810*log(avg1/avg2)+45;
%Remove extremes of estimate
if(lobEstimate<0)
    lobEstimate=0;
end
if(lobEstimate>90)
    lobEstimate=90;
end

%Correct based on 2-4 antenna
if(avg3>4000)
   lobEstimate = 180-lobEstimate;
end

%figure();
%plot(demodData(201:1000));
plot(abs(demodData(start_index:stop_index)));
%plot((demodData(start_index:stop_index)));
hold on; % Hold plot so other lines can be overlaid
%plot(antennaMarker(201:1000),'r');

% This is phase offset is radians to make the sinewave overlay align correctly
% with the FM demodulated impulses; 
calRad = 0.15*pi;
offset = calRad + lobRad;

% The 3300 amplitude and usign the imag component is abitrary & makes the
% plot look nice
sineOverlay = 3300*imag(complexCarrier(numSamps,Fs,1/(4*antennaDwell),offset));
%plot(sineOverlay(201:1000),'g');
plot(abs(sineOverlay(start_index:stop_index)),'g');
line([960/4 960/4], [0 10000], 'Color', 'r');
line([960/4*2 960/4*2], [0 10000], 'Color', 'r');
%line([960/4*3 960/4*3], [0 5000], 'Color', 'r');
line([0 720],[4000 4000],'Color','r');

%Find first riding edge zero crossing of sine overlay. This sine overlay is
% ficticous - the real doppler sinewave work be generated by lowpass
% filtering the FM demod output
zeroCrossingIndex = findZeroCrossing(sineOverlay(201:1000));


lobCorrectionDeg = 334; % this was found emperically by trial/error. Makes the
                        % measured LOB agree with the desired lob 
                        % input at the beginning

% the 360/200 term is because there is 200 samples in one cycle of
% antenna switching. So i Think this technique has 360/200 = 1.8 deg
% of accuracy roughly
measuredLob = lobCorrectionDeg - (360/200)*zeroCrossingIndex;
