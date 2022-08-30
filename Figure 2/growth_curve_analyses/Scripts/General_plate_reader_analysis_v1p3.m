clear %clean all workspace
close all %close all figures
clc %clean command windor

%prior to using this script, model the data with no tables underneath and
%the metadata on top with the first row of metadata having numbers

%change directory to folder of interest
% cd('/Users/tropinica/Desktop/growth_curves')

[file,path] = uigetfile('*.xlsx');
cd(path)
if isequal(file,0)
    disp('User selected Cancel');
else
    disp(['User selected ', fullfile(path,file)]);
end

filename=[file(1:end-4) 'mat'];
if isfile(filename)
    % File exists.
    answer0 = questdlg('This dataset has already been analyzed, what do you want to do?', ...
        '', ...
        'Start over','Continue where I left off','Exit script','');
    
    if strcmp(answer0,'Start over')
        start_over=1;
    elseif strcmp(answer0,'Continue where I left off')
        load(filename)
        start_over=0;
    else
        return
    end
else
    % File does not exist.
    start_over=1;
end

if start_over
    bkg_sub = questdlg('What kind of background subtraction do you want?', ...
        '', ...
        'From control','From first time point','None','');
    
    if strcmp(bkg_sub,'From control')
        bkg_sub_choice=2;
    elseif strcmp(bkg_sub,'From first time point')
        bkg_sub_choice=1;
    else
        bkg_sub_choice=0;
    end
    outlier_remove = questdlg('Do you want to keep the most consistent 3 replicates only (remove outliers)? Only applies where there are more than 3 replicates. Does not apply to controls.', ...
        '', ...
        'Yes','No','');
    if strcmp(outlier_remove,'Yes')
        outlier_removal=1;
    else
        outlier_removal=0;
    end
    growth_data = importdata(fullfile(path,file));
    %% find metadata and format to make variable names from it
    metadata_labels = growth_data.textdata(:,1);
    data = growth_data.data(numel(metadata_labels)+1:end,2:end);
    time = growth_data.data(numel(metadata_labels)+1:end,1);
    well_labels = growth_data.textdata(end,2:end);
    % convert to hours
    time = time*24;
    %check that time doesn't go to 0 (can happen if run was cut short)
    time_0=find(time==0);
    if ~isempty(time_0)
        %if it has 0s in later time point trim
        if time_0(1)>1
            time=time(1:time_0(1)-1);
            data=data(1:time_0(1)-1,:);
        end
    end
    %substitute characters that can't work with field calling
    metadata_labels_formatted=strrep(metadata_labels,' ','_');
    metadata_labels_formatted=strrep(metadata_labels_formatted,'-','_');
    metadata_labels_formatted=strrep(metadata_labels_formatted,'/','_');
    metadata_labels_formatted=strrep(metadata_labels_formatted,'(','');
    metadata_labels_formatted=strrep(metadata_labels_formatted,')','');
    metadata_labels_formatted=strrep(metadata_labels_formatted,'[','');
    metadata_labels_formatted=strrep(metadata_labels_formatted,']','');
    figure_n=1;
    % format Metadata
    for i=1:size(metadata_labels,1)-1
        % if numeric add straight up
        subfield=metadata_labels_formatted{i};
        if ~isnan(growth_data.data(i,2))
            Metadata.(subfield)=growth_data.data(i,2:end)';
        else
            % if text, save from data.textdata and convert to numeric
            Metadata.(subfield)=growth_data.textdata(i,2:end)';
            unique_metadata_i=unique(growth_data.textdata(i,2:end));
            for j=1:numel(unique_metadata_i)
                %convert text metadata into numbers [0 is because metadata
                %goes 2:end so it needs to be shifted by 1
                indeces = strcmp(unique_metadata_i(j),growth_data.textdata(i,:));
                growth_data.data(i,indeces)=j;
            end
            subfield_numeric = [subfield '_numeric'];
            Metadata.(subfield_numeric)=growth_data.data(i,2:end)';
        end
        Metadata.wellname = well_labels';
    end
    %setup table for export
    Metadata_table=struct2table(Metadata);
    nrow = size(Metadata_table,1);
    Metadata_table.OD_max_overall = zeros(nrow, 1);
    Metadata_table.rate = zeros(nrow, 1);
    Metadata_table.OD_max = zeros(nrow, 1);
    Metadata_table.flag = zeros(nrow, 1);
    
    %% find out which categories want to select upon group together and analyze
    list = metadata_labels(1:end-1);
    [indx,tf] = listdlg('PromptString',{'Select the categories to analyze separately.'},'ListString',list);
    if isempty(indx)
        return
    end
    metadata_selected=metadata_labels(indx);
    metadata_labels_formatted_selected = metadata_labels_formatted(indx);
    numeric_metadata_selected = growth_data.data(indx,2:end);
    all_metadata = growth_data.data(indx,2:end);
    [unique_metadata, unique_indeces, ic] = unique(all_metadata','rows');
    unique_metadata = unique_metadata';
    
    [indx_ctrl,tf_ctrl] = listdlg('PromptString',{'Select the sample/control category.',...
        'Only one category can be selected at a time.',''},...
        'SelectionMode','single','ListString',metadata_selected);
    
    if isempty(indx_ctrl)
        return
    end
    %%
    Averaged_data=struct([]);
    legend_composite={};

    answer = questdlg('Do you want to get fits for this dataset?', ...
        '', ...
        'Yes','No','Exit script','');
    
    if strcmp(answer,'Yes')
        check_fit=1;
    elseif strcmp(answer,'No')
        check_fit=0;
    else
        return
    end
end
if start_over==0
    u1=u;
    s1=s;
else
    u1=1;
    s1=1;
end

for u=u1:numel(unique_indeces)
    save(filename)
    selected_wells = find(all(numeric_metadata_selected==unique_metadata(:,u)));
    Averaged_data(u).metadata_selected=metadata_selected;
    for s=s1:numel(selected_wells)
        save(filename)
        OD = data(:,selected_wells(s));
        Metadata.OD_max_overall(selected_wells(s))=max(OD);
        Metadata.outlier(selected_wells(s))=0; % initialize to 0, not an outlier
        title_composite = '';
        for t=1:numel(metadata_selected)
            metadata_well = Metadata.(metadata_labels_formatted_selected{t})(selected_wells(s));
            if isnumeric(metadata_well)
                title_composite=[title_composite ' ' metadata_selected(t) ' ' num2str(metadata_well) ';'];
            else
                title_composite=[title_composite ' ' metadata_selected(t) ' ' metadata_well ';'];
            end
        end
        if unique_metadata(indx_ctrl,u)==0 %if it is a control
            Metadata.lag(selected_wells(s))=0;
            Metadata.rate(selected_wells(s))=0;
            Metadata.OD_max(selected_wells(s))=0;
            Metadata.OD_i(selected_wells(s))=0;
            Metadata.flag(selected_wells(s))=0;
            Metadata.outlier(selected_wells(s))=0; %%% 5/14/22 added to match Kat's code %% NEED TO ADD THE ONE WHEN IT ACTUALLY GETS REMOVED
            Averaged_data(u).fit(s).fit_parameters=[0, 0, 0, 0];
            Metadata.bkg_subtraction{selected_wells(s)}='No subtraction, control';
        else
            if bkg_sub_choice==1 %subtract the first OD point
                OD = OD - OD(1);
                Metadata.bkg_subtraction{selected_wells(s)}='First time-point-subtracted';
            elseif bkg_sub_choice==2 %subtract the control
                %first find all the matching controls based on the metadata
                metadata_ctrl_match = unique_metadata(:,u);
                metadata_ctrl_match(indx_ctrl)=0;
                matches_i=1;
                controls_indeces=[];
                for mcm=1:size(all_metadata,2)
                    matches = all_metadata(:,mcm)==metadata_ctrl_match;
                    if all(matches)
                        controls_indeces(matches_i)=mcm;
                    end
                    % need to match all of them, then pull out the ones that
                    % are present in all datasets and call that controls_indeces
                    %                 controls_indeces=find(unique_metadata(1,:)==metadata_ctrl_match(1)&unique_metadata(2,:)==metadata_ctrl_match(2)&unique_metadata(3,:)==metadata_ctrl_match(3));
                end
                if ~isempty(controls_indeces)
                    OD_control = nanmean(data(:,controls_indeces),2);
                    OD = OD - OD_control;
                    Metadata.bkg_subtraction{selected_wells(s)}='Control-subtracted';
                else
                    OD = OD - OD(1);
                    disp('No control available - subtracted first time-point')
                    Metadata.bkg_subtraction{selected_wells(s)}='First time-point-subtracted';
                end
            else
                Metadata.bkg_subtraction{selected_wells(s)}='No subtraction';
            end
            if check_fit
                if bkg_sub_choice==2
                    %this need to delete once know it's working properly
                    close all
                    if ~isempty(controls_indeces)
                        f=figure(66);plot(time,OD+OD_control,time,OD_control,time,OD)
                        legend('Original','Control','Background-subtracted')
                        title([title_composite{:}])
                        make_white_fig(20)
                        answer_bkg = questdlg('Background subtraction', ...
                            '', ...
                            'Keep as shown','Subtract first time point only','');
                        if strcmp(answer_bkg,'Keep as shown')
                            bkg_change=0;
                        elseif strcmp(answer_bkg,'Subtract first time point only')
                            bkg_change=1;
                        end
                        if bkg_change
                            OD = OD+OD_control;
                            OD = OD - OD(1);
                        end
                    else
                        disp([title_composite{:} 'NOTE: NO CONTROL TO SUBTRACT, subtracted first time point, press return'])
                        pause
                    end                    
                end
                [Metadata.lag(selected_wells(s)),Metadata.rate(selected_wells(s)),Metadata.OD_max(selected_wells(s)),Metadata.OD_i(selected_wells(s)),Metadata.flag(selected_wells(s)),Averaged_data(u).fit(s).fit_parameters,Averaged_data(u).fit(s).fit_time]=fit_curve(title_composite,time,OD);
                if Metadata.flag(selected_wells(s)) == 2
                    Metadata.flag(selected_wells(s))=1;
                    return
                end
            else
                Metadata.lag(selected_wells(s))=0;
                Metadata.rate(selected_wells(s))=0;
                Metadata.OD_max(selected_wells(s))=0;
                Metadata.OD_i(selected_wells(s))=0;
                Metadata.flag(selected_wells(s))=0;
                Averaged_data(u).fit(s).fit_parameters=[0, 0, 0, 0];
            end
        end
        %populate table
        Metadata_table.OD_max_overall(selected_wells(s))= Metadata.OD_max_overall(selected_wells(s));
        Metadata_table.rate(selected_wells(s)) = Metadata.rate(selected_wells(s));
        Metadata_table.OD_max(selected_wells(s)) = Metadata.OD_max(selected_wells(s))+Metadata.OD_i(selected_wells(s));%here the fitted data has the maximum OD which is the delta from start, so adding back the initial %01/08/21
        Metadata_table.flag(selected_wells(s)) = Metadata.flag(selected_wells(s));
        Metadata_table.outlier(selected_wells(s)) = Metadata.outlier(selected_wells(s)); %%% 5/14/22 added to match Kat's code
        writetable(Metadata_table,[file(1:end-5) '_fits.xlsx'],'Sheet','Sheet1','WriteVariableNames',true);
        %%%
    end
    s1=1; %this is so that when it starts over it doesn't skip on old data (s1 gets set to what it was before the crash using the start_over flag).
    Averaged_data(u).metadata = unique_metadata(:,u);
    Averaged_data(u).unique_index = unique_indeces(u);
    Averaged_data(u).unique_metadata = unique_metadata(:,u);
    Averaged_data(u).selected_wells = selected_wells;
    % here want to not include wells that are flagged in the average data
    % and also set a new flag whether it's an outlier or not
    Averaged_data(u).removed_wells = 0;
    if outlier_removal && numel(selected_wells)>3 && unique_metadata(indx_ctrl,u)~=0 %keep lowest std 3 replicates if have greater than 3 replicates and only for samples
        outliers_all_data = isoutlier(data(:,selected_wells),2);
        outliers = mean(outliers_all_data);
        [~,sort_outliers]=sort(outliers);
        to_keep = sort_outliers(1:3);
        Averaged_data(u).removed_wells = selected_wells(sort_outliers(4:end));
        outlier_wells = selected_wells(sort_outliers(4:end));
        Metadata_table.outlier(outlier_wells)=1;
        selected_wells=selected_wells(to_keep);
        % rewrite output again since outliers have been updated
        writetable(Metadata_table,[file(1:end-5) '_fits.xlsx'],'Sheet','Sheet1','WriteVariableNames',true);
    else
        to_keep = 1:numel(selected_wells);
    end
    legend_composite = [[[title_composite{:}] ' n=' num2str(numel(selected_wells))];legend_composite]; %add number of replicates to legend
    Averaged_data(u).included_wells = selected_wells;
    avg_data_selected=vertcat(Averaged_data(u).fit.fit_parameters);
    Averaged_data(u).fit_average = nanmean(avg_data_selected(to_keep,:));
    Averaged_data(u).fit_std = nanstd(avg_data_selected(to_keep,:));
    Averaged_data(u).legend = [[title_composite{:}] ' n=' num2str(numel(selected_wells))];
    average_sample = mean(data(:,selected_wells),2);
    std_sample = std(data(:,selected_wells),0,2);
    Averaged_data(u).average_sample = average_sample;
    Averaged_data(u).std_sample = std_sample;
end

%%
fig_96=figure(1000);
title_wells_all={'A1' 'A2' 'A3'	'A4' 'A5' 'A6' 'A7' 'A8' 'A9' 'A10' 'A11' 'A12' 'B1' 'B2' 'B3' 'B4' 'B5' 'B6' 'B7' 'B8' 'B9' 'B10' 'B11' 'B12' 'C1' 'C2' 'C3' 'C4' 'C5' 'C6' 'C7' 'C8' 'C9' 'C10' 'C11' 'C12' 'D1' 'D2' 'D3' 'D4' 'D5' 'D6' 'D7' 'D8' 'D9' 'D10' 'D11' 'D12' 'E1' 'E2' 'E3' 'E4' 'E5' 'E6' 'E7' 'E8' 'E9' 'E10' 'E11' 'E12' 'F1' 'F2' 'F3' 'F4' 'F5' 'F6' 'F7' 'F8' 'F9' 'F10' 'F11' 'F12' 'G1' 'G2' 'G3' 'G4' 'G5' 'G6' 'G7' 'G8' 'G9' 'G10' 'G11' 'G12' 'H1' 'H2' 'H3' 'H4' 'H5' 'H6' 'H7' 'H8' 'H9' 'H10' 'H11' 'H12'};
title_wells = well_labels;
plot_position=zeros(1,96);
for sp=1:96 %was sp=1:min(size(data,2),96)
    well_of_interest = title_wells_all{sp};
    Index = find(contains(title_wells,well_of_interest));
    if ~isempty(Index)
        subplot(8,12,sp)
        plot(time,data(:,Index),'LineWidth',2,'Color',[44,162,95]/255)
        ylim([min(min(data)) max(max(data))])
        set(gca,'YTickLabel',[])
        set(gca,'XTickLabel',[])
        title(title_wells_all{sp})
        f=gcf;
        axescurrent = gca;
        allAxes = findobj(f.Children,'Type','axes');
        plot_position(sp) = find(axescurrent==allAxes);
    end
end
%%%% Need to figure out how to connect to Metadata_table and Averaged_data
%%%% to the well number so when changed it gets updated globally.
set(gcf,'Position',[0 116 800 839])
set(gcf,'Color',[247,252,253]/255)
sgtitle('96-well data')
%%
% select which metadata to plot together
T = array2table(unique_metadata');
for i=1:size(T,2)
    T.Properties.VariableNames(i)={metadata_labels_formatted_selected{i}};
    %now if the properties have been translated to numbers, switch back
    if isfield(Metadata, [metadata_labels_formatted_selected{i} '_numeric'])
        T.(metadata_labels_formatted_selected{i})=Metadata.(metadata_labels_formatted_selected{i})(unique_indeces);
    end
end
T(:,size(T,2)+1)={false};
T.Properties.VariableNames(size(T,2))={'Plot'};
fig = uifigure;
fig.Units='Normalized';
fig.Position=[0.2964 0.4990 0.5952 0.3429];
n_fig=1;
uit = uitable(fig);
uit.Data = T;
uit.Units='Normalized';
uit.Position = [0.0190 0.0528 0.7100 0.8610];
uit.ColumnEditable = true;
btn = uibutton(fig,'push',...
    'Position',[750, 50, 100, 22],...
    'ButtonPushedFcn', @(btn,event,n_fig2) plotButtonPushed(btn,uit.Data,time,Averaged_data,n_fig));
btn.Text='Plot Selected';
figure(fig)
function fit_curve_gca(src,event)
disp('Button pressed!')
f=gcf;
axesClicked = gca;
allAxes = findobj(f.Children,'Type','axes');
numClicked = find(axesClicked==allAxes);
%%%% Need to figure out how to connect to Metadata_table and Averaged_data
%%%% to the well number so when changed it gets updated globally.
% here need to call fit_curve
end
function plotButtonPushed(btn,T1,time,Averaged_data,n_fig)
indeces_plotting=table2array(T1(:,end));
cmap = brewermap(numel(indeces_plotting),'Set2');
close all
%%% here want to add a check to not plot outliers and write how many
%%% replicate for each curve in the legend.
legend_composite={};
for ip=1:numel(indeces_plotting)
    if indeces_plotting(ip)
        figure(5)
        hold on
        set(0, 'DefaultFigureRenderer', 'Painters');
        %         errorbar(time,Averaged_data(ip).average_sample,Averaged_data(ip).std_sample)
        boundedline(time,Averaged_data(ip).average_sample,Averaged_data(ip).std_sample,'cmap',cmap(ip,:),'alpha')
        % 1/8/21 changed from subtracting first point to having without
        % subtraction
        %        boundedline(time,Averaged_data(ip).average_sample-Averaged_data(ip).average_sample(1),Averaged_data(ip).std_sample,'cmap',cmap(ip,:),'alpha')
        hold off
        legend_composite = [Averaged_data(ip).legend;legend_composite];
        h = findobj(gca,'Type','line');
        legend(h,legend_composite)
        xlabel('Time (hrs)')
        ylabel('OD')
        make_white_fig(18)
    end
end

n_fig2=n_fig+1;
disp(n_fig)
end

function [lag,rate,OD_max,OD_i,flag,fit_parameters,fit_time]=fit_curve(title_composite,time,OD)
%%%%
% [Metadata.lag(selected_wells(s)),Metadata.rate(selected_wells(s)),Metadata.OD_max(selected_wells(s)),Metadata.OD_i(selected_wells(s)),Metadata.flag(selected_wells(s)),Averaged_data(u).fit(s).fit_parameters,Averaged_data(u).fit(s).fit_time]=fit_curve(title_composite);

answer='No, pick new points';
first_time_plotting=1;
while strcmp(answer,'No, pick new points')
    close all
    
    figure(1)
    if first_time_plotting
        plot(time,OD);
        title([title_composite{:}])
    else
        plot(time,OD);
        hold on
        rectangle('Position', [min(min(OD)) yl(1) x_start yl(2)-yl(1)], 'FaceColor', [0.5 0.5 0.5 0.5])
        rectangle('Position', [x_end yl(1) xl(2)-x_end yl(2)-yl(1)], 'FaceColor', [0.5 0.5 0.5 0.5])
        [~]=Gompertz_plate_reader(time_to_fit,OD_to_fit);
        hold off
        ylim(yl)
        xlim(xl)
    end
    xlabel('Time (hrs)')
    ylabel('OD')
    xlim([min(time) max(time)]);
    make_white_fig(20)
    xl=xlim;
    yl=ylim;
    hold on
    [x_start,~] = ginput(1);
    rectangle('Position', [min(min(OD)) yl(1) x_start yl(2)-yl(1)], 'FaceColor', [0.5 0.5 0.5 0.5])
    ylim(yl)
    xlim(xl)
    [x_end,~] = ginput(1);
    rectangle('Position', [x_end yl(1) xl(2)-x_end yl(2)-yl(1)], 'FaceColor', [0.5 0.5 0.5 0.5])
    hold off
    ylim(yl)
    xlim(xl)
    %don't go much beyond max OD
    t_start = find(time<x_start, 1, 'last' );
    t_end = find(time>x_end, 1, 'first' );
    fit_time = [time(t_start) time(t_end)];
    time_to_fit = time(t_start:t_end);
    OD_to_fit = OD(t_start:t_end);
    plot(time,OD);
    [lag,rate,OD_max,OD_i] = Gompertz_plate_reader(time_to_fit,OD_to_fit);
    hold on
    rectangle('Position', [x_end yl(1) xl(2)-x_end yl(2)-yl(1)], 'FaceColor', [0.5 0.5 0.5 0.5])
    rectangle('Position', [0 yl(1) x_start yl(2)-yl(1)], 'FaceColor', [0.5 0.5 0.5 0.5])
    hold off
    ylim(yl)
    xlim(xl)
    answer_1 = menu('Does the fit look good?', ...
        'Yes', 'Try other fit','Go to next and flag','Exit');
    switch answer_1
        case 1 %yes
            flag=0;
            fit_parameters=[lag,rate,OD_max,OD_i];
            answer='Continue';
        case 2
            first_time_plotting = 0;
        case 3 %no, flag
            flag=1;
            fit_parameters=[NaN, NaN, NaN, NaN];
            answer='Continue';
        case 4 %exit
            flag=2;
            fit_parameters=[NaN, NaN, NaN, NaN];
            return
    end
end
end
