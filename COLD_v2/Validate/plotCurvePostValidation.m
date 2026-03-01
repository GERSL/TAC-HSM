function plotCurvePostValidation(varargin)
%   This function create Comi-Omi diagram after running calculateF1score.m using a series parameters.
%   We are expected to find the optimal values of cprob and conse.

close all;
addpath('/home/kes20012/COLD_v2/CCD');
addpath('/home/kes20012/COLD_v2/Validate');


% sensorname = 'L30';
% sensorname = 'HLS';
sensorname = 'S2';
% tilename = {'18TXM','18TXL','18TYM','18TYL'};
tilename = {'18TXM'};
start_year = 2015;
folderpath_accuracy = fullfile('/shared/cn450/Sentinel-2/COLDResults/Accuracy',sensorname);
if ~isfolder(folderpath_accuracy)
    mkdir(folderpath_accuracy);
end
cd(folderpath_accuracy);


cprob = 0.99;
conse = 8;
% conse = [6,7,8,9,10];
bands1 = [2,3,7:9];           % same as COLD paper 
bands2 = [2:10];              % Sentinel-2 bands
bands3 = [2:10,11,12,14];     % Sentinel-2 bands + NDVIs
bands4 = [2:10,13,15,16,17];  % Sentinel-2 bands + red-edge NDVIs
bands5 = [2:17];              % Sentinel-2 bands + NDVIs + red-edge NDVIs
bands6 = [2:18];              % Sentinel-2 bands + NDVIs + red-edge NDVIs + NBR
B_detect = {bands1,bands2,bands3,bands4,bands5,bands6};


% pmarker = {'k-^','k-d','ko-','ks-','k->','k-<'};   % marker corresponds to B_detect
smarker = {'^','d','o','s','>','<'};   % marker corresponds to B_detect

%% First check if Commission and Omission already existed
% if not exist, calculate first; if exist, load values
% if length(dir(folderpath_accuracy))==2
%     
% COMI = zeros([length(cprob),length(conse)]);
COMI = [];
OMI = [];
% OMI = zeros([length(cprob),length(conse)]);
for i = 1:length(cprob)
    for j = 1:length(conse)
        for k = 1:length(B_detect)
%         fprintf('Start processing for Scenario T=%.2f, conse=%d, B_detect=%s.\r\n', cprob(i),conse(j),num2str(B_detect{k}));
%         COLDsamples('cprob',cprob(i),'conse',conse(j),'Tiles',tilename,'msg',false,...
%             'sensor',sensorname,'B_detect',B_detect{k});
%         fprintf('Complete COLD for cprob=%.2f,conse=%d, B_detect=%s\r\n',cprob(i),conse(j),num2str(B_detect{k}));
% %         COLDsamples('cprob',cprob(i),'conse',conse(j),'Tiles',{'18TXM','18TXL','18TYM','18TYL'},'msg',false);
%         exportDOYsamples_hybrid('sensor',sensorname,'Tiles',tilename,'scenario',k);
        [comi,omi,f1] = calculateF1score('sensor',sensorname,'Tiles',tilename,'start_year',start_year,'scenario',k);
%         
        COMI(k) = comi;
        OMI(k) = omi;
        F1(k) = f1;
        end
    end
end
% 
% save(fullfile(folderpath_accuracy,'COMI_S2.mat'),'COMI');
% save(fullfile(folderpath_accuracy,'OMI_S2.mat'),'OMI');
% %% Else
% load('COMI_2018.mat');
% load('OMI_2018.mat');
% end
% calculate F1-score
F1 = (1-OMI).*(1-COMI)./(2-OMI-COMI).*2;


% COMI = COMI(2:end,:);
% OMI = OMI(2:end,:);
% F1 = F1(2:end,:);

%% Part 2. Display scatter plot
figure
for j = 1:length(B_detect)

    % using scatter to plot markers only
    sz = 105;
    c = F1(j)*100;
    scatter(OMI(j)*100,COMI(j)*100,sz,c,'filled',smarker{j},'MarkerEdgeColor','none');
    hold on;
    
    h = plot(OMI(j)*100,COMI(j)*100,smarker{j},'LineWidth',1.0,'MarkerEdgeColor','k','MarkerSize',11,'DisplayName',string(B_detect{j})); 
    hold on;
end
hold off;

%% Add figure properties
cb = colorbar();
caxis([20,55]);
cb.Ticks = linspace(20,55,8);
cb.Title.String = 'F1 Score (%)';
cb.Title.FontSize = 11;
set(cb.XLabel,{'String','Rotation','Position'},{'XLabel',0,[0.5 0.5]});

xlim([40,100]);
ylim([40,100]);

xlabel('Omission Rate (%)');
ylabel('Commission Rate (%)');

legend(h);
% 
%% Save figures
% saveas(gcf,fullfile(folderpath_accuracy,[sensorname,'_',int2str(start_year),'_conse_',int2str(min(conse)),'_',int2str(max(conse)),'.png']));

end

