%% Monte Carlo Simulation of Heston Stochastic volatility model
 
close all
clear variables

%Controls
figures = 1; 

% Volatility dynamics parameters from Cui et al
kappa = 3; % Mean reversion rate
theta = 0.1; % Long term variance (or v_bar in Cui et al)
epsilon = 0.25; % Volatility of volatilty (or sigma in Cui et al)
V0 = 0.08; % Initial variance value
rho = -0.8; % Correlation coefficient of share price (underlying) and volatility

% Market parameters from Cui et al.
S0 = 1; % Initial share price
K = 1.1; % Strike price
r = 0.02; % Risk free rate
q = 0; % Dividend rate 
mu = r-q; % Drift parameter

% Define parameters and time grid
npaths = 10^4; % number of paths
nblocks = 20;
nsteps = 200; % number of time steps
T = 1; % Time horizon
dt = T/nsteps; % time step
t = 0:dt:T; % observation times

tic

VcMCb = zeros(nblocks,1);
VpMCb = zeros(nblocks,1);

for j = 1:nblocks

    X1 =  randn(nsteps, npaths); 
    X2 =  rho*X1 + sqrt(1 - rho^2)*randn(nsteps, npaths); % Correlated N(0,1) number

    % Monte Carlo simulation of volatility dynamics using Feller Square-root
    % process

    % Allocate and initialise all paths
    V = [V0 * ones(1, npaths); zeros(nsteps, npaths)]; % V = Volatility

    a = epsilon^2/kappa*(exp(-kappa*dt)-exp(-2*kappa*dt)); % with analytic moments
    b = theta*epsilon^2/(2*kappa)*(1-exp(-kappa*dt))^2; % with analytic moments

    for i= 1:nsteps % Compute and accumulate the increments
        V(i+1,:) = theta+(V(i,:)-theta)*exp(-kappa*dt) + sqrt(a*V(i,:)+b).*X2(i,:); 
        V(i+1,:) = max(V(i+1,:),zeros(1,npaths)); % avoid negative V 
    end

    % Compute the increments of the arithmetic Brownian motion X = log(S/S0)
    dX = (mu-0.5*V(1:end-1,:))*dt + sqrt(V(1:end-1,:)).*X1*sqrt(dt);

    % Cumulatively sum all changes in X

    X = [zeros(1,npaths); cumsum(dX)];

    % Transform X_t to GBM
    S = S0 * exp(X(end,:));

    % Discounted expected payoff
    VcMCb(j) = exp(-r*T)*mean(max(S-K,0));
    VpMCb(j) = exp(-r*T)*mean(max(K-S,0));


end

VcMC = mean(VcMCb);
VpMC = mean(VpMCb);
scMC = sqrt(var(VcMCb)/nblocks);
spMC = sqrt(var(VpMCb)/nblocks);
cputime_MC = toc;
fprintf('%20s%15s%15s%15s\n','','call','put','CPU_time/s')
fprintf('%20s%15.10f%15.10f%15.10f\n','Monte Carlo Heston Model',VcMC,VpMC,cputime_MC)
fprintf('%20s%15.10f%15.10f\n','Monte Carlo Heston stdev',scMC,spMC)


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%% FIGURES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if figures ~= 0

% Sample paths of volatility
figure (1)
plot(t, V(:,1:200:end));
xlabel('t')
ylabel('V_t')
title('Sample stochastic dynamics of instantaneous variance dv_t = k(\theta-v_t)dt + \epsilon v_{t}^{1/2}dW_{t}^{v} ')

% Sample paths of share price simulations
figure(2)
S_Plot = S0 * exp(X);
plot(t, S_Plot(:,1:80:end));
xlabel('t')
ylabel('S_t')
title('dS_t = \muSdt + v^{1/2}SdW1')

% Probability density function at different times

figure(3)
subplot(3,1,1)
histogram(S_Plot(1:30,:),0:0.035:3.5,'normalization','pdf');
ylabel('f_X(x,0.15)')
xlim([0,2.2])
ylim([0,3.5])
title('Heston Stochastic Volatility model: PDF at different times')

subplot(3,1,2)
histogram(S_Plot(1:80,:),0:0.035:3.5,'normalization','pdf');
xlim([0,2.2])
ylim([0,3.5])
ylabel('f_X(x,0.4)')

subplot(3,1,3)
histogram(S_Plot(end,:),0:0.035:3.5,'normalization','pdf');
xlim([0,2.2])
ylim([0,3.5])
xlabel('x')
ylabel('f_X(x,1)')

end
