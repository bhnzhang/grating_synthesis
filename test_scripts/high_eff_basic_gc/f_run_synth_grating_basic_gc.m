function [] = f_run_synth_grating_basic_gc( lambda, optimal_angle, layer_thick )
% authors: bohan
% 
% script for testing the latest synthesis object on the scc
% using the basic GC dimensions
%
% Inputs
%   lambda
%       wavelength in nm
%   optimal_angle
%       angle in deg, can be negative
%   layer_thick
%       layer thickness, in nm

% clear; close all;

% dependencies
% addpath( genpath( [ '..' filesep '..' ] ) );                                % all synth grating code

% initial settings
disc                = 10;
units               = 'nm';
% lambda              = 1250;
index_clad          = 1.45; % 1.448;
y_domain_size       = 2500;
% optimal_angle       = 20;             % still useful
coupling_direction  = 'down';
data_notes          = ['lambda ' num2str(lambda) ' optimal angle ' num2str(optimal_angle) ];

% display inputs
fprintf('Inputs are:\n');
fprintf('Wavelength: %f %s\n', lambda, units);
fprintf('Angle: %f degrees\n', optimal_angle);
fprintf('Layer thickness: %f %s\n', layer_thick, units);

% make grating cell function
h_makeGratingCell = @(dxy, units, lambda, background_index, y_domain_size, ...
                      period, fill_top, fill_bot, offset_ratio) ...
                      f_makeGratingCell_basic( dxy, units, lambda, background_index, y_domain_size, ...
                                         period, fill_top, fill_bot, offset_ratio, layer_thick )

% make synthesis object
synth_obj = c_synthTwoLevelGrating(   'discretization',    disc, ...
                                      'units',             units,   ...
                                      'lambda',            lambda, ...
                                      'background_index',  index_clad,    ...
                                      'y_domain_size',     y_domain_size, ...
                                      'optimal_angle',     optimal_angle, ...
                                      'data_notes',        data_notes, ...
                                      'coupling_direction', coupling_direction, ...
                                      'h_makeGratingCell', h_makeGratingCell ...
                                      );

% display Q for logging purposes
synth_obj

% design space fills
fill_bots           = fliplr( 0.025:0.025:0.95 );
fill_top_bot_ratio  = fliplr( 0.025:0.025:1.5 );
% fill_bots           = fliplr( 0.95:0.025:0.975 );
% fill_top_bot_ratio  = fliplr( 0.95:0.025:0.975 );

% run design space generation
tic;
synth_obj = synth_obj.generate_design_space( fill_bots, fill_top_bot_ratio );
toc;

fprintf('Design space generation sweep is done\n');
fprintf('Saving data...\n');

% make folder to save to
save_data_path = [ pwd filesep synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) '_thick' num2str(layer_thick) ];
mkdir( save_data_path );

% clear the GC from the data and save
% synth_obj.sweep_variables.GC_vs_fills = zeros( size(synth_obj.sweep_variables.GC_vs_fills) );
save( [  save_data_path filesep 'synth_obj_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) '_NO_GC' '.mat' ], 'synth_obj', '-v7.3' );

fprintf('Data saved\n');

% Plot results and save figures

% directivity vs. fill
figure;
imagesc( synth_obj.sweep_variables.fill_top_bot_ratio, synth_obj.sweep_variables.fill_bots, 10*log10(synth_obj.sweep_variables.directivities_vs_fills) );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
title('Directivity (dB) vs. fill factors');
figure_name = [ 'dir_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) ];
save_fig_multiformat( gcf, save_data_path, figure_name );

% directivity BEFORE sweeping periods vs. fill
figure;
imagesc( synth_obj.sweep_variables.fill_top_bot_ratio, synth_obj.sweep_variables.fill_bots, 10*log10(synth_obj.sweep_variables.dir_b4_period_vs_fills) );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
title('Directivity (dB) BEFORE PERIOD SWEEP vs. fill factors');
figure_name = [ 'dir_b4_period_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) ];
save_fig_multiformat( gcf, save_data_path, figure_name );

% angles vs. fill
figure;
imagesc( synth_obj.sweep_variables.fill_top_bot_ratio, ...
         synth_obj.sweep_variables.fill_bots, ...
         synth_obj.sweep_variables.angles_vs_fills );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
title('Angles (deg) vs. fill factors');
figure_name = [ 'angle_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) ];
save_fig_multiformat( gcf, save_data_path, figure_name );

% scattering strength (imaginary) alpha vs. fill
figure;
imagesc( synth_obj.sweep_variables.fill_top_bot_ratio, ...
         synth_obj.sweep_variables.fill_bots, ...
         imag(synth_obj.sweep_variables.scatter_str_vs_fills) );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
title('Scattering strength (imaginary) vs. fill factors');
figure_name = [ 'scatter_str_imag_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) ];
save_fig_multiformat( gcf, save_data_path, figure_name );

% scattering strength alpha vs. fill
figure;
imagesc( synth_obj.sweep_variables.fill_top_bot_ratio, ...
         synth_obj.sweep_variables.fill_bots, ...
         real(synth_obj.sweep_variables.scatter_str_vs_fills) );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
title('Scattering strength (real) vs. fill factors');
figure_name = [ 'scatter_str_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) ];
save_fig_multiformat( gcf, save_data_path, figure_name );

% period vs. fill
figure;
imagesc( synth_obj.sweep_variables.fill_top_bot_ratio, ...
         synth_obj.sweep_variables.fill_bots, ...
         synth_obj.sweep_variables.periods_vs_fills );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
title(['Period (' synth_obj.units.name ') vs. fill factors']);
figure_name = [ 'period_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) ];
save_fig_multiformat( gcf, save_data_path, figure_name );

% offset vs. fill
figure;
imagesc( synth_obj.sweep_variables.fill_top_bot_ratio, ...
         synth_obj.sweep_variables.fill_bots, ...
         synth_obj.sweep_variables.offsets_vs_fills );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
title('Offset vs. fill factors');
figure_name = [ 'offsets_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) ];
save_fig_multiformat( gcf, save_data_path, figure_name );

% k vs. fill
figure;
imagesc( synth_obj.sweep_variables.fill_top_bot_ratio, ...
         synth_obj.sweep_variables.fill_bots, ...
         real(synth_obj.sweep_variables.k_vs_fills) );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
title('Real k vs. fill factors');
figure_name = [ 'k_real_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) ];
save_fig_multiformat( gcf, save_data_path, figure_name );

figure;
imagesc( synth_obj.sweep_variables.fill_top_bot_ratio, ...
         synth_obj.sweep_variables.fill_bots, ...
         imag(synth_obj.sweep_variables.k_vs_fills) );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
title('Imag k vs. fill factors');
figure_name = [ 'k_imag_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) ];
save_fig_multiformat( gcf, save_data_path, figure_name );


% % TEMP remove sat
% figure;
% imagesc( Q.fill_top_bot_ratio, Q.fill_bots, 10*log10(dir_vs_fill_b4_temp) );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
% title('Directivity (dB) BEFORE PERIOD SWEEP vs. fill factors');
% savefig('dir_b4_period_TEMP_v_ff.fig');
% saveas(gcf, 'dir_b4_period_TEMP_v_ff.png');



% % directivity vs. fill, saturated
% dir_v_fill_sat                                  = 10*log10(Q.directivities_vs_fills);
% sat_thresh                                      = 20;                                   % threshold, in dB
% dir_v_fill_sat( dir_v_fill_sat < sat_thresh )   = sat_thresh;
% 
% figure;
% imagesc( Q.fill_top_bot_ratio, Q.fill_bots, dir_v_fill_sat );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
% title('Directivity (dB) (saturated) vs. fill factors');
% savefig([ 'dir_v_ff_sat_' num2str(sat_thresh) '.fig']);
% saveas(gcf, [ 'dir_v_ff_sat_' num2str(sat_thresh) '.png']);


% % plot the way jelena did
% % with fill factor bottom vs. 'layer ratio'
% [FILL_BOT, FILL_TOP] = meshgrid( Q.fill_bots, Q.fill_tops );
% layer_ratio          = FILL_TOP./FILL_BOT;
% layer_ratio( isinf(layer_ratio) | isnan(layer_ratio) ) = 50;
% % layer_ratio = log10(layer_ratio);
% 
% figure;
% surf( layer_ratio, FILL_TOP, 10*log10(Q.directivities_vs_fills) );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom layer ratio'); ylabel('top fill factor');
% title('Directivity (dB) vs. top fill factor and layer ratio');
% savefig('dir_v_ff_layer_ratio.fig');
% saveas(gcf, 'dir_v_ff_layer_ratio.png');


% % plot but block out all the places that jelena's code doesn't sweep
% dir_v_fill_jelena                       = 10*log10(Q.directivities_vs_fills);
% dir_v_fill_jelena( layer_ratio > 1.4 )  = -100;
% 
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, dir_v_fill_jelena );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title('Directivity (dB) (only datapoints that jelena sweeps) vs. fill factors');
% % savefig([ 'dir_v_ff_sat_' num2str(sat_thresh) '.fig']);
% % saveas(gcf, [ 'dir_v_ff_sat_' num2str(sat_thresh) '.png']);
% 
% 
% % plot but only show the "normal" curve regime
% dir_v_fill_jelena                       = 10*log10(Q.directivities_vs_fills);
% dir_v_fill_jelena( layer_ratio < 0.95 | layer_ratio > 1.4 ) = -100;
% 
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, dir_v_fill_jelena );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title('Directivity (dB) (only datapoints on normal curve) vs. fill factors');
% 
% 
% % plot but only show the "inverted" curve regime
% dir_v_fill_jelena                       = 10*log10(Q.directivities_vs_fills);
% dir_v_fill_jelena( layer_ratio > 1.05 | (layer_ratio + FILL_BOT) < 0.9 | (layer_ratio + FILL_BOT) > 1.1 )  = -100;
% 
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, dir_v_fill_jelena );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title('Directivity (dB) (only datapoints on inverted curve) vs. fill factors');



% % offset (jelena's definition) vs. fills
% offset_jelena = synth_obj.offsets_vs_fills + ...
%                 repmat(synth_obj.fill_bots.', 1, length(synth_obj.fill_top_bot_ratio) ) - ...
%                 repmat(synth_obj.fill_bots.', 1, length(synth_obj.fill_top_bot_ratio) ) .* repmat(synth_obj.fill_top_bot_ratio, length(synth_obj.fill_bots), 1);
% offset_jelena = mod( offset_jelena, 1.0 );
% figure;
% imagesc( synth_obj.fill_top_bot_ratio, synth_obj.fill_bots, offset_jelena );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('top/bottom fill ratio'); ylabel('bottom fill factor');
% title('Offset (jelena''s def) vs. fill factors');
% savefig(['offsets_jelena_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) '_box' num2str(BOX_thickness) '.fig']);
% saveas(gcf, ['offsets_jelena_v_ff_' synth_obj.start_time 'lambda' num2str(lambda) '_optangle' num2str(optimal_angle) '_box' num2str(BOX_thickness) '.png']);


% plot of the final designs
% 
% % final synthesized fills
% figure;
% plot( 1:length(Q.bot_fill_synth), Q.bot_fill_synth, '-o' ); hold on;
% plot( 1:length(Q.top_bot_fill_ratio_synth), Q.top_bot_fill_ratio_synth, '-o' );
% xlabel('cell #');
% legend('bottom fill ratio', 'top/bottom fill ratio');
% title('Final synthesized fill factor');
% makeFigureNice();
% savefig('final_fill_ratios.fig');
% saveas(gcf, 'final_fill_ratios.png');
% 
% % final synthesized fills
% figure;
% plot( 1:length(Q.bot_fill_synth), Q.bot_fill_synth.*Q.period_synth, '-o' ); hold on;
% plot( 1:length(Q.top_bot_fill_ratio_synth), Q.top_bot_fill_ratio_synth.*Q.bot_fill_synth.*Q.period_synth, '-o' );
% xlabel('cell #');
% legend('bottom fill', 'top fill');
% title('Final synthesized fills (nm)');
% makeFigureNice();
% savefig('final_fills.fig');
% saveas(gcf, 'final_fills.png');
% 
% % final synthesized offset
% figure;
% plot( 1:length(Q.offset_synth), Q.offset_synth, '-o' );
% xlabel('cell #');
% legend('offset ratio');
% title('Final synthesized offset ratio');
% makeFigureNice();
% savefig('final_offsets.fig');
% saveas(gcf, 'final_offsets.png');
% 
% % final synthesized period
% figure;
% plot( 1:length(Q.period_synth), Q.period_synth, '-o' );
% xlabel('cell #');
% legend(['period, ' units]);
% title('Final synthesized period');
% makeFigureNice();
% savefig('final_periods.fig');
% saveas(gcf, 'final_periods.png');
% 
% % final synthesized angles
% figure;
% plot( 1:length(Q.angles_synth), Q.angles_synth, '-o' );
% xlabel('cell #');
% legend('angle, deg');
% title('Final synthesized angles');
% makeFigureNice();
% savefig('final_angles.fig');
% saveas(gcf, 'final_angles.png');
% 
% % final synthesized scattering strength
% figure;
% plot( 1:length(Q.scatter_str_synth), Q.scatter_str_synth, '-o' );
% xlabel('cell #');
% legend(['scattering strength (units 1/' units]);
% title('Final synthesized scattering strength');
% makeFigureNice();
% savefig('final_scattering_str.fig');
% saveas(gcf, 'final_scattering_str.png');
% 
% % final synthesized scattering strength normalized comparison
% figure;
% plot( 1:length(Q.scatter_str_synth), Q.des_scatter_norm, '-o' ); hold on;
% plot( 1:length(Q.scatter_str_synth), Q.scatter_str_synth./abs(max(Q.scatter_str_synth(:))), '-o' );
% xlabel('cell #');
% legend('desired scatter str', 'normalized scatter str');
% title('Final synthesized scattering strength, normalized comparison');
% makeFigureNice();
% savefig('final_scattering_str_norm.fig');
% saveas(gcf, 'final_scattering_str_norm.png');
% 
% % final synthesized directivity
% figure;
% plot( 1:length(Q.dir_synth), 10*log10(Q.dir_synth), '-o' );
% xlabel('cell #');
% legend('Directivity, dB');
% title('Final synthesized directivity');
% makeFigureNice();
% savefig('final_dir.fig');
% saveas(gcf, 'final_dir.png');


% -------------------------------------------------------------------------
% buncha extra test cases
% -------------------------------------------------------------------------

% % TESTING max eff. vs. MFD
% MFDs            = 5000:500:15000;
% max_eff_vs_MFD  = zeros(size(MFDs));
% 
% tic;
% for ii = 1:length(MFDs)
%     
%     fprintf('mfd iteration %i of %i\n', ii, length(MFDs) );
%     
%     % run EME sim
%     Q = Q.runFinalDesignEME_fiber_overlap( MFDs(ii) );
%     % save result
%     max_eff_vs_MFD(ii) = Q.final_design.max_coupling_eff;
%     
%     toc;
%     
% end
% 
% % plot result
% figure;
% plot( MFDs, max_eff_vs_MFD, '-o' );
% xlabel(['MFD (' units ')']); ylabel('Max eff.');
% title('Max coupling eff. vs. MFD');
% makeFigureNice();
% 
% 
% % TESTING eff. vs. angle at BEST MFD
% [~, indx_best_mfd]  = max( max_eff_vs_MFD );
% best_MFD            = MFDs( indx_best_mfd );
% eme_obj_temp        = Q.final_design.eme_obj;
% angle_vec           = 15:0.1:25;
% eme_obj_temp.fiberCoup.coup = zeros( 1, length(angle_vec) );                % annoying but I have to re-size this
% % compute fiber overlap
% um              = 1e6;
% eme_obj_temp    = eme_obj_temp.fiberOverlap( 'zOffset', Q.final_design.eme_obj.fiberCoup.optZOffset,...
%                                 'angleVec', angle_vec,...
%                                 'MFD', best_MFD * Q.units.scale * um,...
%                                 'overlapDir', Q.coupling_direction, ...
%                                 'nClad', Q.background_index );
% 
% % plot eff vs angle
% figure;
% plot( eme_obj_temp.fiberCoup.angleVec, 10*log10(eme_obj_temp.fiberCoup.coup), '-o' );
% xlabel('Angle'); ylabel('Coupling eff');
% title(['Coupling eff. (dB) vs. angle for MFD = ' num2str(best_MFD) ' ' units ]);
% makeFigureNice();
% 
% 
% % TESTING eff. vs. angle at DESIRED/SYNTHESIZED MFD
% eme_obj_temp        = Q.final_design.eme_obj;
% angle_vec           = 15:0.1:25;
% eme_obj_temp.fiberCoup.coup = zeros( 1, length(angle_vec) );                % annoying but I have to re-size this
% % compute fiber overlap
% um              = 1e6;
% eme_obj_temp    = eme_obj_temp.fiberOverlap( 'zOffset', Q.final_design.eme_obj.fiberCoup.optZOffset,...
%                                 'angleVec', angle_vec,...
%                                 'MFD', MFD * Q.units.scale * um,...
%                                 'overlapDir', Q.coupling_direction, ...
%                                 'nClad', Q.background_index );
% 
% % plot eff vs angle
% figure;
% plot( eme_obj_temp.fiberCoup.angleVec, 10*log10(eme_obj_temp.fiberCoup.coup), '-o' );
% xlabel('Angle'); ylabel('Coupling eff');
% title(['Coupling eff. (dB) vs. angle for MFD = ' num2str(MFD) ' ' units ]);
% makeFigureNice();
% 
% 
% % TESTING eff. vs. offset at BEST MFD
% eme_obj_temp        = Q.final_design.eme_obj;
% offset_vec          = 0:0.1:12;
% eme_obj_temp.fiberCoup.coup = zeros( length(offset_vec), 1 );                % annoying but I have to re-size this
% % compute fiber overlap
% um              = 1e6;
% eme_obj_temp    = eme_obj_temp.fiberOverlap( 'zOffset', offset_vec,...
%                                 'angleVec', Q.optimal_angle,...
%                                 'MFD', best_MFD * Q.units.scale * um,...
%                                 'overlapDir', Q.coupling_direction, ...
%                                 'nClad', Q.background_index );
% 
% % plot eff vs angle
% figure;
% plot( eme_obj_temp.fiberCoup.zOffset, 10*log10(eme_obj_temp.fiberCoup.coup), '-o' );
% xlabel('Offset (um)'); ylabel('Coupling eff');
% title(['Coupling eff. (dB) vs. offset for MFD = ' num2str(best_MFD) ' ' units ]);
% makeFigureNice();

end


        
