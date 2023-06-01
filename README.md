# Measuring temporal bias in sequential numerosity processing

This folder contains an example of code to generate sequential numerical stimuli under the framework described in Dolfi et al. (in preparation).
*Serena Dolfi, June 2023*, serena.dolfi@phd.unipd.it

**WARNING**

The example provided in the scripts and the associated function assume a manipulation of temporal features in frames, in order to allow the direct use of the output sequences in visual or auditory modality. The features provided as default values in ALL SCRIPTS AND FUNCTIONS assume the correspondence: 1 frame = 0.01667 s. Values of Duration and TmpSpacing as well as minimum IED or Interval values used in the function "seq_stim_creator" should be changed according to the system and screen refresh rate used and the intended use of the output sequences. Similarly, the script to create audio files uses a conversion based on 1 frame = 0.01667 s.

## CONTENT

- 'Generate_sequences.m': main script to generate sequences varying independently in Numerosity, Duration and Temporal Spacing. Both regular (with fixed duration of events and interval) as well as irregular sequences can be created. Stimuli are created as sequences of timestamps in frames, so appropriate values of Duration and Temporal Spacing should be changed based on the system used. The script saves the output sequences in a spreadsheet. The code also allows to easily visualize the relationship between numerosity and temporal features of the resulting sequences. 

- 'seq_stim_creator.m': function called by the main script, used to create the sequences as timestamps. Minimum and maximum event and interval durations in frames should be changed according to the system used.  

- 'Example_write_seq_audio.m': script providing an example on how to use the sequences of timestamps created with the main script to generate stimuli for experiments. The example shows how to use event and interval timestamps to create an auditory stimulus with a certain tone, sampling frequency and amplitude. The script uses a conversion based on 1 frame = 0.01667 s.

- 'Stimuli_example': folder containing 27 auditory stimoli (.wav files) and the spreadsheet with their description. 

- 'Data_analysis_study': folder containing the raw data from the study reported in Dolfi et al. (in preparation) and the script 'numcomp_seq_GLM.m' to replicate the analyses of the comparison task, estimating the weight of numerosity, Duration and Temporal Spacing for each participant and determining the individual discrimination vector. The code also computes the projection of participants' vector onto all temporal features and the angle between the individual vector and the numerosity axis (non-directional bias). An alternative approach (GLMM) is included to estimate the effect of numerosity, Duration and Temporal spacing ratios at group level.
