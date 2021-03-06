% authors: bohan
% 
% script for testing the latest synthesis pipeline

clear; close all;

% dependencies
addpath( genpath( ['..' filesep '..'] ) );

% initial settings
disc                = 10;
units               = 'nm';     % i forget why i needed units to begin with
lambda              = 1550;
index_clad          = 1.45;
y_domain_size       = 2500;
optimal_angle       = -15;
coupling_direction  = 'down';   % either 'up' or 'down'
data_notes          = 'meh';

% make synthesis object
synth_obj = c_synthTwoLevelGrating(   'discretization',    disc, ...
                                      'units',             units,   ...
                                      'lambda',            lambda, ...
                                      'background_index',  index_clad,    ...
                                      'y_domain_size',     y_domain_size, ...
                                      'optimal_angle',     optimal_angle, ...
                                      'data_notes',        data_notes, ...
                                      'coupling_direction', coupling_direction, ...
                                      'h_makeGratingCell', @f_makeGratingCell_45RFSOI ...
                                      );

                                  
% DEBUG run the function
% f_run_synth_grating_basic_gc( lambda, optimal_angle );
        
% generate design space
% a small test scenario
fill_bots           = fliplr( 0.95:0.025:0.975 );
fill_top_bot_ratio  = fliplr( 0.975:0.025:1.0 );
% run generation
verbose     = true;
synth_obj   = synth_obj.generate_design_space( fill_bots, fill_top_bot_ratio );

% Plot results

% directivity vs. fill
figure;
imagesc( synth_obj.sweep_variables.fill_bots, ...
         synth_obj.sweep_variables.fill_top_bot_ratio, ...
         10*log10( synth_obj.sweep_variables.directivities_vs_fills ) );
colorbar; set( gca, 'ydir', 'normal' );
xlabel('bottom fill factor'); ylabel('top bottom fill ratio');
title('Directivity (dB) vs. fill factors');

% 
% % directivity vs. fill, saturated
% dir_v_fill_sat                                  = 10*log10(Q.directivities_vs_fills);
% sat_thresh                                      = 20;                                   % threshold, in dB
% dir_v_fill_sat( dir_v_fill_sat < sat_thresh )   = sat_thresh;
% 
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, dir_v_fill_sat );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title('Directivity (dB) (saturated) vs. fill factors');
% savefig([ 'dir_v_ff_sat_' num2str(sat_thresh) '.fig']);
% saveas(gcf, [ 'dir_v_ff_sat_' num2str(sat_thresh) '.png']);
% 
% 
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
% 
% 
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
% 
% 
% % angles vs. fill
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, Q.angles_vs_fills );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title('Angles (deg) vs. fill factors');
% savefig('angle_v_ff.fig');
% saveas(gcf, 'angle_v_ff.png');
% 
% % scattering strength alpha vs. fill
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, real(Q.scatter_str_vs_fills) );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title('Scattering strength (real) vs. fill factors');
% savefig('scatter_str_v_ff.fig');
% saveas(gcf, 'scatter_str_v_ff.png');
% 
% % period vs. fill
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, Q.periods_vs_fills );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title(['Period (' Q.units.name ') vs. fill factors']);
% savefig('period_v_ff.fig');
% saveas(gcf, 'period_v_ff.png');
% 
% % offset vs. fill
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, Q.offsets_vs_fills );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title('Offset vs. fill factors');
% savefig('offsets_v_ff.fig');
% saveas(gcf, 'offsets_v_ff.png');
% 
% % k vs. fill
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, real(Q.k_vs_fills) );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title('Real k vs. fill factors');
% savefig('k_real_v_ff.fig');
% saveas(gcf, 'k_real_v_ff.png');
% 
% figure;
% imagesc( Q.fill_bots, Q.fill_tops, imag(Q.k_vs_fills) );
% colorbar; set( gca, 'ydir', 'normal' );
% xlabel('bottom fill factor'); ylabel('top fill factor');
% title('Imag k vs. fill factors');
% savefig('k_imag_v_ff.fig');
% saveas(gcf, 'k_imag_v_ff.png');





        