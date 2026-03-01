function createModelCoeffImage(folderpath_cold, yy, mm, dd, varargin)
%createModelCoeffImage This function is to create coeff images, such as a0 and slope,
%based on the results of continous change detection (CCD).
%
% INPUT:
%
%   folderpath_cold:        Locate to COLD working folder, in which the
%                           change folder <TSFitLine> is necessery, and
%                           this folder was created by <COLD.m>.
%
%   year:                   [Number] The year of synthtic image. 
%
%   mm:                     [Number] The month or DOY of synthtic image. 
%
%   dd (optional):          [Number] The day of synthtic image. When dd =
%                           [], this function will consider mm as DOY.
%
%   lbands (optional):      Landsat bands. Default: [1, 2, 3, 4, 5, 7]
%
%   coeffs (optional):      Coefficents. Default: {'a0', 'c1', 'a1', 'b1', 'rmse'}
%
%   centover (optional):    [true/false] To adjust a0 to the central date or not. Default: [false] we will adjust the prefined date.
%
%   compress (optional):    [true/false] Compress all the files into a tar.
%                           (default value: false)
%
%   msg (optional):         [false/true] Display processing status (default
%                           value: false)
%
% REFERENCE(S):
%
%
% EXAMPLE OF USE:
%
%   > To create a coeff image for 07/01/2000
%
%     createModelCoeffImage('/lustre/scratch/qiu25856/TestGERSToolbox/h029v005/',
%     2000, 7, 1)
%
%   > To create a synthetic image for DOY 171, 2000
%
%     createModelCoeffImage('/lustre/scratch/qiu25856/TestGERSToolbox/h029v005/',
%     2000, 171)
% 
% AUTHOR(s): Shi Qiu and Zhe Zhu
% DATE: July 14, 2021
% COPYRIGHT @ GERSLab


    addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'CCD'));
    addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'GRIDobj'));
    
    % optional
    p = inputParser;
    addParameter(p,'lbands', [1,2,3,4,5,7]); % not to generate the qa band of synthetic data
    addParameter(p,'coeffs', {'a0', 'c1', 'a1', 'b1', 'rmse'}); % not to display info
    addParameter(p,'compress', true); % not to generate the qa band of synthetic data
    addParameter(p,'centover', false); % not to adjust a0 to the central date or not
    addParameter(p,'msg', false); % not to display info
    parse(p,varargin{:});
    msg = p.Results.msg;
    compress = p.Results.compress;
    lbands = p.Results.lbands;
    coeffs = p.Results.coeffs;
    centover = p.Results.centover;

    bands_index = lbands;
    bands_index(lbands == 7) = 6;
    bands_index(lbands == 6) = 7;% label as 7
    
    % define date
    if yy>0
        if mm>0&&~isempty(dd)&&dd>0 % using yyyy/mm/dd
            % converted to julian date
            j_date=datenum(yy,mm,dd);
%             j0_date=datenum(yy,1,0);
%             doy = j_date-j0_date;
            % date for show i.e. 19990815
            s_date=yy*10000+mm*100+dd;
%             s_date = yy*1000 + doy;
        elseif mm>0 % using yyyy DOY
            j_date = datenum(yy,1,0) + mm;
            s_date = yy*1000 + mm;
        end
    end
    
    [~, foldername_working] = fileparts(folderpath_cold);
    if msg
        fprintf('Start to coeff image on %d for %s\r\n', s_date, foldername_working);
    end

    folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine');
    if ~isfolder(folderpath_tsf) % also support the old name <TSFitMap>
        folderpath_tsf = fullfile(folderpath_cold, 'TSFitMap');
    end
    %% Image folder
    folderpath_syn = fullfile(folderpath_cold, 'CoeffImage');

    
    %% get metadata
    load(fullfile(folderpath_cold, 'metadata.mat'));
    geotif_obj = metadata.GRIDobj;
    geotif_obj.Z = uint16(geotif_obj.Z);
    nrows = metadata.nrows;
    ncols = metadata.ncols;
    % dimension and projection of the image
    jiDim = [ncols,nrows];
%     nbands = metadata.nbands; % 7 Landsat bands + 1 QA band
    ncoefs = 8; % number of model coeffs 
    
    filename_syn = sprintf('CM_%s_%s_%d', metadata.region, [metadata.tile(2:4), metadata.tile(6:8)], s_date);  % C: Coefficents % M: Model of CCD
    
    %% check exist: .tar
    if isfile(fullfile(folderpath_syn, [filename_syn, '.tar']))
        if msg
            fprintf('Already exist coeff image %s\r\n', [filename_syn, '.tar']);
        end
        return;
    end
    
    %% check exist: folder with uncompress
    if isfolder(fullfile(folderpath_syn, filename_syn))
         iband = 1;
         lackdata = 0;
        for ib = bands_index
            % band name
            if ib <=5
                bandname = sprintf('SRB%d', ib);
            end
            if ib == 6
                bandname = sprintf('SRB%d', 7); % swir 2 band of Landsat
            end
            if ib == 7
                bandname = sprintf('BTB%d', 6); % thermal band
            end
            % for each coeff
            for k_c=1:length(coeffs) % each coeff
                filepath_check = fullfile(folderpath_syn, filename_syn, sprintf('%s_%s_%s.tif', filename_syn, bandname, coeffs{k_c}));
                if ~isfile(filepath_check)
                    lackdata = 1;
                    break;
                end
                iband = iband + 1;
            end
        end
          
        if ~lackdata
            if msg
                fprintf('Already exist coeff image %s\r\n', filename_syn);
            end
            return;
        end
    end
    
    %% create folder if no
    if ~isfolder(folderpath_syn)
        mkdir(folderpath_syn);
    end
    % synthetic image's name
    dir_out_syn = fullfile(folderpath_syn, filename_syn);
    if ~isfolder(dir_out_syn)
        mkdir(dir_out_syn);
    end
    
    %% Sync starts ...

    % produce synthetic data (1, 2, 3, 4, 5, 7, 6, and QA)
    coeffslayer = zeros(nrows, ncols, length(bands_index)*length(coeffs)); % 1. change here for excluding thermal
    imf=dir(fullfile(folderpath_tsf, 'record_change*.mat')); % folder names
    num_line = size(imf,1);

    %% line by line
    tic
    for line = 1: num_line
        % show processing status
        if msg
            if line/num_line < 1
                fprintf('Processing %.2f percent\r',100*(line/num_line));
            else
                fprintf('Processing %.2f percent\n',100*(line/num_line));
            end
        end
        load(fullfile(folderpath_tsf,imf(line).name));

        % postions & coefficients
        pos = [rec_cg.pos];
        % continue if there is no model available
        l_pos = length(pos);
        if l_pos == 0
            continue;
        end
        % get coefficients matrix
        coefs = [rec_cg.coefs];
        % reshape coefs
%         coefs = reshape(coefs,nbands*ncoefs,l_pos);
        coefs = reshape(coefs,size(rec_cg(1).coefs,1)*size(rec_cg(1).coefs,2),l_pos);
  
        rmses = [rec_cg.rmse];
        rmses = reshape(rmses,size(rec_cg(1).rmse,1)*size(rec_cg(1).rmse,2),l_pos);
        
        % get category matrix
%         category = [rec_cg.category];
        % take the first digit (number of coefficients)
%         category = category - 10*floor(category/10);

        % model start, end, & break time for prediction
        model_start = [rec_cg.t_start];
        model_end = [rec_cg.t_end];
        model_break = [rec_cg.t_break];
        clear rec_cg;
        % model on the right
        ids_right = model_start > j_date;
        % model on the left
        ids_left = (model_end < j_date & model_break == 0)|(model_break <= j_date & model_break > 0);
        % id within model interval
        ids_middle = model_start <= j_date & ((model_end >= j_date & model_break == 0) | (model_break > j_date & model_break > 0));
        clear model_start;

        % position for model in the middle
        pos_middle = pos(ids_middle);
        % coefficients for model in the middle
        coefs_middle = coefs(:,ids_middle);
        rmses_middle = rmses(:,ids_middle);
        model_start_middle = model_start(ids_middle);
        model_end_middle = model_end(ids_middle);
        % category for model in the middle
%         category_middle = category(ids_middle);
        clear ids_middle;

        % positions for the nearest model on the right
        pos_right = pos(ids_right);
        [pos_near_right,ids_near_right] = unique(pos_right,'first');
        % coefficients for the nearest model on the right
        coefs_right = coefs(:,ids_right);
        rmses_right = rmses(:,ids_right);
        coefs_near_right = coefs_right(:,ids_near_right);
        rmses_near_right = rmses_right(:,ids_near_right);
        model_start_right = model_start(ids_near_right);
        model_end_right = model_end(ids_near_right);
        % category for the nearest model on the right
%         category_right = category(ids_right);
        clear ids_right;
%         category_near_right = category_right(ids_near_right);
        clear category_right ids_near_right;

        % postions for the nearest model on the left
        pos_left = pos(ids_left);
        [pos_near_left,ids_near_left] = unique(pos_left,'last');
        % coefficients for the nearest model on the left
        coefs_left = coefs(:, ids_left);
        rmses_left = rmses(:, ids_left);
        clear coefs;
        coefs_near_left = coefs_left(:,ids_near_left);
        rmses_near_left = rmses_left(:,ids_near_left);
        model_start_left = model_start(ids_near_left);
        model_end_left = model_end(ids_near_left);
        clear coefs_left;
        % category for the nearest model on the left
%         category_left = category(ids_left);
        clear ids_left category;
%         category_near_left = category_left(ids_near_left);
        clear category_left ids_near_left;
        % pass if there is no nearest model on the left 
        l_pos=length(pos_near_left);
        if l_pos > 0  
            % providing predictions
            for i=1:l_pos
                [I,J]=ind2sub(jiDim,pos_near_left(i));
                iband = 1;
                for j_b = bands_index
                    fit_cft = coefs_near_left(((j_b-1)*ncoefs+1):j_b*ncoefs,i);
                    fit_rmse = rmses_near_left(j_b, i);
                    for k_c=1:length(coeffs) % each coeff
                        switch coeffs{k_c}
                            case 'a0'
                                if centover
                                    coeffslayer(J,I,iband)=fit_cft(1) + ((model_start_left(i) + model_end_left(i))./2)*fit_cft(2); % adjust
                                else
                                    coeffslayer(J,I,iband)=fit_cft(1) + j_date*fit_cft(2); % adjust
                                end
                            case 'c1'
                                coeffslayer(J,I,iband)=fit_cft(2);
                            case 'a1'
                                coeffslayer(J,I,iband)=fit_cft(3);
                            case 'b1'
                                coeffslayer(J,I,iband)=fit_cft(4);
                            case 'a2'
                                coeffslayer(J,I,iband)=fit_cft(5);
                            case 'b2'
                                coeffslayer(J,I,iband)=fit_cft(6);
                            case 'a3'
                                coeffslayer(J,I,iband)=fit_cft(7);
                            case 'b3'
                                coeffslayer(J,I,iband)=fit_cft(8);
                            case 'rmse'
                                coeffslayer(J,I,iband)=fit_rmse;
                        end
                        iband =  iband + 1;
                    end    
                end
            end
        end
        clear category_near_left pos_near_left;

        % pass if there is no nearest model on the right 
        l_pos=length(pos_near_right);
        if l_pos > 0  
            % providing predictions
            for i=1:l_pos
                [I,J]=ind2sub(jiDim,pos_near_right(i));
               
                iband = 1;
                for j_b=bands_index
                    fit_cft =  coefs_near_right(((j_b-1)*ncoefs+1):j_b*ncoefs,i);
                    fit_rmse = rmses_near_right(j_b, i);
                    for k_c=1:length(coeffs) % each coeff
                        switch coeffs{k_c}
                            case 'a0'
                                if centover
                                    coeffslayer(J,I,iband)=fit_cft(1) + ((model_start_right(i) + model_end_right(i))./2)*fit_cft(2); % adjust
                                else
                                    coeffslayer(J,I,iband)=fit_cft(1) + j_date*fit_cft(2); % adjust
                                end
                            case 'c1'
                                coeffslayer(J,I,iband)=fit_cft(2);
                            case 'a1'
                                coeffslayer(J,I,iband)=fit_cft(3);
                            case 'b1'
                                coeffslayer(J,I,iband)=fit_cft(4);
                            case 'a2'
                                coeffslayer(J,I,iband)=fit_cft(5);
                            case 'b2'
                                coeffslayer(J,I,iband)=fit_cft(6);
                            case 'a3'
                                coeffslayer(J,I,iband)=fit_cft(7);
                            case 'b3'
                                coeffslayer(J,I,iband)=fit_cft(8);
                            case 'rmse'
                                coeffslayer(J,I,iband)=fit_rmse;
                        end
                        iband =  iband + 1;
                    end    
                end       
            end
        end
        clear category_near_right pos_near_right;

        % pass if there is no nearest model in the middle 
        l_pos=length(pos_middle);
        if l_pos > 0  
            % providing estimations
            for i=1:l_pos
                [I,J]=ind2sub(jiDim,pos_middle(i));
                iband = 1;
                for j_b= bands_index
                    fit_cft = coefs_middle(((j_b-1)*ncoefs+1):j_b*ncoefs,i);
                    fit_rmse = rmses_middle(j_b, i);
                    for k_c=1:length(coeffs) % each coeff
                        switch coeffs{k_c}
                            case 'a0'
                                if centover
                                    coeffslayer(J,I,iband)=fit_cft(1) + ((model_start_middle(i) + model_end_middle(i))./2)*fit_cft(2); % adjust
                                else
                                    coeffslayer(J,I,iband)=fit_cft(1) + j_date*fit_cft(2); % adjust
                                end
                            case 'c1'
                                coeffslayer(J,I,iband)=fit_cft(2);
                            case 'a1'
                                coeffslayer(J,I,iband)=fit_cft(3);
                            case 'b1'
                                coeffslayer(J,I,iband)=fit_cft(4);
                            case 'a2'
                                coeffslayer(J,I,iband)=fit_cft(5);
                            case 'b2'
                                coeffslayer(J,I,iband)=fit_cft(6);
                            case 'a3'
                                coeffslayer(J,I,iband)=fit_cft(7);
                            case 'b3'
                                coeffslayer(J,I,iband)=fit_cft(8);
                            case 'rmse'
                                coeffslayer(J,I,iband)=fit_rmse;
                        end
                        iband =  iband + 1;
                    end    
                end       
            end
        end  
        clear category_middle pos_middle l_pos;  
    end
    
    % save disturbance image
    
    iband = 1;
    for ib = bands_index
        % band name
        if ib <=5
            bandname = sprintf('SRB%d', ib);
        end
        if ib == 6
            bandname = sprintf('SRB%d', 7); % swir 2 band of Landsat
        end
        if ib == 7
            bandname = sprintf('BTB%d', 6); % thermal band
        end
        % for each coeff
        for k_c=1:length(coeffs) % each coeff
            
            geotif_obj.Z = coeffslayer(:,:,iband);
            
            GRIDobj2geotiff(geotif_obj, fullfile(dir_out_syn, sprintf('%s_%s_%s.tif', filename_syn, bandname, coeffs{k_c})));
            iband = iband + 1;
        end
    end
              
    clear geotif_obj coeffslayer;
    if compress
        tar( fullfile(folderpath_syn, [filename_syn, '.tar']), {fullfile(dir_out_syn, 'CM*.tif')});
        rmdir(fullfile(folderpath_syn, filename_syn), 's'); % delete the data folder
    end
    if msg
        fprintf('Finished creating model coeff image for %s with %0.2f mins\r\n', filename_syn, toc/60); 
    end

end
