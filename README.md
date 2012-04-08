Othello
=======

This is a simple implementation of the Minimax algorithm for othello/reversi. Is my first "real" code after a few days attempting learn Haskell, so it might not be very idiomatic, elegant or readable.

Why?
----

Why not? Othello is a nice game to play, that requires no graphics and the Minimax algorithm can be implemented fairly easily. I had written it once before in C (and failed horribly in Visual Basic), so I knew what I was in for. It is complex enough to be more than a small excercise. Plus, I get to brag about how 1337  I am implementing AI in Haskell. I could find only one other implementation when I wrote this, and it was written in a kind-of-imerative style.

How?
----

To play, just enter the X/Y coordinate as a tuple, ie. (4,2). You play as "O".

The basic datastructure is a map of an Int,Int tuple to a Piece data. This let me use an immutable datastructure, and still referr to the pieces in a simple x/y coordinate system.

The heuristics are pretty simple. The Minimax algorithm is set up to optimize for advantage in the number of pieces but most importantly, *the number of possible moves*. This ensure the AI will dominate the match, leaving you no room to make any smart moves for yourself. I'm not a terrible othello player, but I had a hard time beating the AI.

TODO
----

* Update to be more idiomatic Haskell. I had some code review from a Haskell hacker friend, but I'll need some more Haskell time to "get" some of the pointfree style and evaluate what I like.

* Implement alpha/beta pruning. This should be simple, but I've vever actually done it.

* Parallellize? I have two cores and multithreading. This should be the ideal algorithm to split over a number of threads. We'll see as soon as I get the urge to Haskell.