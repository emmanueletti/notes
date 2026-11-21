# Mars rover / robot grid

Called "the most common rover question". It's the classic Shopify pair programming prompt.

## Prompt

A plateau is a grid. The input's first line is the top-right corner, `5 5`, and the bottom-left is `0 0`. Each rover gets two lines:

```
1 2 N
LMLMLMLMM
```

The position is x, y, and a heading (N, E, S, W). The commands are:
- `L` / `R`: turn 90 degrees without moving
- `M`: move one cell forward

Rovers run one after another. Print each final position: `1 3 N`.

Classic test: `5 5`, then `1 2 N` with `LMLMLMLMM`, which gives `1 3 N`. Then `3 3 E` with `MMRMMRMRRM`, which gives `5 1 E`.

## Follow-ups they add

1. Rovers can't leave the grid. Ask whether a move off the edge should be ignored, stop the rover, or raise an error.
2. Obstacles on some cells.
3. Rovers block each other. A rover can't move into a cell another rover holds.
4. A new command, such as `B` for backward. If your design is good, this is one line.
5. Wrapping edges (the grid is a sphere), or a configurable map loaded from a file.
6. Multiple robots running at the same time, turn by turn, instead of one after another.

## Core idea

There's no algorithm here. It's all design. Keep each kind of change in its own place:

- `Heading`: knows its left, its right, and its step vector (N is 0, +1). Use a lookup table, not a big case statement.
- `Position`: x, y. `Position#+(vector)`.
- `Rover`: position and heading. `turn_left`, `turn_right`, `forward_position`. It doesn't know about the grid.
- `Grid`: size, obstacles, and occupied cells. `allowed?(position)`. Every new movement rule goes here.
- `Mission`/`Controller`: runs commands, asks the grid before each move, and decides what happens on a blocked move.
- `Parser`: text in, domain objects out. Handles invalid lines.

## Senior talking points

- Ask about invalid input: unknown commands, a rover starting off the grid or on an obstacle.
- Make the result of a blocked move clear: return a status or record "stopped at 2 3 N, blocked at 2 4".
- Map commands to methods in a hash (`{"L" => :turn_left, ...}`) so adding a command means adding one entry.
- Use value objects (`Data.define`) so equality works in tests and nothing gets mutated by accident.
- When they ask for running at the same time, talk about turn order and fairness before writing any code.

## Test cases

- The two classic rovers
- Moving off the edge, with the behavior you agreed on
- An obstacle directly ahead
- Two rovers where the second is blocked by the first
- An unknown command gives a clear error
