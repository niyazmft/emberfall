#!/usr/bin/env python3
import time
import random
from ai_pathfinding import a_star_path, debug_grid_overlay

def run_benchmark(width=12, height=12, num_runs=1000):
    blocked = set()
    # Add some random obstacles (20% of the grid)
    for _ in range(int(width * height * 0.2)):
        blocked.add((random.randint(0, width - 1), random.randint(0, height - 1)))

    # Elevations
    elevations = {}
    for x in range(width):
        for y in range(height):
            elevations[(x, y)] = random.randint(0, 2)

    times = []

    # We want to measure the performance of individual pathfinding calls
    for _ in range(num_runs):
        # Pick start and goal that are not blocked
        while True:
            start = (random.randint(0, width - 1), random.randint(0, height - 1))
            if start not in blocked:
                break
        while True:
            goal = (random.randint(0, width - 1), random.randint(0, height - 1))
            if goal not in blocked:
                break

        t0 = time.perf_counter()
        a_star_path(start, goal, blocked, width, height, elevations)
        t1 = time.perf_counter()
        times.append((t1 - t0) * 1000) # ms

    avg_time = sum(times) / len(times)
    max_time = max(times)
    print(f"Benchmark (12x12 grid, {num_runs} runs):")
    print(f"  Average time: {avg_time:.4f} ms")
    print(f"  Worst-case time: {max_time:.4f} ms")

def worst_case_benchmark(width=12, height=12):
    # A "snake" or "maze" that forces the A* to explore most of the grid
    blocked = set()
    for y in range(1, height, 2):
        if (y // 2) % 2 == 0:
            # Wall with gap at the end
            for x in range(width - 1):
                blocked.add((x, y))
        else:
            # Wall with gap at the beginning
            for x in range(1, width):
                blocked.add((x, y))

    start = (0, 0)
    goal = (0, height - 1) if (height - 1) % 4 == 0 else (width - 1, height - 1)

    # Adjust goal to be reachable and not blocked
    if goal in blocked:
        goal = (0, height - 1)

    print("Maze layout:")
    print(debug_grid_overlay(width, height, blocked, start=start, goal=goal))

    num_runs = 100
    times = []
    path = None
    for _ in range(num_runs):
        t0 = time.perf_counter()
        path = a_star_path(start, goal, blocked, width, height)
        t1 = time.perf_counter()
        times.append((t1 - t0) * 1000)

    avg_time = sum(times) / len(times)
    max_time = max(times)
    print(f"Worst-case Maze Benchmark (12x12 grid, {num_runs} runs):")
    print(f"  Average time: {avg_time:.4f} ms")
    print(f"  Worst-case time: {max_time:.4f} ms")
    if path:
        print(f"  Path length: {len(path)}")
    else:
        print("  No path found")

if __name__ == "__main__":
    random.seed(42)
    run_benchmark()
    worst_case_benchmark()
