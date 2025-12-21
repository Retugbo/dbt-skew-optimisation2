import csv
import random
from datetime import date, timedelta
from pathlib import Path

random.seed(42)

ROOT = Path(__file__).resolve().parents[1]
SEEDS = ROOT / "seeds"
SEEDS.mkdir(parents=True, exist_ok=True)

# Option B sizes
NON_SKEWED_ROWS = 5000
SKEWED_ROWS = 50000
DAYS = 30
LOCATIONS = 200

start_date = date(2024, 1, 1)
dates = [(start_date + timedelta(days=i)).isoformat() for i in range(DAYS)]

# Non-skewed data
non_skewed_path = SEEDS / "movement_non_skewed.csv"
with non_skewed_path.open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["location_id", "activity_date", "revenue_amount"])
    for _ in range(NON_SKEWED_ROWS):
        loc = f"L{random.randint(1, LOCATIONS):03d}"
        d = random.choice(dates)
        rev = round(random.uniform(5, 250), 2)
        w.writerow([loc, d, rev])

# Skewed data (hot key)
skewed_path = SEEDS / "movement_skewed.csv"
with skewed_path.open("w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["location_id", "activity_date", "revenue_amount"])
    for _ in range(SKEWED_ROWS):
        d = random.choice(dates)
        rev = round(random.uniform(5, 250), 2)
        w.writerow(["SK1", d, rev])

print("Wrote seeds:")
print(f"- {non_skewed_path} rows={NON_SKEWED_ROWS}")
print(f"- {skewed_path} rows={SKEWED_ROWS}")
