:- use_module(library(lists)).

% ---- solver ----
hanoi(0, _, _, _, []) :- !.
hanoi(N, From, To, Via, Moves) :-
    N > 0,
    M is N - 1,
    hanoi(M, From, Via, To, Before),
    hanoi(M, Via, To, From, After),
    append(Before, [move(N, From, To)|After], Moves).

% solve(N, Flat): Flat = [Disk,From,To, Disk,From,To, ...]
solve(N, Flat) :- hanoi(N, 0, 2, 1, Moves), flatten_moves(Moves, Flat).

flatten_moves([], []).
flatten_moves([move(D, F, T)|R], [D, F, T|X]) :- flatten_moves(R, X).

% ---- move checking ----
% State is a list of 3 pegs, each a list of disk sizes (top first).
step(S, F, T, Result) :-
    (   F =:= T
    ->  Result = err('Pick two different pegs.')
    ;   peg(S, F, [])
    ->  Result = err('That peg has no disks.')
    ;   peg(S, F, [D|_]), peg(S, T, [Top|_]), D > Top
    ->  Result = err('A larger disk cannot sit on a smaller one.')
    ;   apply_move(S, F, T, New),
        (   New = [[], [], _] -> Solved = true ; Solved = false ),
        Result = ok(New, Solved)
    ).

apply_move(S, F, T, New) :-
    peg(S, F, [D|Rest]),
    set_peg(S, F, Rest, S1),
    peg(S1, T, Dest),
    set_peg(S1, T, [D|Dest], New).

peg([P|_], 0, P) :- !.
peg([_|R], I, P) :- I > 0, J is I - 1, peg(R, J, P).

set_peg([_|R], 0, E, [E|R]) :- !.
set_peg([P|R], I, E, [P|R2]) :- I > 0, J is I - 1, set_peg(R, J, E, R2).
