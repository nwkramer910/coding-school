import pandas as pd
from datetime import datetime

# Read your data
df = pd.read_excel('/mnt/user-data/uploads/Book1.xlsx', sheet_name=0)

# Normalize Direction
df['Direction'] = df['Direction'].str.capitalize()

# Create flag columns (0 for blank/NaN, 1 for present)
df['ToOrFromIran'] = df['To or From Iran'].fillna(0).astype(int)
df['IranAffiliated'] = df['Somehow Iran Affiliated'].fillna(0).astype(int)

# Extract date only (no time)
df['DateOnly'] = df['Date Local'].dt.date

# Build the pivot: rows=dates, columns=combinations of Type+Direction+Iran flags
pivot = df.groupby([
    'DateOnly',
    'Type',
    'Direction',
    'ToOrFromIran',
    'IranAffiliated'
]).size().reset_index(name='Count')

# Pivot wider: dates in rows, everything else in column names
pivot_wide = pivot.pivot_table(
    index='DateOnly',
    columns=['Type', 'Direction', 'ToOrFromIran', 'IranAffiliated'],
    values='Count',
    fill_value=0
)

# Flatten column names to something readable
pivot_wide.columns = [
    f"{t}_{d}_{('ToIran' if ti else 'NotToIran')}_{('AffIran' if ai else 'NotAff')}"
    for t, d, ti, ai in pivot_wide.columns
]

# Sort columns logically
col_order = []
for t in ['Cargo', 'Tanker']:
    for d in ['Entering', 'Exiting']:
        for ti in [1, 0]:
            for ai in [1, 0]:
                col_name = f"{t}_{d}_{('ToIran' if ti else 'NotToIran')}_{('AffIran' if ai else 'NotAff')}"
                if col_name in pivot_wide.columns:
                    col_order.append(col_name)

pivot_wide = pivot_wide[col_order]

# Reset index to make date a column
pivot_wide = pivot_wide.reset_index()
pivot_wide.rename(columns={'DateOnly': 'Date'}, inplace=True)

# Write to Excel
output_path = '/mnt/user-data/outputs/Maritime_Pivot_Summary.xlsx'
pivot_wide.to_excel(output_path, index=False, sheet_name='Pivot')

print("✓ Pivot table created successfully!")
print(f"\nOutput: Maritime_Pivot_Summary.xlsx")
print(f"\nShape: {pivot_wide.shape[0]} dates × {pivot_wide.shape[1]-1} column combinations")
print(f"\nDate range: {pivot_wide['Date'].min()} to {pivot_wide['Date'].max()}")
print(f"\nFirst few rows:")
print(pivot_wide.head(10).to_string())
print(f"\nColumn totals (vessels by combination):")
print(pivot_wide.iloc[:, 1:].sum(axis=0).to_string())
print(f"\nGrand total: {pivot_wide.iloc[:, 1:].sum().sum()} vessels")