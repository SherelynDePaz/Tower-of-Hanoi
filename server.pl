% Tower of Hanoi backend (SWI-Prolog 9+)
% Run:  swipl server.pl      then open http://localhost:8080
%
% Pegs are numbered 0, 1, 2. A peg is a list of disk sizes, TOP FIRST.
% Size 1 is the smallest disk. Initial state for N=3: [[1,2,3],[],[]]

:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- use_module(library(http/http_parameters)).
:- use_module(library(lists)).

:- prolog_load_context(directory, Dir),
   asserta(user:file_search_path(app, Dir)).

:- http_handler(root(.),         http_reply_file(app('index.html'), []), []).
:- http_handler(root(api/solve), handle_solve, []).
:- http_handler(root(api/move),  handle_move,  []).

% ---------------------------------------------------------------
% Solver: the classic recursive definition, written as a DCG
% that collects move(Disk, From, To) terms.
% ---------------------------------------------------------------
hanoi(0, _, _, _) --> !, [].
hanoi(N, From, To, Via) -->
    { M is N - 1 },
    hanoi(M, From, Via, To),
    [move(N, From, To)],
    hanoi(M, Via, To, From).

solve(N, Moves) :- phrase(hanoi(N, 0, 2, 1), Moves).

move_dict(move(D, F, T), _{disk: D, from: F, to: T}).

handle_solve(Request) :-
    http_parameters(Request, [n(N, [integer, between(1, 10)])]),
    solve(N, Moves),
    maplist(move_dict, Moves, Dicts),
    length(Dicts, Count),
    reply_json_dict(_{n: N, count: Count, moves: Dicts}).

% ---------------------------------------------------------------
% Move validation for manual play.
% ---------------------------------------------------------------
handle_move(Request) :-
    http_read_json_dict(Request, Body),
    State = Body.state,
    From  = Body.from,
    To    = Body.to,
    (   illegal(State, From, To, Why)
    ->  reply_json_dict(_{ok: false, error: Why, state: State})
    ;   apply_move(State, From, To, New),
        (   solved(New) -> Solved = true ; Solved = false ),
        reply_json_dict(_{ok: true, state: New, solved: Solved})
    ).

illegal(_, F, T, 'Pick two different pegs.') :- F == T, !.
illegal(S, F, _, 'That peg has no disks.')   :- nth0(F, S, []), !.
illegal(S, F, T, 'A larger disk cannot sit on a smaller one.') :-
    nth0(F, S, [D|_]),
    nth0(T, S, [Top|_]),
    D > Top.

apply_move(S, F, T, S2) :-
    nth0(F, S, [D|Rest]),
    nth0(T, S, Dest),
    set_nth(S,  F, Rest,     S1),
    set_nth(S1, T, [D|Dest], S2).

set_nth(L, I, E, L2) :- nth0(I, L, _, R), nth0(I, L2, E, R).

solved([[], [], _]).

% ---------------------------------------------------------------
% Start the server
% ---------------------------------------------------------------
:- initialization(main, main).

main :-
    Port = 8080,
    http_server(http_dispatch, [port(Port)]),
    format("Tower of Hanoi running at http://localhost:~w~n", [Port]),
    thread_get_message(_).   % keep the process alive
