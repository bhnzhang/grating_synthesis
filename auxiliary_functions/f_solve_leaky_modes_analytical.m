function [  ] = f_solve_leaky_modes_analytical( a, b, n0, n1, lambda0 )
% Solves for TE analytical solutions to symmetric leaky mode waveguide
%
% Using formulation from paper:
% j hu c menyuk - understanding leaky modes slab waveguide revisited
%
% Leaky mode waveguide index profile is defined as:
%   
%   n0, upper cladding towards infinity
%   -------------------
%   n1, width b
%   ------------------- 
%   n0, width a
%   -------------------
%   n1, width b
%   -------------------
%   n0, bottom cladding towards neg. infinity
%
%   in plane transverse direction = x
%   direction of propagation = z
%
%
% authors: bohan zhang
%
% Inputs:
%   a
%       type: double, scalar
%       desc: width of waveguide core with index n0, units of nm
%   b
%       type: double, scalar
%       desc: width of waveguide inter-cladding layer with index n1, units
%             of nm
%   n0
%       type: double, scalar
%       desc: index of waveguide core/outer cladding
%   n1
%       type: double, scalar
%       desc: index of waveguide inter-cladding layer
%   lambda0
%       type: double, scalar
%       desc: free space wavelength in nm

% define constants
k0 = 2*pi/lambda0;  % units rad/nm

% For first test, plot the dispersion relation

% pick range of beta's to solve for
neff_range  = linspace( n0, n1, 1000 );
beta_range  = (2*pi/lambda0);
kx          = sqrt( (k0^2)*(n0^2) - beta_range.^2 );
alpha       = sqrt( beta_range.^2 - (k0^2)*(n1^2) );

% dispersion equation
lhs     = tan( kx*a );                                                          % left hand side
rhs     = (alpha./kx) .* tanh( atanh( -1i * kx./alpha ) + alpha.*(b - a) );     % right hand side

% plot dispersion
figure;
plot( beta_range, lhs ); hold on;
plot( beta_range, rhs );
legend('left hand side', 'right hand side');
xlabel('\beta (rad/nm)'); ylabel('dispersion');
title('DEBUG dispersion relation');
makeFigureNice();

end






















