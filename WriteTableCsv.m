classdef WriteTableCsv < handle
%WRITETABLECSV Create and append csv file which is compliant to readtable()
% -------------------------------------------------------------------------
% This class lets you conveniently create and append text files in csv
% format, i.e. comma seperated data layout. WriteTableCsv opens existing
% csv files to further append data to it. Using the status() method,
% information about the data content of the file can be obtained.
%
% WriteTableCsv Properties:
%	NumberOfColumns - The number of data columns in the opened csv file
%
%	NumberOfDataRows - The number of data rows (i.e. without header row) in
%                      the opened csv file
%
%   Header - The content of the csv header row if present
%
%
% WriteTableCsv Methods:
%	WriteTableCsv - Class constructor. The argument is the desired file
%                   name and optionally the desired file mode. If the file
%                   exists and file mode is 'append' the file is opened.
%                   Else (file exists or not and file mode is 'create') the
%                   file is created.
%
%	writeHeader - method to write the data header into the csv file. Works
%                 for the cases when the file is empty or has content and
%                 already a header or has conent and has no header
%
%   append - append data to the csv file. The argument must be a cell with
%            numel == NumberOfColumns. Not supported data types in the
%            input cell: table, struct, cell
%
%   open - open a csv file. Also used by the class constructor. The
%          argument is the desired file name. If the file already exists
%          the file is opened. Else the file is created.
%
%   close - close an opened csv file. No arguments.
%
%   status - show information about the size layout of the csv file and
%            show a preview of the data if present.
%
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  06-May-2016 10:31:59
%

% Version:  v1.0   working appending and file infos, 06-May-2016 10:32 (JA)
%           v1.1   estimate csv header and proper input validation,
%                  07-May-2016 22:18 (JA)
%           v1.1.1 support .csv, .dat and .txt like readtable(),
%                  08-May-2016 10:15 (JA)
%           v1.1.2 display data preview with status() and fix header
%                  writer method, 08-May-2016 15:40 (JA)
%           v1.1.3 better documentation, 14-May-2016 20:32 (JA)
%           v1.2   implement file mode in the constructor to choose whether
%                  the file should be appended if it exists (JA)
%


properties ( Access = private, Constant)
    NumLinesToShow = 3;
end

properties (Access = private)
    FileID;
    LineCounter = 0;
    HasHeader = false;
end


properties (SetAccess = private, GetAccess = public)
    NumberOfColumns = 0;
    NumberOfDataRows = 0;
end


properties (Access = public)
    Header = {};
end



methods
    % Constructor
    function [self] = WriteTableCsv(filename, fileMode)
    %WRITETABLECSV Class constructor
    %
    % Usage: [obj] = WriteTableCsv(filename, fileMode)
    %
    % Input:  ---------------
    %       filename - desired filename (can contain a path)
    %       fileMode - can either be 'create' or 'append'. If 'create' is
    %                  chosen the csv file will be created or overwritten
    %                  if it exists. If 'append' is chosen the csv file
    %                  will be created or an existing file will be
    %                  appended. [default: 'create']
    %
    % Output: ---------------
    %       obj - WriteTableCsv object
    %
    %

        if ~nargin
            return;
        end
        
        narginchk(1,2);

        if nargin < 2 || isempty(fileMode)
            fileMode = 'create';
        end

        validateattributes(filename, {'char'}, {}, ...
            mfilename, ...
            'desired file name', ...
            1 ...
            );
        validateattributes(fileMode, {'char'}, {}, ...
            mfilename, ...
            'file modus', ...
            2 ...
            );
        fileMode = validatestring(fileMode, {'create', 'append'});

        % open or create the desired file
        self.open(filename, fileMode);

        % update content information (e.g. no. of rows and columns)
        self.updateFileInformation();
    end

    function [] = append(self, content)
    %APPEND Append data to csv file
    %
    % Usage: [] = append(obj, content)
    %
    % Input:  ---------------
    %       obj - a WriteTableCsv object
    %       content - cell containing data to be written to file. The cell
    %                 must not have more elements than the file has number
    %                 of columns,
    %                 i.e. numel(content) == obj.NumberOfColumns
    %
    % Output: ---------------
    %       none
    %
    %
        
        validateattributes(content, ...
            {'cell'}, ...
            {'numel', self.NumberOfColumns} ...
            );
        % TODO: estimate data types in each column to assert consistent
        % rows

        % parse and convert (if necessary) the input data types
        content = parseContent(content);
        % get the corresponding format string for fprintf()
        formatString = getContentFormatString(content);

        % write data to file
        fprintf(self.FileID, formatString, content{:});

        % update number of data rows
        self.updateNoOfRows();
    end



    function [] = writeHeader(self, header)
    %WRITEHEADER Create or update the data row in the csv file
    %
    % Usage: [] = writeHeader(obj, header)
    %
    % Input:  ---------------
    %       obj - a WriteTableCsv object
    %       header - cell containing header for each column. The cell
    %                must not have more elements than the file has number
    %                of columns,
    %                i.e. numel(content) == obj.NumberOfColumns
    %                If the file has no data the number of elements defines
    %                the number of columns for the file
    %
    % Output: ---------------
    %       none
    %
    %
        
        % if the file has data be sure to have correct number of elements
        if self.NumberOfColumns > 0
            validateattributes(header, ...
                {'cell'}, ...
                {'numel', self.NumberOfColumns} ...
                );
        else
            validateattributes(header, {'cell'}, {});
        end
        self.goToStart;

        % Do the following even when the file is empty, because it is fast
        % and works nontheless. This way we do not need to check if data
        % lines are present.
        
        % apparently the only way to manipulate lines in a text file is by
        % copying to a dummy file and copying desired lines back (-.-)
        oldFilename = fopen(self.FileID);
        newFilename = tempname;
        
        % open new temp file
        newID = fopen(newFilename, 'w');
        
        % discard first line and write new header
        fgetl(self.FileID);
        
        formatString = getHeaderFormatString(header);
        fprintf(newID, formatString, header{:});
        
        % and write remaining lines to new file
        line = fgetl(self.FileID);
        while ischar(line)
            fprintf(newID, line);
            fprintf(newID, '\n');
            line = fgetl(self.FileID);
        end
        
        % close both files
        self.close();
        fclose(newID);
        
        % and replace original file
        copyfile(newFilename, oldFilename);
        
        % open the new file and go to end file
        self.FileID = fopen(oldFilename, 'r+t');

        self.goToEnd();

        % update object's header and column information
        self.Header = header;
        self.HasHeader = true;
        self.updateNoOfColumns();
    end

    function [] = open(self, filename, fileMode)
    %OPEN Open or create a csv file
    %
    % Usage: [] = open(obj, filename)
    %
    % Input:  ---------------
    %       obj - a WriteTableCsv object
    %       filename - desired filename (can contain a path)
    %
    % Output: ---------------
    %       none
    %
    %

        if nargin < 3 || isempty(fileMode)
            fileMode = 'create';
        end

        % check for file extension and validate if it exists
        [filepath, name, extension] = fileparts(filename);
        if isempty(extension)
            extension = '.csv';
        end
        extension = validatestring(...
            extension, ...
            {'.csv', '.dat', '.txt'} ...
            );

        filename = fullfile(filepath, [name, extension]);

        % open with 'write' permissions and in 'text' mode (seems critical
        % on Windows PCs.
        % If the file exists and fileMode is 'append' it is not overwritten
        % but just opened for further editing
        if exist(filename, 'file') && strcmp(fileMode, 'append')
            permission = 'r+t';
        else
            permission =  'w+t';
        end
        fid = fopen(filename, permission, 'l', 'utf-8');

        % if the file could be opened pass the file id and be sure to go
        % to the end
        assert(fid > 0, 'File could not be opened! Check path and filename.');
        self.FileID = fid;

        self.goToEnd();
    end

    function [] = close(self)
    %CLOSE Close an opened csv file
    %
    % Usage: [] = close(obj)
    %
    % Input:  ---------------
    %       obj - a WriteTableCsv object
    %
    % Output: ---------------
    %       none
    %
    %
    
        fclose(self.FileID);
    end

    function [] = status(self)
    %STATUS Print file information to the command line
    %
    % Usage: [] = status(obj)
    %
    % Input:  ---------------
    %       obj - a WriteTableCsv object
    %
    % Output: ---------------
    %       none
    %
    %
        
        % if the file is presently opened be sure to have the latest file
        % information
        if self.isOpened()
            self.updateFileInformation();
        end

        statusText = {'Closed', 'Opened'};
        
        % construct strings before the colon and let them be right aligned
        leftKeys = char({'File Status:'; 'Number of Columns:'; 'Number of Data Rows:'});
        leftKeys = strjust(leftKeys, 'right');
        showStrings = cellstr(leftKeys);
        
        % construct the right hand side strings
        showStrings(:, 2) = {...
            statusText{self.isOpened() + 1}; ...
            num2str(self.NumberOfColumns); ...
            num2str(self.NumberOfDataRows) ...
            };
        
        % and print both
        for iRow = 1:size(showStrings, 1)
            fprintf('%s\n', strjoin(showStrings(iRow, :), '\t'));
        end
        fprintf('\n');
        
        % show a data preview of the first and last few data rows if the
        % file is opened
        if self.isOpened()
            fprintf('\n<strong>Data Preview:</strong>\n\n')
            self.displayContent();
            fprintf('\n');
        end
    end

    function [] = delete(self)
    %DELETE Class destructor
        
        % close the file if openend
        if ~isempty(self.FileID) && self.isOpened()
            fclose(self.FileID);
        end
    end
end






methods (Access = private)
    function [] = updateFileInformation(self)
    %UPDATEFILEINFORMATION Wrapper function to update file information
    
        self.readHeader();
        self.updateNoOfRows();
        self.updateNoOfColumns();
    end
    
    function [] = displayContent(self)
    %DISPLAYCONTENT Read data and print first and last few rows
        
        thisPosition = ftell(self.FileID);
        
        header = self.Header;
        skip = [];
        if isempty(header)
            header = arrayfun(@(x) sprintf('Var%d', x), 1:self.NumberOfColumns, ...
                'uni', false);
            skip = 0;
        end
        
        headerFormat = getHeaderFormatString(header);
        headerFormat = headerFormat(1:end-2); % remove \n
        headerString = sprintf(headerFormat, header{:});
        
        if isempty(skip)
            skip = length(headerString) + 1;
        end
        
        numRowsForDots = 3;
        % +2 for header row
        extractedLines = cell(self.NumLinesToShow * 2 + 2 + numRowsForDots, 1);
        
        extractedLines{1} = headerString;
        extractedLines{2} = repmat('-', 1, length(extractedLines{1}));
        
        extractedLines((self.NumLinesToShow + 3) : (end - self.NumLinesToShow)) = ...
            deal({'[. . .]'});
        
        % read first data lines
        fseek(self.FileID, skip, 'bof');
        for iLine = 3:self.NumLinesToShow + 2
            extractedLines{iLine} = fgetl(self.FileID);
        end

        numRows = self.countLines();
        for iLine = (self.NumLinesToShow + 1):numRows - self.NumLinesToShow - 1
            fgetl(self.FileID);
        end
        
        % read last data lines
        counter = ...
            length(extractedLines) - self.NumLinesToShow  + 1;
        for bla = 1:3
            extractedLines{counter} = fgetl(self.FileID);
            
            counter = counter + 1;
        end
        
        fprintf('\t%s\n', extractedLines{:});
        
        self.goTo(thisPosition);
    end

    function [] = readHeader(self)
        if self.HasHeader
            self.Header = self.readFirstLine();
        else
            self.Header = self.estimateHeader();
        end
    end

    function [] = updateNoOfRows(self)
        numLines = self.countLines();

        self.NumberOfDataRows = numLines - self.HasHeader;
    end

    function [] = updateNoOfColumns(self)
        if self.HasHeader
            self.NumberOfColumns = length(self.Header);
        else
            firstLine = self.readFirstLine();

            self.NumberOfColumns = length(firstLine);
        end
    end

    function [count] = countLines(self)
        % Quick implementation by reading large data chunks and counting
        % the number of new-line characters.
        % Source:
        % http://stackoverflow.com/a/12176781

        thisPosition = ftell(self.FileID);
        self.goToStart();

        count = 0;
        if thisPosition
            while ~feof(self.FileID)
                count = ...
                    count + ...
                    sum( fread(self.FileID, 16384, 'char') == char(10) );
            end
        end

        self.goTo(thisPosition);
    end

    function [firstLine] = readFirstLine(self)
        thisPosition = ftell(self.FileID);
        self.goToStart();

        line = fgetl(self.FileID);

        firstLine = [];
        if ischar(line)
            firstLine = strsplit(line, ',');
        end

        self.goTo(thisPosition);
    end

    function [header] = estimateHeader(self)
        header = [];

        thisPosition = ftell(self.FileID);
        self.goToStart;

        firstLine  = fgetl(self.FileID);

        % return if file is empty
        if ~ischar(firstLine)
            return;
        end

        lineWithoutDelimiter = strsplit(firstLine, ',');

        % let's see if the first line has numeric data. This makes clear
        % that the first line is no header line
        formatGuess = repmat('%f', 1, length(lineWithoutDelimiter));
        testOnNumeric = textscan(firstLine, formatGuess, ...
            'Delimiter', ',', ...
            'CollectOutput', true);
        testOnNumeric = testOnNumeric{:};

        % if the test on numeric value is negative, return the found header
        if isempty(testOnNumeric)
            header = lineWithoutDelimiter;
            self.HasHeader = true;
        end

        self.goTo(thisPosition);
    end

    function [yesNo] = isOpened(self)
        yesNo = ~isempty(fopen(self.FileID));
    end

    function [] = goToStart(self)
        frewind(self.FileID);
    end

    function [] = goToEnd(self)
        fseek(self.FileID, 0, 'eof');
    end

    function [] = goTo(self, thisPosition)
        fseek(self.FileID, thisPosition, 'bof');
    end
end







end

function [formatString] = getHeaderFormatString(header)

lenHeader = length(header);
formatString = ['%s', repmat(',%s', 1, lenHeader-1), '\n'];
end


function [contentOut] = parseContent(content)
% let's support:
% logicals -> 0/1,
% categoricals -> char,
% numeric -> numeric,
% string -> string
% datetime -> datestr
%
% let's reject:
% cell,
% struct,
% table
%

lenContent = length(content);

contentOut = cell(size(content));
for iElement = 1:lenContent
    thisElement = content{iElement};

    newElement = thisElement;

    if isa(thisElement, 'logical')
        newElement = double(thisElement);
    end
    if isa(thisElement, 'categorical')
        newTempElement = char(thisElement);

        if any(isletter(newTempElement))
            newElement = newTempElement;
        else
            newElement = double(thisElement);
        end
    end
    if isa(thisElement, 'datetime')
        newElement = datestr(thisElement);
    end

    % reject the following
    if isa(thisElement, 'table') ...
            || isa(thisElement, 'struct') ...
            || isa(thisElement, 'cell')

        error('Unsupported data type in Element %d', iElement);
    end

    contentOut{iElement} = newElement;
end
end


function [formatString] = getContentFormatString(content)
% let's support: string -> %s, numeric -> %g

lenContent = length(content);

formatString = cell(1, lenContent);
for iElement = 1:lenContent
    thisElement = content{iElement};

    thisFormat = [];
    if isa(thisElement, 'char'),    thisFormat = '%s';  end
    if isa(thisElement, 'numeric'), thisFormat = '%g';  end

    assert(...
        ~isempty(thisFormat), ...
        sprintf('Unknown data type in element %d!', iElement) ...
        );

    formatString{iElement} = [thisFormat, ','];
end
% remove last comma and add newline
formatString{end} = formatString{end}(1:end-1);
formatString{end + 1} = '\n';

formatString = cell2mat(formatString);
end



% End of file: WriteTableCsv.m
