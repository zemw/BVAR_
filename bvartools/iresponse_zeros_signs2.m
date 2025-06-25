function [ir,Omeg] = iresponse_zeros_signs2(Phi,Sigma,hor,lag,var_pos,f,sr,narrative,errors,draws,toler,normalization_)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Modified to incorporate narrative restrictions
%
% 'iresponse_zeros_sign' computes the impulse response functions using zero
% and sign restrictions on the endogenous variables
% References: 
% Arias, J. E., Rubio-Ram?rez, J. F. and Waggoner, D. F.: 2018, Inference
% Based on SVARs Identified with Sign and Zero Restrictions: Theory and
% Applications, Econometrica 86, 685�720. 
% Binning, A.: 2013, Underidentified SVAR models: A framework for combining
% short and long-run restrictions with sign-restrictions, Working Paper
% 2013/14, Norges Bank.  

% Inputs:
% - Phi, AR parameters of the VAR
% - Sigma, Covariance matrix of the reduced form VAR shocks
% - hor, horizon of the IRF
% - unit, 1 shock STD or 1 percent increase
% - (var_pos,f,sr) inputs for the zero and sign restrictions see bvar.m and
% tutorial_.m 

% Output:
% - ir contains the IRF 
% 1st dimension:   variable 
% 2st dimension:   horizon 
% 3st dimension:   shock

% Filippo Ferroni, 6/1/2015
% Revised, 2/15/2017
% Revised, 3/21/2018
% Revised, 9/11/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 10
    draws = 1; % Number of draws
end
if nargin < 11
    toler = 10000; % Number of rotation attempt
end
if nargin < 12
    normalization_ = 0; % sign normalization on rotations
end
p         = lag;
k         = size(Sigma,1);
endo_numb = p*k;
C1        = chol(Sigma,'lower');

ir      = nan(k,hor,k);
Omeg    = nan(k);

T = hor; % length of impulse response function. 

shocks = eye(k);

[Q,index,flag] = findQs(k,f);

if flag == 1
    error('Rank condition not satisfied, the model is overidentified');
end

shock_pos = logical(shocks); % position of shock

% var_pos = [1,1,4,1,1];
% var_pos = [1,2,2,3,3];       % position of corresponding variable to shock 
% % eg monetary policy shock should result in a positive increase in interest 
% % rates, aggregate demand shock should result in a positive increase in gdp
% % etc.

R = zeros(k,T,length(shocks),draws); % Contains impulse resonse functions
% 1st dimension = variable
% 2nd dimension = time
% 3th dimension = shock
% 4rd dimension = draw

counter = 1;

B      = [Phi(endo_numb+1:end,:); Phi(1:endo_numb,:)];
Btilde = Phi(1:endo_numb,:)';
% B      = [Phi(end,:); Phi(1:end-1,:)];
% Btilde = B(2:end,:)';
% Btilde = Phi(1:end-1,:)';
alpha = [Btilde;eye(k*(p-1)),zeros(k*(p-1),k)]; % Build companion form matrix
WW    = nan(k);
if draws > 10
    wb = waitbar(0, 'Generating Rotations');
end

tj = 0;
while counter < draws+1

% Just clarify the notation:
%
%  T = length of IRFs
%  N = number of observations
%  k = number of variables
%  U'= N x k matrix of residuals, UU' = Sigma
%  V'= N x k matrix of structural shocks, VV' = I
%  W'= k x k matrix of structural decomposition
% 
%  Thus, U' = V'*W' or U = W*V 
%  UU' = WVV'W' = WW' = Sigma
%
%  C is some (Chelosky) decomposition of Sigma, CC' = Sigma
%  P is some random draw of some orthogonal matrix, PP' = I
%  W = C*P produce some rotation over the decomposition of Sigma
%  We check the W satisfie the restrictions

    tj = tj +1;

    if tj > toler
        warning('I could not find a rotation')
        return;
    end
    
    C = generateDraw(C1,k);
    
    P = findP(C,B,Q,p,k,index);
    
    W = C*P;

    for jj = 1:length(shocks)
                
        shock = shocks(:,jj);
        if normalization_ == 1
            if W(var_pos(jj),jj) < 0
                shock = -shocks(:,jj);
            end
        end
        
        WW(:,jj) = W*shock;

        V = zeros(k*p,T);
        
        V(1:k,1) = W*shock;
        
        chk = W*shock;
        sr_index = ~isnan(sr(:,jj));
        tmp = sign(chk(sr_index)) - sr(sr_index,jj);

        if any(tmp~=0)
            jj = 0;
            break
        end
        
        for ii = 2:T
            V(:,ii) = alpha*V(:,ii-1);
        end
        
        R(:,:,jj,counter) = V(1:k,:);
        
    end
    
    % make sure all shocks satisfy the restrictions
    % otherwise continue to next draw
    if jj ~= length(shocks)
        continue;
    end

    % make sure narrative restrictions satisfied
    if exist('narrative', 'var')
        % errors(=U): the T x k matrix of reduced-form residuals 
        % Recall: U' = V'*W' Solve out for V'=U'/W'
        v = errors / W';
        d = checkrestrictions(narrative,[],v);
        if d ==0
            continue;
        end
    end
    
    % if all check passed
    counter = counter + 1;
    
end


if draws > 10, close(wb); end

%Omeg = W; 
Omeg = C1\WW; 
ir    = R;