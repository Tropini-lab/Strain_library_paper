%% Calculate pH and plot OD/pH data
% last updated 07/03/22

% Input: an Excel file with the following tabs:
%     self-corrected OD data (sheet: ODs)
%     440 nm data (sheet: 440)
%     490 nm data (sheet: 490)
% Requirements:
%     All headers must match (ie, data must be in the same order)
%     Need the following categories:
%        bcecf
%        condition
%        strain
%        time

% clear %clean all workspace
% close all %close all figures
% clc %clean command window

%prior to using this script, model the data with no tables underneath and
%the metadata on top with the first row of metadata having numbers

% Prompt user to specify location of file and change to that directory
[file,path] = uigetfile('*.xlsx');
cd(path)

if isequal(file,0)
    disp('User selected Cancel');
else
    disp(['User selected ', fullfile(path,file)]);
end

% Import the data into a struct called growth_data
growth_data = importdata(fullfile(path,file));

% Check that the headers from the growth_data and bcecf sheets match
if isempty(setdiff(growth_data.textdata.x440, growth_data.textdata.x490))
    disp ('Headers match!')
else
    disp('Headers don''t match, fix them please')
    return
end

% Find metadata and format to make variable names from it
    metadata_labels = growth_data.textdata.x440(1:4,1);
    data_OD = growth_data.data.ODs(numel(metadata_labels)+1:end,2:end);
    data_440 = growth_data.data.x440(numel(metadata_labels)+1:end,2:end);
    data_490 = growth_data.data.x490(numel(metadata_labels)+1:end,2:end);
    time = growth_data.data.ODs(numel(metadata_labels)+1:end,1);
    well_labels = growth_data.textdata.x440(end,2:end);
    % Convert time to hours
    time = time*24;
    % Check that time doesn't go to 0 (can happen if run was cut short)
    time_0=find(time==0);
    if ~isempty(time_0)
        %if it has 0s in later time point trim
        if time_0(1)>1
            time=time(1:time_0(1)-1);
            data_440=data_440(1:time_0(1)-1,:);
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
        subfield=lower(metadata_labels_formatted{i});
        if ~isnan(growth_data.data.x440(i,2))
            pHMetadata.(subfield)=growth_data.data.x440(i,2:end)';
        else
            % if text, save from data.textdata and convert to numeric
            pHMetadata.(subfield)=growth_data.textdata.x440(i,2:end)';
            unique_metadata_i=unique(growth_data.textdata.x440(i,2:end));
            for j=1:numel(unique_metadata_i)
                %convert text metadata into numbers [0 is because metadata
                %goes 2:end so it needs to be shifted by 1]
                indeces = strcmp(unique_metadata_i(j),growth_data.textdata.x440(i,:));
                growth_data.data.x440(i,indeces)=j;
            end
            subfield_numeric = [lower(subfield) '_numeric'];
            pHMetadata.(subfield_numeric)=growth_data.data.x440(i,2:end)';
        end
    end


numeric_strains = unique(pHMetadata.strain_numeric);
numeric_conditions = unique(pHMetadata.condition_numeric);
% make a matrix that has 2 extra rows on top for metadata
stored_data = nan(size(data_440,1)+3,1);
all_wells = growth_data.textdata.x440(4,2:end);


for strain = 1:numel(numeric_strains)
    for condition = 1:numel(numeric_conditions)
        % find matching columns
        matching_columns = intersect(find(pHMetadata.condition_numeric == condition),find(pHMetadata.strain_numeric == strain));
        bcecf_columns = intersect(matching_columns,find(pHMetadata.bcecf == 1));
        control_column = intersect(matching_columns,find(pHMetadata.bcecf == 0));

        if numel(bcecf_columns) > 0
            % copy metadata to top 2 rows
            curr_metadata = repmat([strain;condition],1,numel(bcecf_columns));
            curr_metadata(3,:) = bcecf_columns;

            % no bcecf subtraction
            corrected_440 = data_440(:,bcecf_columns)-data_440(:,control_column);
            corrected_490 = data_490(:,bcecf_columns)-data_490(:,control_column);

            % calculation of ratios
            ratios = corrected_440./corrected_490;


            % store metadata and data
            if isnan(stored_data(1))
                stored_data(1:3,1:numel(bcecf_columns)) = curr_metadata;
                stored_data(4:end,1:numel(bcecf_columns)) = ratios;
            else
                stored_data(1:3,end+1:end+numel(bcecf_columns)) = curr_metadata;
                stored_data(4:end,end-numel(bcecf_columns)+1:end) = ratios;
            end
        end


    end
end

% get input on which columns are
    unique_strains = unique(pHMetadata.strain);
    strain_list = unique_strains;
    [indx2,tf] = listdlg('PromptString',{'Select your control'},'ListString',strain_list);
    if isempty(indx2)
        return
    end
    % find first instance of control strain
    first_control_ind = find(strcmp(pHMetadata.strain,unique_strains(indx2)),1);
    % store the Strain__numeric value for the control strain
    control_num = pHMetadata.strain_numeric(first_control_ind)
    % control_num columns in stored_data
    all_control_idx = find(stored_data(1,:)==control_num)

    unique_conditions = unique(pHMetadata.condition);
    pH_conditions = {};
    list = unique_conditions;
    [indx,tf] = listdlg('PromptString',{'Select the target pH conditions'},'ListString',list);
    if isempty(indx)
        return
    end

    prompts = compose(unique_conditions(indx))

    dims = [1 60];
    y = inputdlg(prompts,'Input measured pH values:',dims)

    for cond = 1:numel(indx)
        % find first instance of a unique condition
        curr_ind = find(strcmp(pHMetadata.condition,unique_conditions(indx(cond))),1);
        % store the string name and the numerical name and the true value
        pH_conditions{1,end+1} = pHMetadata.condition{curr_ind}
        pH_conditions{2,end} = pHMetadata.condition_numeric(curr_ind)
        pH_conditions{3,end} = (stored_data(4,intersect(all_control_idx,find(stored_data(2,:)==indx(cond)))))
        pH_conditions{4,end} = repmat(str2num(y{cond}),1,numel(pH_conditions{3,end}))

    end

figure('Color','w');
scatter(cell2mat(pH_conditions(3,:)),cell2mat(pH_conditions(4,:)),'filled')
xlabel('440/490 ratio')
ylabel('pH of standard')
bcecf_mdl = fitlm(cell2mat(pH_conditions(3,:)),cell2mat(pH_conditions(4,:)))
% convert data with standard curve fit
converted_data = bcecf_mdl.Coefficients.Estimate(2)*stored_data + bcecf_mdl.Coefficients.Estimate(1);
% replace headers
converted_data(1:3,:) = stored_data(1:3,:);
% get list of all unique wells that have calculated pHs
pH_wells = all_wells(converted_data(3,:))

print(sprintf('pH_std_curve_experiment_%s.pdf',erase(file,'.xlsx')),'-dpdf','-bestfit');
export_fig(sprintf('pH_std_curve_experiment_%s.png',erase(file,'.xlsx')),'-m2.5');
close all;
%
condition_colors = [91,88,81; 45,44,40; 191,185,170; 152,148,136; 215, 48,39 ; 252,141,89 ; 254,224,144 ; 145,191,219]/255


unique_strain = unique(pHMetadata.strain)
unique_conditions = unique(pHMetadata.condition)
% ask for colors
%% Figure making time
for current_plot = 2:2
for s = 1:numel(unique_strain)
    figure('Color','w','pos',[10 10 1200 800]);
    hold on;
    current_strain = unique_strain{s};
    curr_strain_numeric = pHMetadata.strain_numeric(find(strcmp(pHMetadata.strain,current_strain),1))
    for c = 1:numel(unique_conditions)
        current_condition = unique_conditions(c);
        curr_condition_numeric = pHMetadata.condition_numeric(find(strcmp(pHMetadata.condition,current_condition),1))

    if current_plot == 1 % plot ODs
        columns_to_plot = intersect(find(pHMetadata.condition_numeric == curr_condition_numeric),find(pHMetadata.strain_numeric == curr_strain_numeric));
        plot_type = 'OD'
        current_title = ['{\it ' current_strain '} growth in Mega Medium'];
       %time_vals = growth_data.data.ODs(numel(metadata_labels)+1:end,1);

       % remove outliers
       curr_data = data_OD(:,columns_to_plot)
        outliers_all_data = isoutlier(curr_data(50:end,:),2);
        outliers = mean(outliers_all_data);
        [~,sort_outliers]=sort(outliers);
        to_keep = sort_outliers(1:3)
        filtered_data = curr_data(:,to_keep)

% % this plots all the curves and then all the ones that passed the
% % outlier filter in thicker lines
%             figure(2)
%             subplot(4,2,c)
%             hold on;
%             plot(time, curr_data,'LineWidth',1)
%             plot(time, filtered_data,'LineWidth',4)
%             suptitle(current_strain)
%             title(current_condition)
%             hold off;
%         pause;
         mean_vals = nanmean(filtered_data,2);
         stdev_vals = nanstd(filtered_data,0,2);
         ylabel_text = 'OD600 (Min corrected)'

    else % plot pH
        columns_to_plot = (converted_data(2,:) == curr_condition_numeric & converted_data(1,:) == curr_strain_numeric);
        plot_type = 'pH'
        current_title = ['pH of media during ' current_strain ' growth in Mega Medium'];
        %time_vals = growth_data.data.x440(numel(metadata_labels)+1:end,1)
        mean_vals = nanmean(converted_data(4:end,columns_to_plot),2);
        stdev_vals = nanstd(converted_data(4:end,columns_to_plot),0,2);
        ylabel_text = 'pH'
    end

    [hLine(c), hPatch(c)] = boundedline(time,mean_vals,stdev_vals,'cmap',condition_colors(c,:),'nan', 'gap','alpha');
    end


    set(hLine,'LineWidth',2)
    legend([hLine(5) hLine(6) hLine(7) hLine(8) hLine(3) hLine(4) hLine(1) hLine(2)],{unique_conditions{5} unique_conditions{6} unique_conditions{7} unique_conditions{8} unique_conditions{3} unique_conditions{4} unique_conditions{1} unique_conditions{2}},'Location','northeast')

    xlabel('Time (hours)')
    xlim([0 100])
    
    ylabel(ylabel_text)
    set(gca, 'FontName', 'Myriad Pro')
    title(current_title);

    set(gca,'FontSize',16)
    set(0, 'DefaultFigureRenderer', 'Painters');
    hold off;
    print(sprintf('%s_%s_experiment_%s.pdf',current_strain,plot_type,erase(file,'.xlsx')),'-dpdf','-bestfit');
    export_fig(sprintf('%s_%s_experiment_%s.png',current_strain,plot_type,erase(file,'.xlsx')),'-m2.5');
    close all
end
end
