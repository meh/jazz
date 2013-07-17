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

{S}?{N}+(\.{N}+([eE]{S}?{N}+)?)? : { token, { number, TokenLine, lex_number(TokenChars) } }.

"(\\.|[^"])*" : { token, { string, TokenLine, lex_string(TokenChars) } }.
'(\\.|[^'])*' : { token, { string, TokenLine, lex_string(TokenChars) } }.

\{ : { token, { '{', TokenLine } }.
\} : { token, { '}', TokenLine } }.

\[ : { token, { '[', TokenLine } }.
\] : { token, { ']', TokenLine } }.

\: : { token, { ':', TokenLine } }.
\, : { token, { ',', TokenLine } }.

true  : { token, { boolean, TokenLine, true } }.
false : { token, { boolean, TokenLine, false } }.
null  : { token, { null, TokenLine } }.

Erlang code.

lex_string(String) ->
  lists:reverse(tl(lists:reverse(tl(String)))).

lex_number(Number) ->
  case lists:member($., Number) of
    true  -> list_to_float(Number);
    false -> list_to_integer(Number)
  end.
