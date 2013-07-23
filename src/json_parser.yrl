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
  true false null string number '{' '}' '[' ']' ':' ','.

Rootsymbol
  value.

value -> true    : true.
value -> false   : false.
value -> null    : nil.
value -> string  : parse_string('$1').
value -> number  : parse_number('$1').
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

-define(EXTENDED(First, Second),
  16#10000 + ((First band 16#07ff) * 16#400) + (Second band 16#03ff)).

% shit's slow yo
parse_string([$\\, $u, A1, B1, C1, D1, $\\, $u, A2, B2, C2, D2 | String])
    when (A1 == $d orelse A1 == $D) andalso (A2 == $d orelse A2 == $D) ->
  [?EXTENDED(list_to_integer([A1, B1, C1, D1], 16),
             list_to_integer([A2, B2, C2, D2], 16)) | parse_string(String)];
parse_string([$\\, $u, A, B, C, D | String]) ->
  [list_to_integer([A, B, C, D], 16) | parse_string(String)];
parse_string([$\\, $b | String]) ->
  [$\b | parse_string(String)];
parse_string([$\\, $f | String]) ->
  [$\f | parse_string(String)];
parse_string([$\\, $n | String]) ->
  [$\n | parse_string(String)];
parse_string([$\\, $r | String]) ->
  [$\r | parse_string(String)];
parse_string([$\\, $t | String]) ->
  [$\t | parse_string(String)];
parse_string([$\\, Char | String]) ->
  [Char | parse_string(String)];
parse_string([_]) ->
  [];
parse_string([A | String]) ->
  [A | parse_string(String)];

parse_string({ string, _, [$' | String] }) ->
  unicode:characters_to_binary(parse_string(String));
parse_string({ string, _, [$" | String] }) ->
  unicode:characters_to_binary(parse_string(String)).

parse_number({ number, _, Number }) ->
  case lists:member($., Number) of
    true  -> list_to_float(Number);
    false -> list_to_integer(Number)
  end.
