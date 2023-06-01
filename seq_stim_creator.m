function [seq] = seq_stim_creator(n,ted,tsd,event_method,interval_method)
%SEQ STIM CREATOR Function to create non-symbolic sequential numerical
%stimuli, from a combination of Numerosity, Total event duration and Total
%stimulus duration. 
%Serena Dolfi, March 2023, serena.dolfi@phd.unipd.it

%Inputs are:
%n (numeric) = the number of events in the sequence 
%ted (numeric) = total event duration, the total duration of all the events (TSA), in frames
%tsd (numeric) = total stimulus duration, the overall duration of the sequence (CH), in frames
%event_method (char vec) = 'fixed' for same duration for all events (ISA), 'sum' for variable event duration (AIS)
%interval_method (char vec) = 'fixed' for same duration of inter-events intervals,'sum' for variable interval duration
%Output is:
%seq (struct) with fields:
%ied_vec: row vector of n elements corresponding to the individual event durations in frames
%int_vec: row vector of n-1 elements corresponding to the duration in frames of inter-event intervals

%% Basic checks input

if ~isnumeric(n) || ~isnumeric(ted) || ~isnumeric(tsd)
    error('N, TED and TSD must be numeric')
elseif ~ischar(event_method) || ~ischar(interval_method)
    error('Specify event and interval methods with strings (Fixed or Sum)')
elseif ~strcmp(event_method,'Fixed') &&  ~strcmp(event_method,'Sum')
    error('Specify event method as: Fixed/Sum')
elseif ~strcmp(interval_method,'Fixed') &&  ~strcmp(interval_method,'Sum')
    error('Specify interval method as: Fixed/Sum')
end

ied = ted/n;
int = (tsd-ted)/(n-1);
tot_int = int*(n-1);

%% Set parameters as preferred 

min_ied = 2; %ied must be min 2 frames in case of 'sum' method
min_int = 3; %int must be min 3 frames in case of 'sum' method
ied_maxoffset = 1.75; %to determine the variability around mean ied in 'sum' method
int_maxoffset = 1.75; %to determine the variability around mean int in 'sum' method
max_ied = ted/n*ied_maxoffset; %it can also be set to a fixed value
max_int = tot_int/(n-1)*int_maxoffset; %it can also be set to a fixed value
max_iter = 100000; %max iterations to find the ied or int vectors before returning error in case of 'sum' method

%% %Basic checks feature values

if tsd < ted
    error('Total stimulus duration cannot be smaller than Total event duration')
elseif min_ied*n > ted
    error('Minimum individual event duration too long for selected Total event duration')
elseif min_int*(n-1) > tot_int
    error('Minimum individual interval duration too long for selected Total stimulus duration')
end

%% Create events vector
seq = struct();

if strcmp(event_method,'Fixed') %If fixed, round the ied for all events
    ied_vec = round(repmat(ied,1,n));
elseif strcmp(event_method,'Sum') 
    if ied - min_ied < 1 %To allow a fast solution also in case of small ied values
        ied_vec = floor(repmat(ied,1,n));
        diff_ted = ted - sum(ied_vec);
        for i = 1:diff_ted %"manually" adjust the ieds
            change_ied = randperm(length(ied_vec));
            change_idx = change_ied(1);
            ied_vec(change_idx) = ied_vec(change_idx) + 1;
        end
    else %To allow small values and variability in selected range 
        niter = 0;
        success = 0;
        while success == 0
            success = 1;
            ied_vec = [];
            tank = 0;
            for i = 1:n
                if i == n
                    ied_vec(i) = ted - tank;
                    if ied_vec(i) < min_ied || ied_vec(i) > max_ied
                        success = 0;
                        niter = niter + 1;
                    end
                else
                    ied_vec(i) = min_ied + (max_ied - min_ied).*rand;
                    ied_vec(i) = floor(ied_vec(i));
                    tank = tank + ied_vec(i);
                    if tank > ted
                        success = 0;
                        niter = niter + 1;
                        if niter > max_iter
                            error('Maximum number of iterations reached trying to create the event vector')
                        end
                        break
                    end
                end
            end
        end
    end
end

%% Create interval vector

if strcmp(interval_method,'Fixed') %If fixed, round the intervals
    int_vec = round(repmat(int,1,n-1));
elseif strcmp(interval_method,'Sum')
    if int - min_int < 1 %To allow a fast solution also in case of small int values
        int_vec = floor(repmat(int,1,n));
        diff_int = tot_int - sum(int_vec);
        for i = 1:diff_int
            change_int = randperm(length(int_vec));
            change_idx = change_int(1);
            int_vec(change_idx) = int_vec(change_idx) + 1;
        end
    else %To allow small values and variability in selected range
        niter = 0;
        success = 0;
        while success == 0
            tank = 0;
            success = 1;
            for i = 1:n
                if i == n
                    int_vec(i) = tot_int - tank;
                    if int_vec(i) < min_int || int_vec(i) > max_int
                        success = 0;
                        niter = niter + 1;
                    end
                else
                    int_vec(i) = min_int + (max_int - min_int).*rand;
                    int_vec(i) = floor(int_vec(i));
                    tank = tank + int_vec(i);
                    if tank > tot_int
                        success = 0;
                        niter = niter + 1;
                        if niter > max_iter
                            error('Maximum number of iterations reached trying to create the interval vector')
                        end
                        break
                    end
                end
            end
        end
    end
end

%% Store info about sequence
seq.ied_vec = ied_vec; 
seq.int_vec = int_vec;

end