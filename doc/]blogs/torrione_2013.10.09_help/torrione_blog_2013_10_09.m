%% Dude, Where's My Help?  (Or, MATLAB Freezing During Startup)
% Depending on your setup, you may have recently had one of the following
% happen:
%
% 1) If you pulled the most recent version of the PRT since October 9,
% 2013, the PRT no longer shows up in the builtin MATLAB help-browser 
% 
% or:
%
% 2) If you updated to MATLAB 2013B, MATLAB freezes during startup.
%
% Here's the skinny - there's a bug in the new version of MATLAB (2013B)
% that, according to TMW:
%
%%%%%%%%%%%%%
% This is a known issue with MATLAB 8.2 (R2013b) in the way that the
% MATLAB startup handles the info.xml file. There is a deadlock between
% the Help System initialization and the path changes (raised by the
% startup.m) at the start of MATLAB. 
%%%%%%%%%%%%%

% Copyright (c) 2014 CoVar Applied Technologies
%
% Permission is hereby granted, free of charge, to any person obtaining a
% copy of this software and associated documentation files (the
% "Software"), to deal in the Software without restriction, including
% without limitation the rights to use, copy, modify, merge, publish,
% distribute, sublicense, and/or sell copies of the Software, and to permit
% persons to whom the Software is furnished to do so, subject to the
% following conditions:
%
% The above copyright notice and this permission notice shall be included
% in all copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
% OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
% NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
% OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
% USE OR OTHER DEALINGS IN THE SOFTWARE.


%%
% The result of this bug is that MATLAB seems to start up fine, but then
% just sits there, and never accepts inputs.  This is pretty much as bad a
% bug as can be (besides wrong answers), since it makes MATLAB completely
% unusable, and you can't even easily determine what is causing it since...
% MATLAB is unusable.
%
% There is a patch to fix this bug, but if you don't have the patch
% already installed it's *very* difficult to figure out what is going wrong
% and it can be very frustrating.  Alternatively, removing (or moving) the
% XML files will let MATLAB startup, but the automatic help search, prtDoc,
% etc. will no longer work.  We thought that moving the XML files would
% cause the least amount of pain overall, so that's what we did.  Our XML
% files that used to live in prtRoot now live in fullfile(prtRoot,']xml')
% which is by default *not* on the prtPath, so should not cause you any
% issues.
%
% If you still want to use the PRT documentation in the MATLAB help
% browser, simply install the patch by following the instructions below,
% then move the .xml files from fullfile(prtRoot,']xml') to prtRoot.  That
% should get everything running!
%
% Sorry about any headaches anyone encountered, and a big "thank you" to 
% Cesar from TMW who helped us get to the bottom of this quickly and
% professionally.

%% Patch Installation Instructions from Cesar
%
%%%%%%%%%%%%%
% To work around this issue, unzip the attached patch (link) into your
% MATLAB root directory (most likely C:\Program Files\MATLAB\R2013b).
%%%%%%%%%%%%%
