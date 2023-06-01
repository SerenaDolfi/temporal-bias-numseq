%Example on how to create audio files from event and intervals vectors
%Serena Dolfi, March 2023, serena.dolfi@phd.unipd.it

clear
clc

%% Load stimuli and select stimulus to play
%Created with the script "Generate_sequences"
stim_table = readtable('sequences_stimuli.xlsx'); 

%Which sequence?
which_seq = 1; %idx of selected stim

%Which sound frequency to use to play the events?
which_freq = 400;

%% Retrieve info and prepare vectors 

%Retrieve info and features
file_name = stim_table.name{which_seq};
n = stim_table.n(which_seq);
temp_vec_ied = stim_table.ied_vec(which_seq);
temp_vec_int = stim_table.int_vec(which_seq);

%Prepare to build the audio file
save_name = strcat(file_name,'.wav');

vec_ied_frame = str2double(split(temp_vec_ied," "))';
vec_ied_frame_s = vec_ied_frame.*0.01667; %transform in seconds (considering 1 frame == 0.01667)
vec_int_frame = str2double(split(temp_vec_int," "))'; 
vec_int_frame_s = vec_int_frame.*0.01667;

%% Create stimulus 
%Based on Matlab for Psychologists by Borgo, Soranzo, Grassi (2012)

%In the example before the first and after the last event we insert a silent interval of 100 ms
in_out_window = 0.1; %in s

vec_int_frame_s = [in_out_window,vec_int_frame_s];
final_int = in_out_window;

Fs = 44100; %8192;   % Default Sampling Frequency (Hz)
amp = 0.8; 
Ys = [];
for dot = 1:n
    dur = vec_ied_frame_s(dot);
    freq = which_freq;                     % tone frequency
    T = linspace(0,dur,Fs*dur);            % Duration
    Y = amp*sin(2*pi*freq*T);              % Tone
    
    %ONSET and OFFSET gating (optional)
    gatedur = 0.005; %duration of gate in seconds
    ongate = cos(linspace(pi, 2*pi, Fs*gatedur));
    ongate = ongate + 1;
    ongate = ongate/2;
    offgate = fliplr(ongate);
    sustain = ones(1,(length(Y) - 2*length(ongate)));
    envelope = [ongate,sustain,offgate];
    Y = Y.*envelope;
    
    %Normalize
    Input_data = Y';
    minC = min(Input_data(:,1));
    maxC = max(Input_data(:,1));
    ScaledData = 2*(Input_data(:,1) - minC)./(maxC - minC) - 1; %Scaled data between -1 and 1
    
    Y0 = zeros(1,round(vec_int_frame_s(dot)*Fs));  %Silent Interval
    Ys = [Ys,Y0,Y];%[Ys,ScaledData,Y0];
    
    %Final interval
    if dot == n
        Y0 = zeros(1,round(final_int*Fs));
        Ys = [Ys,Y0];
    end
end

d.stim.file = Ys;
d.stim.Fs = Fs;

%% Test stim
p = audioplayer(d.stim.file,d.stim.Fs);

%play(p) %WARNING! CHECK YOUR VOLUME BEFORE PLAYING!
%pause(p)
%resume(p)
%stop(p)

%% Plot
duration_s = sum(vec_ied_frame_s) + sum(vec_int_frame_s) + final_int;
step = 1/Fs;
t = 0:step:duration_s;
t = t(1:length(Ys));
plot(t,Ys)
xlim([min(t),max(t)])
xlabel('Time')
ylabel('Audio Signal')

%% Write audio file
audiowrite(save_name,Ys,Fs)
