# MatlabCsvWrite

This MATLAB class lets you create or open csv files that can be read by MATLAB's `readtable()` function. A typical scenario would be to conduct a large experiment to evaluate the performance of an algorithm and to successively append the result of each test condition to a csv file. This could be easier and faster than expanding a (probably) large table in MATLAB in each iteration. Another advantage could be the cross-platform and cross-language property of csv files. That way a csv file could easily be opened in *Python* (using e.g. Pandas) or *R*.

Dependencies
------------------------

There are no special dependencies to the class, since it will use rudimentary text file routines.

Methods
------------------------

```matlab
>> methods(WriteTableCsv)

Methods for class WriteTableCsv:

WriteTableCsv  close          open           writeHeader
append         delete         status
```

The constructor's arguments are the desired filename of the csv file and the file mode ('create' to create or overwrite an existing csv file, 'append' to create or append and existing csv file). The file mode is optional and defaults to 'create'.  
`obj = WriteTableCsv(filename)`  
`obj = WriteTableCsv(filename, 'create')`  
`obj = WriteTableCsv(filename, 'append')`  

A header line can be written both in an empty and in a nonempty file containing data! The argument must be a cell string array whose number of elements correspond to the columns of data to be written or present in the file. Each cell will be the header for one column: `obj.writeHeader({'First', 'Second', 'Third'})`

The `status` method lets you see information about the number of columns and data rows (excluding the header if present) and the header (if present). Also a preview of the data is shown by printing the first and last couple of data lines.

The `open` methods lets you both open and create a csv file. This method is also called by the constructor. `obj.open(filename)`.

The `close` method closes the currently opened file: `obj.close()`.


Usage
---------------------

The following is an example of the typical (intended) workflow. Supported file extensions are `csv`, `dat` and `txt` in accordance with the `readtable()` function.

```matlab
filename = 'results.csv';
obj = WriteTableCsv(filename);

obj.writeHeader({'Name', 'SNR', 'Result'});

for iCondition = 1:numConditions
    snr = 19;
    algoName = 'algo3';
    thisResult = algorithm();

    data = {algoName, snr, thisResult};

    obj.append(data);
end

obj.close;
% or delete the object
```

The beginning of the corresponding file `results.csv` would look similar to the following.

```
Name,SNR,Result
algo3,-4,0.973164838429023
algo1,-18,0.201787740900155
algo4,12,0.350602315361081
algo3,17,0.607117601767853
algo3,2,0.548299571749886
algo3,14,0.133907855848347
algo4,-8,0.626515936141886
algo3,19,0.0913844653898596
...
...
...
```

License
---------------------

The Code is licensed under BSD 3-Clause license.
