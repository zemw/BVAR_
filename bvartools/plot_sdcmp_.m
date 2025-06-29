function  plot_sdcmp_(input,BVAR,options)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filippo Ferroni, 6/1/2015
% Revised, 2/15/2017
% Revised, 3/21/2018

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nparams = size(BVAR.Phi_draws,1);
nshocks = BVAR.N;
lags    = BVAR.lags;
% if  nparams > nshocks * lags
%     constant_ = 1;
% end
nexogenus = 0;
if  nparams > nshocks * lags + 1
    nexogenus = nparams - (nshocks * lags + 1);
end
for v = 1 : nshocks + nexogenus 
    eval(['namesshock{' num2str(v) '} =  ''Shck' num2str(v) ''';'])
end
for v = 1 : BVAR.N
    eval(['pplotvar{'   num2str(v) '} =  ''Var' num2str(v) ''';'])
end
for v = 1 : nshocks + nexogenus
    eval(['ex_names_{'   num2str(v) '} =  {''Shck' num2str(v) '''};'])
end
ex_names_ = ex_names_';
for v = 1 : BVAR.N
    eval(['leg{'   num2str(v) '} =  ''Shck' num2str(v) ''';'])
end
leg{end+1} = 'initial condition';

TT   = 1:1:size(input,1);
Tlim   = [TT(1) TT(end)];

[~,positions] = ismember(pplotvar,BVAR.varnames);
dcmp_group_yes = 0;
dmcp_type      = 'stacked';
tags           = [];
colors_decomp_yes = 0;
savefig_yes = 0;
include_predictable_yes =0;
% initial_state_dcmp = 0;
% addplot_=0;
% addplot0_=0;

if nargin > 2
    if isfield(options,'plotvar_') ==1
        clear plotvar_
        pplotvar             = options.plotvar_;
    end
    if isfield(options,'snames_') ==1
        clear ex_names_
        ex_names_             = options.snames_;
    end
    if isfield(options,'stag_') ==1
        clear leg
        leg             = options.stag_;
    end
    if isfield(options,'snames_') ==1 && isfield(options,'stag_') == 0
        error('You need to provide also ''stag_''')
    end
%     if isfield(options,'snames_') == 0 && isfield(options,'stag_') == 1
%         error('YOu need to provide also ''snames_''')
%     end
    if size(ex_names_,1) ~= length(leg)
        error('Mismatch between shock aggregations and shocks names')
    end
    if isfield(options,'time') ==1
        TT = options.time;
        Tlim   = [TT(1) TT(end)];
        if isfield(options,'Tlim') ==1
            Tlim=options.Tlim;
            if Tlim(1) < TT(1)
                warning('You have set a intitial date that starts earlier than the first obs');
                warning('I change it with the frist obs');
                Tlim(1) = TT(1);
            end
            if Tlim(2) > TT(end)
                warning('You have set a final date that exceeds the forecast horizon');
                warning('I change it with the endo of forecast');
                Tlim(2) = TT(end);
            end
        end
        
    end
    
    if isfield(options,'save_strng') ==1
        tags = options.save_strng;
    end
    if isfield(options,'dcmp_grouped') ==1 && options.dcmp_grouped ==1
        dcmp_group_yes = 1;
        dmcp_type      = 'grouped';
    end
    if isfield(options,'plotvarnames') ==1
        pplotvarname = options.plotvarnames;
        if length(pplotvarname)~=length(pplotvar)
            error('The number of plot titles (pplotvarname) and of plot variables needs to coincide')
        end
    end
    if isfield(options,'colors_decomp') ==1 && options.colors_decomp==1
        colors_decomp_yes =1;
    end
    if isfield(options,'colors_decomp') ==1 && options.colors_decomp==2
        colors_decomp_yes =2;
    end
    if isfield(options,'colors_decomp') ==1 && options.colors_decomp==3
        colors_decomp_yes =3;
    end
    % customized color palette
    if isfield(options, 'color_palette') == 1
        if size(options.color_palette, 1) ~= length(leg)
            error('Mismatch between color palette and shocks')
        end
        colors_decomp_yes =4;
    end
    if isfield(options,'saveas_dir') ==1
        savefig_yes = 1;
        %   setting the folder where to save the figure
        fnam_dir = options.saveas_dir;
        if exist(fnam_dir,'dir') == 0
            mkdir(fnam_dir)
        end
    end
    
    %     if isfield(options,'addplots_yes') ==1  && options.addplots_yes==1,
    %         tags = [ tags '_memo'];
    %         if isfield(input,'frcsts') ==1
    %             addplot_=1;
    %             frcsts = input.frcsts.states.Mean(:,positions);
    %             s_s = input.frcsts.states.steady(positions);
    %         end
    %         if isfield(input,'frcsts0') ==1
    %             addplot0_=1;
    %             frcsts0 = input.frcsts0.states.Mean(:,positions);
    %
    %         end
    %     end
end

[~,positions] = ismember(pplotvar,BVAR.varnames);
pplotvarname  = pplotvar;

% include predictable component in the plot
if isfield(options,'include_predictable') ==1 && options.include_predictable==1
    deco  = input;
    leg = [leg; 'Predictable'];
    include_predictable_yes = 1;
else
    deco = input(:,:,1:end-1);
end

% setting the names of the figure to save
fnam_suffix = [tags '_shcks_dcmp'];

ngroups0 = size(ex_names_,1);
% ngroups  = ngroups0+1+no_initial_effect;
if colors_decomp_yes == 0
    func = @(x) colorspace('RGB->Lab',x);
    MAP = distinguishable_colors(ngroups0+1,'w',func);
    % MAP = CreateColorMap(ngroups0+1);
    MAP(end,:) = [0.7 0.7 0.7];
elseif colors_decomp_yes == 1
    MAP = zeros(4,3);
    MAP(end,:) = [0.7 0.7 0.7]; % gray
    MAP(end-1,:) = [0.2 0.5 0.99];      % blue
    MAP(end-2,:) =  [1 1 0];        % yellow
    MAP(end-3,:) = [0.8 0 0.8] ;            % purple
    %     MAP(end-4,:) = [0 0.7 0];          % green
    %     MAP(end-5,:) = [1 0 0];             % red
    %     MAP(end-6,:) = [0 0 1];             % blue
    %     MAP(end-7,:) = [.5 .5 0];           % light green
elseif colors_decomp_yes == 2
    MAP = zeros(10,3);
    MAP(end,:) = [0.7 0.7 0.7]; % gray
    MAP(end-1,:) = [0.2 0.5 0.99];       % blue
    MAP(end-2,:) = [0.8 0 0.8] ;        % purple
    MAP(end-3,:) = [1 1 0] ;            % yellow
    MAP(end-4,:) = [0 0.7 0];          % green
    MAP(end-5,:) = [1 0 0];             % red
    MAP(end-6,:) = [0 0 1];             % blue
    MAP(end-7,:) = [.5 .5 0];          % light green
    MAP(end-8,:) = [0 0.25 0]; %brown
    MAP(end-9,:) = [0 0.9 0.9]; % violet
elseif colors_decomp_yes == 3
    MAP = zeros(11,3);
    MAP(end,:) = [0.7 0.7 0.7]; % gray
    MAP(end-1,:) = [0.2 0.5 0.99];       % blue
    MAP(end-2,:) = [0.8 0 0.8] ;        % purple
    MAP(end-3,:) = [1 1 0] ;            % yellow
    MAP(end-4,:) = [0 0.7 0];          % green
    MAP(end-5,:) = [1 0 0];             % red
    MAP(end-6,:) = [0 0 1];             % blue
    MAP(end-7,:) = [.5 .5 0];          % light green
    MAP(end-8,:) = [0 0.25 0]; %brown
    MAP(end-9,:) = [0 0.9 0.9]; % violet
    MAP(end-10,:) = [0.5 0.1 0.1]; % violet
elseif colors_decomp_yes == 4
    colors = options.color_palette;
    if include_predictable_yes ==1
        colors = [colors; '#CECECE'];
    end
    MAP = colors;
end

st = find(Tlim(1)==TT);
en = find(Tlim(2)==TT);
if savefig_yes == 1
    fidTxt = fopen([fnam_dir '\legenda_' fnam_suffix '_plots.txt'],'w');
    fprintf(fidTxt,['LEGENDA ' tags ' SHOCK DECOMPOSITION PLOTS\n']);
    fprintf(fidTxt,['\n']);
end

for j = 1 : size(pplotvar,2)
    clear sdec sdec_tot,
    indx = positions(j);
    sdec0 = squeeze(deco(:,indx,:));
    for i=1:ngroups0
        clear index,
        for ii=1:size(ex_names_{i},2)
            indbuf = strmatch(ex_names_{i}{ii},namesshock,'exact');
            if ~isempty(indbuf)
                index(ii) = indbuf;
            elseif ~isempty(ex_names_{i}{ii})
                error(['Shock name ',ex_names_{i}{ii}, ' not found.' ]);
            end
        end
        sdec(:,i)=sum(sdec0(:,index),2);
        sdec0(:,index)=0;
    end
    
    h= figure('Name',['Shocks Decomposition for ' pplotvarname{j}]);
    if include_predictable_yes ==1
        % concatenate predictable component
        sdec_tot=[sdec, sum(sdec0,2)];
    else
        sdec_tot = sdec;
    end
    if dcmp_group_yes == 0
        ind_pos = (sdec_tot>0);
        ind_neg = (sdec_tot<0);
        temp_neg  = cumsum(sdec_tot.*ind_neg ,2).*ind_neg;
        temp_pos  = cumsum(sdec_tot.*ind_pos ,2).*ind_pos;
        temp      = temp_neg + temp_pos;
        for kk = size(temp,2) : -1 : 1
            hold on
            bbar = bar(TT(st:en),temp(st:en,kk),dmcp_type,'EdgeColor','none');
            set(bbar, 'FaceColor', MAP(kk,:))
            shading faceted; hold on;
        end
        leg0 = leg(end:-1:1);
        
    else
        temp      = sdec_tot;
        bbar = bar(TT(st:en),temp(st:en,:),dmcp_type,'EdgeColor','none'); colormap(MAP);
        %         hleg=legend(leg(1:1:end),'interpreter','none','location','Best');
        %         shading faceted;
        %
    end
    %     set(hleg,'position',[0.5 0.15 0.4 0.2],'units','normalized')
    hold on
    axis tight
    fillips = sum(sdec_tot,2);
    hold on, h1=plot(TT(st:en),fillips(st:en),'k-.');
    set(h1,'MarkerFaceColor', 'k')
    
    %     if addplot_ ==1
    %         hold on, h1=plot(TT(st:en),frcsts(st:en,j),'k-*','LineWidth',2);
    %         hold on, h1=plot(TT(st:en),s_s(j)*ones(length(TT(st:en)),1),'k-.','LineWidth',2);
    %         leg0{end+1} = 'Current Forecast';
    %         leg0{end+1} = 'steady state';
    %     end
    %
    %     if addplot0_ ==1
    %         hold on, h1=plot(TT(st:en),frcsts0(st:en,j),'r-o','LineWidth',2);
    %         leg0{end+1} = 'Previous Forecast';
    %     end
    
    set(gcf,'position' ,[50 50 800 650])
    hleg=legend(leg0,'interpreter','none','location','Best');
    shading faceted;
    
    %     define_.timestart + (define_.nobs-1)/4
    %plot the last in-+sample obs
    %     hold on; plot([TT(define_.nobs) TT(define_.nobs)],[low up],'color',[1 0 0],'LineWidth',2)
    %     h=vline(define_.timestart + (define_.nobs-1)/4, 'k', 'Last Obs');
    %     set(h,'Linewidth',2)
    
    title(pplotvarname{j})
    %     set(gca,'Xtick',TT(st:6:en))
    %     tmp_str= sample2date(TT(st:6:en));
    set(gca,'Xtick',TT(st:6:en))
    %     tmp_str= sample2date(TT(st:2:en));
    %     set(gca,'Xticklabel',tmp_str)
    %     tmp_str= sample2date(TT);
    %     STR_RECAP = [ 'model_' fnam_suffix '_' tmp_str{st} '_'  tmp_str{end} '_' int2str(j)];
    
    if savefig_yes == 1
        STR_RECAP = [ fnam_dir '/svar_' fnam_suffix '_' int2str(j)];
        saveas(gcf,STR_RECAP,'fig');
        if strcmp(version('-release'),'2022b') == 0
            saveas(gcf,STR_RECAP,'pdf');
        end
        fprintf(fidTxt,['The figure sdcmp_' fnam_suffix '_' int2str(j) ' contains the following variable:\n' ]);
        tmp = strrep(char(pplotvarname{j} ),'\',' ');
        fprintf(fidTxt,[tmp '; ']);
        
        fprintf(fidTxt,['\n' ]);
        fprintf(fidTxt,['\n']);
        %close all
    end
    
end

if savefig_yes == 1
    fclose(fidTxt);
end

end
