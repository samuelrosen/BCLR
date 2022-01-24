function matrix2latex(matrix,filename,varargin)
% function: matrix2latex(...)
% Author:   M. Koehler
% Contact:  koehler@in.tum.de
% Version:  1.1
% Date:     May 09, 2004

% This software is published under the GNU GPL, by the free software
% foundation. For further reading see: http://www.gnu.org/licenses/licenses.html#GPL

% Usage:
% matrix2latex(matrix, filename, varargs)
% where
%   - matrix is a 2 dimensional numerical or cell array
%   - filename is a valid filename, in which the resulting latex code will
%   be stored
%   - varargs is one ore more of the following (denominator, value) combinations
%      + 'rowLabels', array -> Can be used to label the rows of the
%      resulting latex table
%      + 'columnLabels', array -> Can be used to label the columns of the
%      resulting latex table
%      + 'alignment', 'value' -> Can be used to specify the alginment of
%      the table within the latex document. Valid arguments are: 'l', 'c',
%      and 'r' for left, center, and right, respectively
%      + 'format', 'value' -> Can be used to format the input data. 'value'
%      has to be a valid format string, similar to the ones used in
%      fprintf('format', value);
%      + 'size', 'value' -> One of latex' recognized font-sizes, e.g. tiny,
%      HUGE, Large, large, LARGE, etc.
%
% Example input:
%   matrix = [1.5 1.764; 3.523 0.2];
%   rowLabels = {'row 1', 'row 2'};
%   columnLabels = {'col 1', 'col 2'};
%   matrix2latex(matrix, 'out.tex', 'rowLabels', rowLabels, 'columnLabels', columnLabels, 'alignment', 'c', 'format', '%-6.2f', 'size', 'tiny'...
%                   , 'bold', 0, 'parentheses', paraentheses_matrix);
%
% The resulting latex file can be included into any latex document by:
% \input{out.tex}

% Edited by A. MacKinlay 2/06/09:
% Changes to program:
% 1. Eliminated vertical lines and horizontal lines arguments.
% 2. Add argument to have bold row and/or column.
% 3. Add argument to put parentheses around certain elements.
% 4. Added ability to give column header for the rows names, (for upper
% left corner)
% 5. Added argument to leave certain parts of the matrix blank when
% converted to table.


% Edited by A. MacKinlay 6/23/09:
% Changes to program:
% 1. Added ability to use both () (parenthesis matrix has value of 1) and
% [] (parenthesis matrix has a value of 2)

rowLabels = [];
colLabels = [];
alignment = 'l';
bold = 0; % 0 for no bold row or column headers, 1 for bold column headers, 2 for bold row headers, 3 for bold row and column headers;
parentheses = []; % matrix with 0 if no parentheses, 1 with parentheses, 2 with square brackets.
leaveblank = []; % matrix with 0 if there is an element, 1 if it is to be left blank
format = [];
textsize = [];
if (rem(nargin,2) == 1 || nargin < 2)
    error('matrix2latex: Incorrect number of arguments to %s.', mfilename);
end

okargs = {'rowlabels','columnlabels', 'alignment', 'format', 'size', 'bold', 'parentheses', 'leaveblank'};
for j=1:2:(nargin-2) %#ok<*FXUP>
    pname = varargin{j};
    pval = varargin{j+1};
    k = strmatch(lower(pname), okargs); %#ok<MATCH2>
    if isempty(k)
        error('matrix2latex: Unknown parameter name: %s.', pname);
    elseif length(k)>1
        error('matrix2latex: Ambiguous parameter name: %s.', pname);
    else
        switch(k)
            case 1  % rowlabels
                rowLabels = pval;
                if isnumeric(rowLabels)
                    rowLabels = cellstr(num2str(rowLabels(:)));
                end
            case 2  % column labels
                colLabels = pval;
                if isnumeric(colLabels)
                    colLabels = cellstr(num2str(colLabels(:)));
                end
            case 3  % alignment
                alignment = lower(pval);
                if strcmp(alignment,'right') == 1
                    alignment = 'r';
                end
                if strcmp(alignment,'left') == 1
                    alignment = 'l';
                end
                if strcmp(alignment,'center') == 1
                    alignment = 'c';
                end
                if alignment ~= 'l' && alignment ~= 'c' && alignment ~= 'r'
                    alignment = 'd';
                    %                     warning('matrix2latex: ', 'Unknown alignment. (Set it to \''left\''.)');
                end
            case 4  % format
                format = lower(pval);
            case 5  % Font size
                textsize = pval;
            case 6  % Bold row/column headers
                bold = pval;
            case 7  % Parentheses
                parentheses = pval;
            case 8  % Leave Blank
                leaveblank = pval;
        end
    end
end

if isequal(filename, '__MCL')
    
    outputstr = '';
    
    width = size(matrix, 2);
    height = size(matrix, 1);
    
    if(isempty(parentheses))
        parentheses = zeros(height,width);
    end
    
    if(isempty(leaveblank))
        leaveblank = zeros(height,width);
    end
    
    if isnumeric(matrix)
        matrix = num2cell(matrix);
        for h=1:height
            for w=1:width
                if(~isempty(format))
                    matrix{h, w} = num2str(matrix{h, w}, format);
                else
                    matrix{h, w} = num2str(matrix{h, w});
                end
            end
        end
    end
    
    if(~isempty(textsize))
        outputstr = strcat(outputstr, sprintf('\\begin{%s}', textsize) );
    end
    
    outputstr = strcat(outputstr,sprintf('\r\\n\b\b$\r\\n\b\b\\left(\r\\n\b\b\\begin{array}{') );
    
    if(~isempty(rowLabels))
        outputstr = strcat(outputstr, sprintf( 'l') );
    end
    
    for i=1:width
        outputstr = strcat(outputstr, sprintf('%c', alignment) );
    end
    
    outputstr = strcat(outputstr, sprintf('}\r\\n\b\b') );
    
    if(~isempty(colLabels))
        if(~isempty(rowLabels))
            %             Takes account of whether there is a column label for the row
            %             labels
            if size(colLabels,2)==(width+1)
                colwidth = width+1;
                width_start = 2;
                if bold==1 || bold==3
                    outputstr = strcat(outputstr, sprintf('\\textbf{%s}&', colLabels{1}));
                else
                    outputstr = strcat(outputstr, sprintf('%s&', colLabels{1}));
                end
            else
                colwidth = width;
                width_start = 1;
                outputstr = strcat(outputstr, sprintf('&'));
            end
        end
        if bold==1 || bold==3
            for w=width_start:colwidth-1
                outputstr = strcat(outputstr, sprintf('\\textbf{%s}&', colLabels{w}) );
            end
            outputstr = strcat(outputstr, sprintf('\\textbf{%s}\\\\\\hline\r\\n\b\b', colLabels{colwidth}) );
        else
            for w=width_start:colwidth-1
                outputstr = strcat(outputstr, sprintf('%s&', colLabels{w}) );
            end
            outputstr = strcat(outputstr, sprintf('%s\\\\\\hline\r\\n\b\b', colLabels{colwidth}) );
        end
    end
    
    for h=1:height
        if(~isempty(rowLabels))
            if bold==2 || bold==3
                outputstr = strcat(outputstr, sprintf('\\textbf{%s}&', rowLabels{h}) );
            else
                outputstr = strcat(outputstr, sprintf('%s&', rowLabels{h}) );
            end
        end
        for w=1:width-1
            if parentheses(h,w) == 1
                outputstr = strcat(outputstr, sprintf('(%s)&', matrix{h, w}) );
            elseif parentheses(h,w) == 2
                outputstr = strcat(outputstr, sprintf('[%s]&', matrix{h, w}) );
            elseif leaveblank(h,w) == 1
                outputstr = strcat(outputstr, sprintf('&'));
            else
                outputstr = strcat(outputstr, sprintf('%s&', matrix{h, w}) );
            end
        end
        if parentheses(h,width) == 1
            outputstr = strcat(outputstr, sprintf('(%s)\\\\\r\\n\b\b', matrix{h, width}) );
        elseif parentheses(h,w) == 2
            outputstr = strcat(outputstr, sprintf('[%s]&', matrix{h, w}) );
        elseif leaveblank(h,width) == 1
            outputstr = strcat(outputstr, sprintf('\\\\\r\\n\b\b'));
        else
            outputstr = strcat(outputstr, sprintf('%s\\\\\r\\n\b\b', matrix{h, width}) );
        end
    end
    
    outputstr = strcat(outputstr, sprintf('\hline\\end{array}\r\\n\b\b\\right)\r\\n\b\b$\r\\n\b\b') );
    
    if(~isempty(textsize))
        outputstr = strcat(outputstr, sprintf('\\end{%s}', textsize) );
    end
    sprintf('%s',outputstr)
    
else
    
    fid = fopen(filename, 'w');
    
    width = size(matrix, 2);
    height = size(matrix, 1);
    
    if(isempty(parentheses))
        parentheses = zeros(height,width);
    end
    
    if(isempty(leaveblank))
        leaveblank = zeros(height,width);
    end
    
    if isnumeric(matrix)
        matrix = num2cell(matrix);
        for h=1:height
            for w=1:width
                if(~isempty(format))
                    matrix{h, w} = num2str(matrix{h, w}, format);
                else
                    matrix{h, w} = num2str(matrix{h, w});
                end
            end
        end
    end
    
    if(~isempty(textsize))
        fprintf(fid, '\\begin{%s}', textsize);
    end
    
    fprintf(fid, '\\begin{tabular}{');
    
    if(~isempty(rowLabels))
        fprintf(fid, 'l');
    end
    
    for i=1:width
        fprintf(fid, '%c', alignment);
    end
    
    fprintf(fid, '}\r\n');
    
    fprintf(fid, '\\hline\r\n');
    
    if(~isempty(colLabels))
        if(~isempty(rowLabels))
            if size(colLabels,2)==(width+1)
                colwidth = width+1;
                width_start = 2;
                if bold==1 || bold==3
                    fprintf(fid, '\\textbf{%s}&', colLabels{1});
                else
                    fprintf(fid, '%s&', colLabels{1});
                end
            else
                colwidth = width;
                width_start = 1;
                fprintf(fid, '&');
            end
        end
        if bold==1 || bold==3
            for w=width_start:colwidth-1
                fprintf(fid, '\\textbf{%s}&', colLabels{w});
            end
            fprintf(fid, '\\textbf{%s}\\\\\\hline\r\n', colLabels{colwidth});
        else
            for w=width_start:colwidth-1
                fprintf(fid, '%s&', colLabels{w});
            end
            fprintf(fid, '%s\\\\\\hline\r\n', colLabels{colwidth});
        end
    end
    
    for h=1:height
        if(~isempty(rowLabels))
            if bold==2 || bold==3
                fprintf(fid, '\\textbf{%s}&', rowLabels{h});
            else
                fprintf(fid, '%s&', rowLabels{h});
            end
        end
        for w=1:width-1
            if parentheses(h,w)==1
                fprintf(fid, '(%s)&', matrix{h, w});
            elseif parentheses(h,w)==2
                fprintf(fid, '[%s]&', matrix{h, w});
            elseif leaveblank(h,w)==1
                fprintf(fid, '&');
            else
                fprintf(fid, '%s&', matrix{h, w});
            end
        end
        if parentheses(h,width)==1
            fprintf(fid, '(%s)\\\\\r\n', matrix{h, width});
        elseif parentheses(h,width)==2
            fprintf(fid, '[%s]\\\\\r\n', matrix{h, width});
        elseif leaveblank(h,width)==1
            fprintf(fid, '\\\\\r\n');
        else
            fprintf(fid, '%s\\\\\r\n', matrix{h, width});
        end
    end
    
    fprintf(fid, '\\hline\\end{tabular}\r\n');
    
    if(~isempty(textsize))
        fprintf(fid, '\\end{%s}', textsize);
    end
    
    fclose(fid);
end
