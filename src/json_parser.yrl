%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
%                  Version 2, December 2004
%
%          DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
% TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
%
% 0. You just DO WHAT THE FUCK YOU WANT TO.

Nonterminals
  value object array members pair elements.

Terminals
  boolean null string number '{' '}' '[' ']' ':' ','.

Rootsymbol
  value.

value -> boolean : element(3, '$1').
value -> null    : nil.
value -> string  : parse_string('$1').
value -> number  : element(3, '$1').
value -> object  : '$1'.
value -> array   : '$1'.

object -> '{' '}'         : [].
object -> '{' members '}' : '$2'.

members -> pair : ['$1'].
members -> pair ',' members : ['$1' | '$3'].

pair -> string ':' value : { parse_string('$1'), '$3' }.

array -> '[' ']' : [].
array -> '[' elements ']' : '$2'.

elements -> value : ['$1'].
elements -> value ',' elements : ['$1' | '$3'].

Erlang code.

parse_string({ string, _, String }) ->
  list_to_binary(String).
