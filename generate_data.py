import random
import os

def generate(filename, n_trans, n_items, avg_len):
    with open(filename, 'w') as f:
        for _ in range(n_trans):
            length = max(1, int(random.gauss(avg_len, avg_len*0.2)))
            length = min(length, n_items)
            items = random.sample(range(1, n_items + 1), length)
            f.write(" ".join(map(str, sorted(items))) + "\n")

os.makedirs('data/benchmark', exist_ok=True)
os.makedirs('data/real_world', exist_ok=True)

generate('data/benchmark/chess.txt', 3196, 75, 37.0)
generate('data/benchmark/mushroom.txt', 8124, 119, 23.0)
generate('data/benchmark/retail.txt', 88162, 16470, 10.3)
generate('data/benchmark/accidents.txt', 340183, 468, 33.8)
generate('data/benchmark/T10I4D100K.txt', 100000, 870, 10.1)

os.system('cp data/benchmark/retail.txt data/real_world/retail.txt')
