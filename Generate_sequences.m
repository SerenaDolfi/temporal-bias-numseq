%Script to generate sequential numerical stimuli with the manipulation of
%temporal features as described in Dolfi et al. (in preparation)
%Serena Dolfi, March 2023, serena.dolfi@phd.unipd.it

clear
clc
rng('shuffle')

% This script and the associated functions assume a manipulation of temporal
% features in frames, in order to allow the direct use of the output sequences in 
% visual or auditory modality. The features provided as default values assume 
% the correspondence: 1 frame = 0.01667 s. Values of Duration and
% TmpSpacing as well as minimum IED or Interval values used in the function "seq_stim_creator"
% should be changed according to the system used.
% E.g., for sequences to be shown visually on a screen at 120 Hz, consider
% that 1 frame = 0.0083 s, so all values should be increased.

%% Define the features as preferred

%Inspired to DeWind et al. 2015:
%- Duration = Total event duration (TED) * Individual event duration (IED)
%- Temporal Spacing = Total stimulus duration (TSD) * Mean event period (MEP)
%To find values in a range: round(logspace(log10(7),log10(28),5));
N_levels = [7,14,28]; %round(logspace(log10(7),log10(28),10)); 
Duration_levels = [130,260,490]; %round(logspace(log10(130),log10(490),10)); 
TmpSpacing_levels = [1500,3000,6000]; %round(logspace(log10(1500),log10(6000),10)); 
rep = 1; %how many repetitions for every combination?

%Define the method used to compute IED (fixed or variable within
%stimulus) and the blank intervals (fixed or variable)
%In case of variability in IED, Individual event duration --> Mean event duration (MED)
event_method = 'Sum'; %'Fixed' for same duration for all events, 'Sum' for variable
interval_method = 'Sum'; %'Fixed' or 'Sum'

%% Create sequences

%Create the corresponding combinations
N_levels = repmat(N_levels,rep,1); N_levels = N_levels(:);
Duration_levels = repmat(Duration_levels,rep,1); Duration_levels = Duration_levels(:);
TmpSpacing_levels = repmat(TmpSpacing_levels,rep,1); TmpSpacing_levels = TmpSpacing_levels(:);
stim = struct();
[stim.n,stim.dur,stim.tmp_sp] = meshgrid(N_levels,Duration_levels,TmpSpacing_levels);
stim.n = stim.n(:);
stim.dur = stim.dur(:);
stim.tmp_sp = stim.tmp_sp(:);
stim.ted = sqrt(stim.dur.*stim.n);
stim.ied = stim.ted./stim.n;
stim.tsd = sqrt(stim.tmp_sp.*stim.n);
stim.mep = stim.tsd./stim.n;
stim = struct2table(stim);

%Create single sequences
seq_stimuli = struct();
for s = 1:size(stim,1)
    file_name = strcat('Stim',num2str(s));
    n = stim.n(s);
    ted = round(stim.ted(s));
    tsd = round(stim.tsd(s));
    one_seq = seq_stim_creator(n,ted,tsd,event_method,interval_method);
    
    %Collect info for database
    seq_stimuli.name{s,1} = file_name;
    seq_stimuli.ied_vec{s,:} = join(string(one_seq.ied_vec));
    seq_stimuli.int_vec{s,:} = join(string(one_seq.int_vec));
    %Actual features after rounding
    seq_stimuli.n(s,1) = length(one_seq.ied_vec);
    seq_stimuli.ted(s,1) = sum(one_seq.ied_vec);
    seq_stimuli.ied(s,1) = seq_stimuli.ted(s,1)/n;
    seq_stimuli.tsd(s,1) = sum(one_seq.ied_vec) + sum(one_seq.int_vec);
    seq_stimuli.mep(s,1) = seq_stimuli.tsd(s,1)/n;
    seq_stimuli.dur(s,1) = seq_stimuli.ted(s,1)*seq_stimuli.ied(s,1);
    seq_stimuli.tmp_sp(s,1) = seq_stimuli.tsd(s,1)*seq_stimuli.mep(s,1);
    
end

seq_stimuli = struct2table(seq_stimuli);

%% Plot stimulus space 

%Select the corresponding table to plot 
% - the intended manipulation: 'stim'
%- the actual stimuli with variability due to rounding: 'seq_stimuli'
plot_stim = seq_stimuli;

%Original Features
figure(1)
subplot(2,2,1)
gscatter(plot_stim.ied,plot_stim.ted,plot_stim.n)
xlabel('IED'),ylabel('TED'); axis square; legend('Location','northeastoutside');
subplot(2,2,2)
gscatter(log2(plot_stim.ied),log2(plot_stim.ted),plot_stim.n)
xlabel('log(IED)'),ylabel('log(TED)'); axis square; legend('Location','northeastoutside');
subplot(2,2,3)
gscatter(plot_stim.mep,plot_stim.tsd,plot_stim.n)
xlabel('MEP'),ylabel('TSD'); axis square; legend('Location','northeastoutside');
subplot(2,2,4)
gscatter(log2(plot_stim.mep),log2(plot_stim.tsd),plot_stim.n)
xlabel('log(MEP)'),ylabel('log(FA)'); axis square; legend('Location','northeastoutside');

%Duration and Temporal Spacing as axes
figure(2)
subplot(2,2,1)
scatter(plot_stim.dur,plot_stim.n,20,'k','filled');
xlabel('Duration'),ylabel('N'); axis square
subplot(2,2,2)
scatter(log2(plot_stim.dur),log2(plot_stim.n),20,'k','filled');
xlabel('log(Duration)'),ylabel('log(N)'); axis square
subplot(2,2,3)
scatter(plot_stim.tmp_sp,plot_stim.n,20,'k','filled');
xlabel('Temporal Spacing'),ylabel('N'); axis square
subplot(2,2,4)
scatter(log2(plot_stim.tmp_sp),log2(plot_stim.n),20,'k','filled');
xlabel('log(Temporal Spacing)'),ylabel('log(N)'); axis square

%% Plot individual features

figure(3)

subplot(2,2,1)
scatter(plot_stim.n,plot_stim.ted,'.k'); title('Total Event Duration')
xlabel('Num'); ylabel('TED')

subplot(2,2,2)
scatter(plot_stim.n,plot_stim.ied,'.k'); title('Individual Event Duration')
xlabel('Num'); ylabel('IED')

subplot(2,2,3)
scatter(plot_stim.n,plot_stim.tsd,'.k'); title('Total Stimulus Duration')
xlabel('Num'); ylabel('TSD')

subplot(2,2,4)
scatter(plot_stim.n,plot_stim.mep,'.k'); title('Mean Event Period')
xlabel('Num'); ylabel('MEP')

%% Save stimuli table to file 

%Save stimuli with intended and real features
newNames = append(stim.Properties.VariableNames,'_intended');
stim = renamevars(stim,stim.Properties.VariableNames,newNames);
out_table = [seq_stimuli,stim];

writetable(out_table,'sequences_stimuli.xlsx');
