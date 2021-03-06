% authors: bohan zhang
%
% testing 2D optimizer
% for a given set of FF's, find the period and offset that gives desired
% angle and best directivity in two ways:
%   brute force sweep
%   using an optimizer

clear; close all;

% dependencies
addpath(['..' filesep '45RFSOI']);                  % 45RF
addpath(['..' filesep 'main' ]);                    % main code
addpath(['..' filesep 'auxiliary_functions']);      % merit function

% initial settings
disc        = 10;
units       = 'nm';
lambda      = 1550;
index_clad  = 1.0;
domain      = [ 2500, 800 ];

% directory to save data to
% unused for this script
data_dir        = [ pwd, filesep, 'test_datasave' ];
% data_dir        = [ filesep 'project' filesep 'siphot' filesep 'bz' filesep 'gratings' filesep 'grating_synth_data' ];
data_filename   = 'test';
data_notes      = 'test sweep new dedicated function for init. grating cell';

% make the directory to save data to, if not already in existence
mkdir( data_dir );

% number of parallel workers, unused
n_workers = 4;

% desired angle
optimal_angle = 15;

% coupling up/down
coupling_direction = 'down';

% make object
Q = c_synthGrating( 'discretization',   disc,       ...
                    'units',            units,      ...
                    'lambda',           lambda,     ...
                    'background_index', index_clad, ...
                    'domain_size',      domain,     ...
                    'optimal_angle',    optimal_angle,      ...
                    'coupling_direction', coupling_direction, ...
                    'data_directory',   data_dir, ...
                    'data_filename',    data_filename, ...
                    'data_notes',       data_notes, ...
                    'data_mode',        'new', ...
                    'num_par_workers',  n_workers, ...
                    'h_makeGratingCell', @f_makeGratingCell_45RFSOI ...
                     );
%                     'h_makeGratingCell', @f_makeGratingCell_45RFSOI ...
          

% -------------------------------------------------------------------------
% nonlinear optim
% -------------------------------------------------------------------------

% % weights and fill factor
% weights         = [1, 1];
% fill_factors    = [ fill_top, fill_bot ];
% 
% % starting point
% x0 = [ 0.700, 0.3 ];
% 
% % options
% opts = optimset( 'Display', 'iter', ...
%                  'FunValCheck', 'off', ...
%                  'MaxFunEvals', 400, ...
%                  'MaxIter', 400, ...
%                  'PlotFcns', @optimplotfval );
% 
% % run fminsearch, simplex search
% tic;
% [x, fval, exitflag, output] = fminsearch( @(x) f_merit_period_offset( x, Q, optimal_angle, weights, fill_factors ), x0, opts );
% toc;

% % run fminunc, the gradient search
% tic;
% [x, fval, exitflag, output] = fminunc( @(x) f_merit_period_offset( x, Q, optimal_angle, weights, fill_factors ), x0, opts );
% toc;

% -------------------------------------------------------------------------
% Brute force
% -------------------------------------------------------------------------

% chosen fills
fill_bot = 0.7;
fill_top = fill_bot * 1;

% period and offset ranges to sweep
% periods = 650:10:770;                     % good range when fill top = fill bot = 80%
% periods = 730:10:830;                       % good range when fill top = 0.6, fill bot = 0.8
% periods = 980:10:1080;                       % good range when fill top = 0.3, fill bot = 0.3
% periods     = 630:10:670;                       % good range when fills = 95%
periods     = 760:10:820;                    
offsets     = 0.72:0.04:1.72;
% periods     = 1020;
% offsets = [0.4, 0.5, 0.6, 0.7];

% init saving variables
directivities   = zeros( length(periods), length(offsets) );    % up/down directivity, dimensions period vs. offset
angles_up       = zeros( length(periods), length(offsets) );    % up angle, dimensions period vs. offset
angles_down     = zeros( length(periods), length(offsets) );    % down angle, dimensions period vs. offset
alpha_up        = zeros( length(periods), length(offsets) );    % scattering strength up, dimensions period vs. offset
alpha_down      = zeros( length(periods), length(offsets) );    % scattering strength down, dimensions period vs. offset
k_all           = zeros( length(periods), length(offsets) );    % k, dimensions period vs. offset
p_rad_up        = zeros( length(periods), length(offsets) );    % power radiated upwards, dimensions period vs. offset
p_rad_down      = zeros( length(periods), length(offsets) );    % power radiated upwards, dimensions period vs. offset
p_in            = zeros( length(periods), length(offsets) );    % power in, dimensions period vs. offset
GC_all          = cell( length(periods), length(offsets) );     % GC objects, dimensions period vs. offset


% set guessk
guessk = 0.009449 + 1i * 7.8965e-5;


% main loop simulation settings
num_modes   = 1;
BC          = 0;                                                % 0 = PEC
pml_options = [1, 200, 20, 2]; 


i_loop = 0;
tic;

% run loops
for i_period = 1:length(periods)
    
    for i_offset = 1:length(offsets)
        
        % print loop #
        i_loop = i_loop + 1;
        fprintf('Loop %i of %i\n', i_loop, length(periods)*length(offsets) );
        
        % make grating coupler object
        GC = Q.h_makeGratingCell( Q.convertObjToStruct(), periods(i_period), fill_top, fill_bot, offsets(i_offset) );
        
        % run sim
        GC = GC.runSimulation( num_modes, BC, pml_options, guessk );
        
%         % DEBUG plot field
%         GC.plotEz_w_edges();
       
        % save results
        directivities( i_period, i_offset ) = GC.directivity;
        angles_up( i_period, i_offset )     = GC.max_angle_up;
        angles_down( i_period, i_offset )   = GC.max_angle_down;
        k_all( i_period, i_offset )         = GC.k;
        alpha_up( i_period, i_offset )      = GC.alpha_up;
        alpha_down( i_period, i_offset )    = GC.alpha_down;
        p_rad_up( i_period, i_offset )      = GC.P_rad_up;
        p_rad_down( i_period, i_offset )    = GC.P_rad_down;
        p_in( i_period, i_offset )          = GC.P_in;
        GC_all{ i_period, i_offset }        = GC;
        
        % update guessk
        guessk  = GC.k;
        if i_offset == 1
            % first iteration, save this guessk for next outer iteration
            next_period_loop_guessk = guessk;
        end
        
        toc;
        
    end     % end for i_offset
    
    % update guessk
    guessk = next_period_loop_guessk;
     
end     % end for i_period

% % Loading old data
% % data is stored in: C:\Users\beezy\git\grating_synthesis\test_scripts\temporary_data
% data = load( 'C:\Users\beezy\git\grating_synthesis\test_scripts\temporary_data\s_test_opimize_period_offset_data.mat' );
% % unpack data
% v2struct(data.data);
        
% Plot stuff
% directivity vs. period and offset
figure;
imagesc( offsets, periods, 10*log10(directivities) );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Up/down Directivity (dB) vs. period and offset');

% down/up directivity vs. period and offset
figure;
imagesc( offsets, periods, 10*log10(1./directivities) );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('down/up Directivity (dB) vs. period and offset');


% scattering up vs. period and offset
figure;
imagesc( offsets, periods, alpha_up );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Up scattering vs. period and offset');

% scattering down vs. period and offset
figure;
imagesc( offsets, periods, alpha_down );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Down scattering vs. period and offset');

% total scattering
figure;
imagesc( offsets, periods, abs(alpha_down) + abs(alpha_up) );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Total scattering vs. period and offset');


% angle up vs. period and offset
figure;
imagesc( offsets, periods, angles_up );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Up angle vs. period and offset');

% angle down vs. period and offset
figure;
imagesc( offsets, periods, angles_down );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Down angle vs. period and offset');


% power up vs. period and offset
figure;
imagesc( offsets, periods, p_rad_up );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Up radiated power vs. period and offset');

% power down vs. period and offset
figure;
imagesc( offsets, periods, p_rad_down );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Down radiated power vs. period and offset');

% power in vs. period and offset
figure;
imagesc( offsets, periods, p_in );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Input power vs. period and offset');

% power in minus power up minus power down vs. period and offset
figure;
imagesc( offsets, periods, p_in - p_rad_up - p_rad_down );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Input power - rad up - rad down vs. period and offset');


% % plot FOM
% fom         = weights(1)*abs( optimal_angle - angles_down )/optimal_angle + weights(2)*log10(directivities);
% % plot merit function
% figure;
% imagesc( offsets, periods, fom );
% xlabel('offset'); ylabel('period');
% colorbar;
% set( gca, 'ydir', 'normal' );
% title('FOM vs. period and offset');

% plot angle error
angle_error = abs( optimal_angle - angles_down )/optimal_angle;
figure;
imagesc( offsets, periods, angle_error );
xlabel('offset'); ylabel('period');
colorbar;
set( gca, 'ydir', 'normal' );
title('Angle error (in %) vs. period and offset');

% % plot directivity
% figure;
% imagesc( offsets, periods, log10(directivities) );
% xlabel('offset'); ylabel('period');
% colorbar;
% set( gca, 'ydir', 'normal' );
% title('log10(directivities) vs. period and offset');

% % DEBUG plot each mode one by one
% OPTS.plots = 'real';
% for ii = 1:length(GC_all)
%    
%     GC_all{ii}.plotEz_w_edges( OPTS );
%     pause;
%     close(gcf);
% %     close(gcf);
%     
% end

        
% -------------------------------------------------------------------------
% Sweep offset and then sweep period
% -------------------------------------------------------------------------
        
        
% % starting period
% start_period = 1000;
% 
% % init saving variables
% directivities   = zeros(size(offsets));
% angles_up       = zeros(size(periods));
% angles_down     = zeros(size(periods));
%    
% % sweep offset, pick offset with best directivity
% tic;
% for i_offset = 1:length(offsets)
% 
%     % print loop #
%     fprintf('Loop %i of %i\n', i_offset, length(offsets) );
% 
%     % make grating coupler object
%     GC = f_makeGratingCell_45RFSOI( Q.convertObjToStruct(), start_period, fill_top, fill_bot, offsets(i_offset) );
% 
%     % run sim
%     GC = GC.runSimulation( num_modes, BC, pml_options, guessk );
% 
%     % save results
%     directivities( i_offset ) = GC.directivity;
% 
%     toc;
% 
% end
% 
% % grab best directivity
% [ max_dir, indx_max_dir ]   = max(1./directivities(:));
% best_offset                 = offsets( indx_max_dir );
%         
% 
% % sweep periods, pick period with closest angle to desired
% for i_period = 1:length(periods)
% 
%     % print loop #
%     fprintf('Loop %i of %i\n', i_period, length(periods) );
% 
%     % make grating coupler object
%     GC = f_makeGratingCell_45RFSOI( Q.convertObjToStruct(), periods(i_period), fill_top, fill_bot, best_offset );
% 
%     % run sim
%     GC = GC.runSimulation( num_modes, BC, pml_options, guessk );
% 
%     % save results
%     angles_down( i_period ) = GC.max_angle_down;
% 
%     toc;
% 
% end
% 
% 
% % grab best period
% [ angle_err, indx_best_period ] = min( abs( optimal_angle - angles_down ) );
% best_period                     = periods( indx_best_period );
        
        
        
        
        
        