"""Generate unique forced-mate puzzles from legal engine self-play; no puzzle dataset.

Output is an SQL seed for the Supabase SQL editor. Stockfish stays on the worker.
"""
import argparse
import hashlib
import json
import random
from pathlib import Path

import chess
import chess.engine


def forced_line(engine, original, depth):
    board = original.copy()
    solver = board.turn
    moves, positions = [], []
    # Only accept short forced mates with a unique mating move at EVERY solver turn.
    for _ in range(7):
        if board.is_checkmate():
            return (moves, positions) if board.turn != solver else None
        if board.is_game_over():
            return None
        lines = engine.analyse(board, chess.engine.Limit(depth=depth), multipv=2)
        if not lines or not lines[0].get('pv'):
            return None
        if board.turn == solver:
            score = lines[0]['score'].pov(solver)
            mate = score.mate()
            if mate is None or not 0 < mate <= 3:
                return None
            if len(lines) > 1:
                second = lines[1]['score'].pov(solver).mate()
                if second is not None and second > 0:  # Reject alternative forced mates.
                    return None
        move = lines[0]['pv'][0]
        if move not in board.legal_moves:
            return None
        moves.append(move.uci())
        board.push(move)
        positions.append(board.fen())
    return None


def literal(value):
    return "'" + str(value).replace("'", "''") + "'"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--engine', required=True)
    parser.add_argument('--output', required=True)
    parser.add_argument('--count', type=int, default=30)
    parser.add_argument('--games', type=int, default=100)
    parser.add_argument('--depth', type=int, default=16)
    parser.add_argument('--seed', type=int, default=42)
    args = parser.parse_args()
    rng = random.Random(args.seed)
    puzzles = {}
    with chess.engine.SimpleEngine.popen_uci(args.engine) as engine:
        engine.configure({'Threads': 1, 'Hash': 128})
        for game_index in range(args.games):
            board = chess.Board()
            for ply in range(160):
                if board.is_game_over(claim_draw=True):
                    break
                lines = engine.analyse(board, chess.engine.Limit(depth=7), multipv=3)
                top = lines[0]['score'].pov(board.turn).mate()
                if ply > 8 and top is not None and 0 < top <= 3:
                    first = forced_line(engine, board, args.depth)
                    # Deeper independent verification must keep the same solution.
                    verified = forced_line(engine, board, args.depth + 2) if first else None
                    if verified and verified[0] == first[0]:
                        key = hashlib.sha256(' '.join(board.fen().split()[:4]).encode()).hexdigest()
                        moves, positions = verified
                        turns = (len(moves) + 1) // 2
                        puzzles[key] = dict(fingerprint=key, fen=board.fen(), solution=moves,
                            positions=positions, rating=600 + turns * 300,
                            expected_seconds=20 + turns * 25, theme=f'mate_in_{turns}',
                            source_moves=[m.uci() for m in board.move_stack],
                            engine=engine.id['name'], verification_depth=args.depth+2)
                        print(f'Validated {len(puzzles)}/{args.count}', flush=True)
                        break
                # Different-strength play: mostly best moves, occasionally plausible mistakes.
                selected = rng.choices(lines, weights=[7, 2, 1][:len(lines)])[0]
                move = selected['pv'][0]
                if ply > 12 and rng.random() < 0.1:
                    move = rng.choice(list(board.legal_moves))
                board.push(move)
            if len(puzzles) >= args.count:
                break
            print(f'Game {game_index + 1} completed', flush=True)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    statements = ['-- Automatically generated and depth-verified Stockfish self-play puzzles.']
    for p in puzzles.values():
        array = lambda xs: 'ARRAY[' + ','.join(literal(x) for x in xs) + ']'
        statements.append('insert into public.puzzles (fingerprint,fen,solution,positions,rating,expected_seconds,theme) values (' +
            ','.join([literal(p['fingerprint']),literal(p['fen']),array(p['solution']),array(p['positions']),
                str(p['rating']),str(p['expected_seconds']),literal(p['theme'])]) + ') on conflict (fingerprint) do nothing;')
    output.write_text('\n'.join(statements) + '\n')
    output.with_suffix('.json').write_text(json.dumps(list(puzzles.values()), indent=2))
    print(f'Saved {len(puzzles)} puzzles to {output}. Ratings are provisional.')
    if not puzzles:
        raise SystemExit('No verified candidates; increase --games or change --seed.')


if __name__ == '__main__':
    main()
