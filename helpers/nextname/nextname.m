function [name,val,fpa,dbg] = nextname(varargin)
% Return the next unused filename, incrementing an integer as required.
%
% (c) 2017-2026 Stephen Cobeldick
%
%%% Syntax %%%
%
%   name = nextname(filename)                     % syntax 1
%   name = nextname(basename,suffix,extension)    % syntax 2
%   name = nextname(filepath,...)
%   name = nextname(...,withpath)
%   [name,val,fpa] = nextname(...)
%
% NEXTNAME increments an integer value in either <filename> or <suffix>
% such that the returned <name> is currently unused by any file/folder.
% If the files/folders are not in the current directory then <filename>,
% <basename>, or <filepath> must specify the relative/absolute path.
%
% NEXTNAME supports two different calling syntaxes:
% 1) the complete name is provided in <filename>. The integer to increment
%    is enclosed in angle brackets, e.g. "<001>data.txt" or "test<1>.txt".
% 2) the <basename>, <suffix>, and <extension> are provided as separate
%    inputs: this syntax is convenient when using the outputs from
%    FILEPARTS as inputs to NEXTNAME. The <basename> is treated as literal
%    text. The <suffix> must contain exactly one integer value, e.g. "0",
%    "_1", "(001)", "99", etc. The file <extension> is treated as literal
%    text: for folders (or for files that do not require an extension)
%    specify the <extension> as empty text, i.e. '' or "".
%
% Padding the integer with leading zeros indicates the (minimum) required
% number of digits, thus allowing for the creation of fixed-width names.
%
% Duplicate number values will not be returned, regardless of any leading
% zeros in the existing file/folder names or in the provided integer. This
% is due to NEXTNAME comparing the number values (and not the raw text).
%
%% Examples %%
%
% The current directory contains files 'A1.txt', 'A2.txt', and 'A4.txt':
%
%   >> nextname("A<1>.txt")                 % syntax 1
%   ans = "A3.txt"
%   >> nextname("A","1",".txt")             % syntax 2
%   ans = "A3.txt"
%
%   >> nextname("A<001>.txt")               % syntax 1
%   ans = "A003.txt"
%   >> nextname("A","001",".txt")           % syntax 2
%   ans = "A003.txt"
%
% Directory 'test' contains subdirectories 'B(1)', 'B(2)', and 'B(4)':
%
%   >> nextname('test/B(<1>)')              % syntax 1
%   ans = 'B(3)'
%   >> nextname('test/B','(1)','')          % syntax 2
%   ans = 'B(3)'
%   >> nextname('test','B(<1>)')            % syntax 1
%   ans = 'B(3)'
%   >> nextname('test','B','(1)','')        % syntax 2
%   ans = 'B(3)'
%
%   >> nextname('test','B(<1>)',true)       % syntax 1
%   ans = 'test/B(3)'
%   >> nextname('test','B','(1)','',true)   % syntax 2
%   ans = 'test/B(3)'
%
%% Input Arguments (**==default) %%
%
%   filename  = CharRowVector or StringScalar, a folder or filename with
%               file extension and absolute/relative path if required. Must
%               include one integer in angle brackets, e.g. "test<1>.txt".
%   filepath  = CharRowVector or StringScalar, the absolute/relative path
%               of <basename>/<filename>. The text is interpreted literally.
%   basename  = CharRowVector or StringScalar, a folder or filename without
%               the file extension. The text is interpreted literally.
%   suffix    = CharRowVector or StringScalar, to append onto the <basename>.
%               Contains exactly one integer number, other letters optional.
%   extension = CharRowVector or StringScalar, the <basename> file-extension.
%               For folders (or files without extensions) use '' or "".
%   withpath  = LogicalScalar, true/false** -> output <name> includes the
%               absolute/relative path provided in <filename> or <filepath>.
%
%% Output Arguments %%
%
%   name = A currently unused file/folder name. Note that <name> is string
%          if any input is string, otherwise it is a character vector.
%   val  = UINT64 Scalar, the integer value used in the returned <name>.
%   fpa  = The path split into an array of separate folder names. Is string
%          if <name> is a string, otherwise it is a cell array of char vectors.
%
%% Dependencies %%
%
%% * MATLAB R2009b or later.
%
% See also DIR EXIST FILEPARTS FULLFILE MKDIR FOPEN FCLOSE FPRINTF SPRINTF
% ARBSORT NATSORT NATSORTFILES NATSORTROWS ISFILE ISFOLDER WHAT WHICH WHO
% READCELL WRITECELL READLINES WRITELINES READMATRIX WRITEMATRIX READVARS
% READTABLE WRITETABLE READTIMETABLE WRITETIMETABLE FILEREAD TEXTSCAN
tmv = tic();
arg = varargin;
iss = false;
% Release | Feature
% --------|--------
% R2007a  | regexptranslate
% R2007b  | regexp/regexpi: cell array of char, 'split' option
% R2008a  | assert: message-identifier
% R2008b  | tic/toc: timer id
% R2009b  | tilde output placeholder
% R2016b  | string class (not required for NEXTNAME to work)
%
%% Input Wrangling %%
%
assert(nargin>0,'SC:nextname:InputsTooFew', 'Not enough input arguments.')
assert(nargin<6,'SC:nextname:InputsTooMany','Too many input arguments.')
%
for k = 1:numel(arg)
	arr = arg{k};
	if isa(arr,'string') && isscalar(arr)
		iss = true;
		arg{k} = arr{1};
	end
end
%
tmp = arg{end};
if isequal(tmp,false)||isequal(tmp,true)
	assert(nargin>1,'SC:nextname:withpath:OnlyOneInput',...
		'The input <withpath> must be provided after one or more text inputs.')
	arg(end) = [];
	withpath = logical(tmp);
else
	withpath = false;
end
%
if ispc()
	psc = '[/\\]';
else % Mac & Linux
	psc = '/';
end
%
fmt = 'The %s input <%s> must be a string scalar or a character row vector.';
ord = {'1st','2nd','3rd','4th','5th'};
chk = @(a)ischar(a) && ((ndims(a)==2 && size(a,1)==1) || isequal(a,'')); %#ok<ISMAT>
%
N = numel(arg);
switch N
	case {1,2}
		assert(chk(arg{N}),'SC:nextname:filename:NotText',fmt,ord{N},'filename')
		assert(chk(arg{1}),'SC:nextname:filepath:NotText',fmt,ord{1},'filepath')
		spl = regexp(fullfile(arg{1:N}),psc,'split');
		[ind,ins] = regexp(spl{end},'<(\d+)>','tokens','split');
		assert(isscalar(ind),'SC:nextname:filename:NotSingleIntegerInAngleBrackets',...
			['The %s input <filename> must contain exactly one integer in angle brackets,',...
			' e.g. "test<01>.txt"\nNumber of integers found: %d\n'],ord{N},numel(ind))
		fpa = spl(1:end-1);
		rhs = ins{2};
		lhs = ins{1};
		dgt = ind{1}{:}; % digits only
	case {3,4}
		rhs = arg{N-0};
		sfx = arg{N-1};
		lhs = arg{N-2};
		assert(chk(rhs),'SC:nextname:extension:NotText',fmt,ord{N-0},'extension')
		assert(chk(sfx),'SC:nextname:suffix:NotText',   fmt,ord{N-1},'suffix')
		assert(chk(lhs),'SC:nextname:basename:NotText', fmt,ord{N-2},'basename')
		assert(chk(arg{1}),'SC:nextname:filepath:NotText',fmt,ord{1},'filepath')
		spl = regexp(fullfile(arg{1:N-2}),psc,'split');
		fpa = spl(1:end-1);
		lhs = spl{end};
		[ind,ins] = regexp(sfx,'\d+','match','split');
		assert(isscalar(ind),'SC:nextname:suffix:NotSingleInteger',...
			['The %s input <suffix> must contain exactly one integer,',...
			' e.g. "01"\nNumber of integers found: %d\n'],ord{N-1},numel(ind))
		lhs = [lhs,ins{1}];
		rhs = [ins{2},rhs];
		dgt = ind{:}; % digits only
	otherwise
		error('SC:nextname:InputsWrongType',...
			'Incorrect input types provided, please check the NEXTNAME help.')
end
%
wid = numel(dgt);
val = sscanf(dgt,'%lu');
%
%% Get Existing File/Folder Names %%
%
% Find files/subfolders on that path:
raw = dir(fullfile(fpa{:},[lhs,'*',rhs]));
%
% Generate regular expression:
rgx = ['^',regexptranslate('escape',lhs),'(\d+)',regexptranslate('escape',rhs),'$'];
%
% Extract numbers from names:
tkn = regexpi({raw.name},rgx,'tokens','once');
tkn = [tkn{:}];
%
%% Identify First Unused Name %%
%
if numel(tkn)
	% For speed these values must be converted before the WHILE loop:
	vec = sscanf(sprintf(' %s',tkn{:}),'%lu');  % faster than STR2DOUBLE.
	mxv = intmax('uint64');
	%
	% Find the first unused name, starting from the provided value:
	while any(val==vec) && val<mxv
		val = val+1;
	end
	%
	% Throw error if VAL reaches INTMAX... which is also in VEC:
	assert(~any(val==vec),...
		'SC:nextname:NoUnusedIntegerFound',...
		'No unused integer could be found.')
end
%
%% Generate Output Name Text %%
%
name = [lhs,sprintf('%0*u',wid,val),rhs];
%
if nargout>3
	dbg = struct('path',{fpa}, 'numbers',{tkn}, 'regexp',rgx, 'value',val,...
		'dir',raw, 'lhs',lhs, 'rhs',rhs, 'integer',dgt, 'seconds',toc(tmv));
end
%
if withpath
	name = fullfile(fpa{:},name);
end
%
if iss
	name = string(name);
	fpa  = string(fpa);
end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%nextname