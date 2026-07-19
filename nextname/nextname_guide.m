%% |NEXTNAME| User Guide
%
% The function <https://www.mathworks.com/matlabcentral/fileexchange/64108
% |NEXTNAME|> returns a file or folder name, incrementing an integer value
% such that the returned name is not currently used by any file or folder.
%
% |NEXTNAME| supports *two* different input syntaxes, please read this
% documentation carefully to select the syntax suitable for your usecase.
%
%% Syntax 1: Basic Usage
%
% Call |NEXTNAME| with a |filename| which contains one integer within angle
% brackets (aka less/greater than symbols), other integers are ignored.
% The integer specifies the value to start incrementing from. For example
% creating new files in an empty folder and starting from the value 1:
name = nextname('A_<1>.txt') % syntax 1
dlmwrite(name,0)
name = nextname('A_<1>.txt') % syntax 1
dlmwrite(name,0)
name = nextname('A_<1>.txt') % syntax 1
dlmwrite(name,0)
%% Syntax 2: Separate Basename, Suffix, Extension
%
% Three inputs are required:
%
% # The file or folder |basename|, without any file extension. If the
%   location to check for existing files/folders is not the current
%   directory then the |basename| must include an absolute or relative
%   path to that location. All characters are treated literally.
% # A |suffix| that will get appended on to the end of the |basename|. The
%   |suffix| must contain exactly one integer number (zero or greater),
%   and may contain any other non-digit characters as required. The
%   integer specifies the value to start incrementing from.
% # The file |extension|, e.g. |'.txt'|, |'.mat'|, |'.csv'|, etc. Use
%   |''| for folder names or for files that do not require an extension.
%
% Note that |basename| and |extension| are easily obtained using
% <https://www.mathworks.com/help/matlab/ref/fileparts.html |FILEPARTS|>.
%
% Some |suffix| examples:
%
% * |'0'|
% * |'_1'|
% * |'(005)'|
% * |'.copy.100'|
% * |' 00001 backup'|
% * etc.
name = nextname('A','_1','.txt') % syntax 2
dlmwrite(name,0)
name = nextname('A','_1','.txt') % syntax 2
dlmwrite(name,0)
name = nextname('A','_1','.txt') % syntax 2
dlmwrite(name,0)
%% Folders Too
%
% |NEXTNAME| can also check and return folder names. For example:
subd = nextname('B_<0>') % syntax 1
mkdir(subd)
subd = nextname('B_<0>') % syntax 1
mkdir(subd);
subd = nextname('B_<0>') % syntax 1
mkdir(subd);
subd = nextname('B','_0','') % syntax 2
mkdir(subd);
subd = nextname('B','_0','') % syntax 2
mkdir(subd);
subd = nextname('B','_0','') % syntax 2
mkdir(subd);
%% Optional Input: Absolute/Relative Filepath
%
% An absolute/relative filepath may be included within |filename| (syntax
% 1) or within |basename| (syntax 2). Alternatively the |filepath| may be
% provided as the first input argument with either syntax 1 or syntax 2:
nextname(subd,'file(<1>).txt')     % syntax 1
nextname(subd,'file','(1)','.txt') % syntax 2
%% Optional Input: Include Path in the Output Name
%
% By default the output name includes the folder/filename only. Optional
% trailing input |withpath| specifies if the output should include the
% relative/absolute path as provided in |filename|, |basename|, or |filepath|. 
% Note that |NEXTNAME| does not fully qualify or expand the path.
nextname(subd,'file(<1>).txt',true)     % syntax 1
nextname(subd,'file','(1)','.txt',true) % syntax 2
%% Output 2: Integer Number
%
% The 2nd output gives the integer number used by the returned name:
[name,val] = nextname('A_<1>.txt')
%% Output 3: Array of Folder Names
%
% The 3rd output gives the path as an array of folder names
% (note that the path is not expanded or qualified in any way):
[name,~,fpa] = nextname(subd,'file(<1>).txt')
%% Integer Start Value
%
% The |suffix| or |filename| must contain one integer number which
% specifies the start value for incrementing from. The number must be an
% integer (zero or greater). |NEXTNAME| will find the next unused file
% (or folder) name, starting from the provided value. For example:
name = nextname('A_<100>.txt') % start from one hundred.
dlmwrite(name,0)
name = nextname('A_<100>.txt')
dlmwrite(name,0)
name = nextname('A_<0>.txt') % start from zero.
dlmwrite(name,0)
name = nextname('A_<0>.txt')
dlmwrite(name,0)
%% Integer Leading Zeros
%
% By default the output number has no leading zeros, which means the
% output filename changes length depending on the number of digits in the
% output number. Fixed-width names can be specified using the integer:
% the number used in the output name is zero-padded to ensure that
% it has the same (minimum) width as the provided integer has. Leading
% zeros can be included in the integer number to achieve this length.
%
% Note that |NEXTNAME| compares the number values (not literal strings),
% which ensures that all file/folder names have unique number values, i.e.
% this means that |'A_01.txt'| will not be returned if the filenames
% |'A_1.txt'| or |'A_001.txt'| or |'A_0001.txt'| etc. already exist.
%
% For example, starting from one (with minimum four digits):
name = nextname('A_<0001>.txt')
dlmwrite(name,0)
name = nextname('A_<0001>.txt')
dlmwrite(name,0)
%% Using |FILEPARTS|' Outputs
%
% The recommended approach to calling |NEXTNAME| using the outputs from
% <https://www.mathworks.com/help/matlab/ref/fileparts.html |FILEPARTS|>:
given = 'A.txt';
[P,N,X] = fileparts(given);
name = nextname(P,N,'_1',X,true)
dlmwrite(name,0)
%% Natural Sort Order with |NATSORTFILES|
%
% Once files are saved in a directory the order in which the names are
% returned by the OS/filesystem may not be the same as the number order.
% An easy way to sort filenames or directory names into
% <https://en.wikipedia.org/wiki/Natural_sort_order _natural sort order_>
% is to download my FEX submission
% <https://www.mathworks.com/matlabcentral/fileexchange/47434 |NATSORTFILES|>:
S = dir('A_*.txt'); % OS order
display({S.name}.')
S = natsortfiles(S); % natural sort order
display({S.name}.')