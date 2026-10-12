"""Replay generated provenance and solutions; reject invalid seed artifacts."""
import json
import sys
import chess

items = json.load(open(sys.argv[1]))
assert items
seen = set()
for item in items:
    assert item['fingerprint'] not in seen
    seen.add(item['fingerprint'])
    board = chess.Board()
    for uci in item['source_moves']:
        move = chess.Move.from_uci(uci)
        assert move in board.legal_moves
        board.push(move)
    assert board.fen() == item['fen']
    solver = board.turn
    assert len(item['solution']) == len(item['positions'])
    assert len(item['solution']) % 2 == 1
    for uci, fen in zip(item['solution'], item['positions']):
        move = chess.Move.from_uci(uci)
        assert move in board.legal_moves
        board.push(move)
        assert board.fen() == fen
    assert board.is_checkmate() and board.turn != solver
print(f'{len(items)} unique legal self-play positions and complete mating solutions verified.')
