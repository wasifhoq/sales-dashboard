"""Converts the raw Kaggle CSV (Windows-1252 encoding) into a clean UTF-8 CSV.
"""

raw_path = "data/superstore_sample.csv"
clean_path = "data/superstore_clean.csv"

with open(raw_path, encoding="cp1252", newline="") as f:
    text = f.read().replace("\xa0", " ")

with open(clean_path, "w", encoding="utf-8", newline="") as f:
    f.write(text)

print("OK")