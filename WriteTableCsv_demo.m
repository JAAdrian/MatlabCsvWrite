% Demo file to demonstrate WriteTableCsv()
%
% Author :  J.-A. Adrian (JA) <jensalrik.adrian AT gmail.com>
% Date   :  06-May-2016 11:07:03
%

clear;
close all;

filename = 'test.csv';

header = {'First', 'Second', 'Third'};

content1 = [1 2 3];
content2 = [4 5 6];

content3 = {true, 42, 'peter'};
content4 = {false, 13, 'pan'};


%% Create a test csv file and write a header and some data
obj = WriteTableCsv(filename);
obj.writeHeader(header);

obj.append(num2cell(content2));
obj.append(num2cell(content1));

obj.status;

obj.close;
obj.status;

%% Open the same file in 'append' mode and append some more data
obj.open(filename, 'append');
for i = 1:100
    obj.append(num2cell(rand(1,3)));
end
obj.status;

%% Overwrite the file and create a new test csv file
% the destructor should close the previous test.csv and create a new one
% while overwriting the old one
obj = WriteTableCsv('test.csv');
obj.writeHeader(header);
obj.append(content3);
obj.append(content4);

obj.status;
obj.close();

% End of file: WriteCsv_demo.m
