%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
%                  Version 2, December 2004
%
%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
% TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
%
% 0. You just DO WHAT THE FUCK YOU WANT TO.

Definitions.

WS = [\t\s]
N  = [0-9]
S  = [+\-]

Rules.

{WS}+ : skip_token.

{S}?{N}+(\.{N}+([eE]{S}?{N}+)?)? : { token, { number, TokenLine, TokenChars } }.

"(\\.|[^"])*" : { token, { string, TokenLine, TokenChars } }.
'(\\.|[^'])*' : { token, { string, TokenLine, TokenChars } }.

\{ : { token, { '{', TokenLine } }.
\} : { token, { '}', TokenLine } }.

\[ : { token, { '[', TokenLine } }.
\] : { token, { ']', TokenLine } }.

\: : { token, { ':', TokenLine } }.
\, : { token, { ',', TokenLine } }.

true  : { token, { true, TokenLine } }.
false : { token, { false, TokenLine } }.
null  : { token, { null, TokenLine } }.

Erlang code.
