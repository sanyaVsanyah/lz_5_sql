import sqlite3
import random
import os
from datetime import datetime, timedelta
SHARD_SERVERS = {
    1:  "server_shard_01_january.db",
    2:  "server_shard_02_february.db",
    3:  "server_shard_03_march.db",
    4:  "server_shard_04_april.db",
    5:  "server_shard_05_may.db",
    6:  "server_shard_06_june.db",
    7:  "server_shard_07_july.db",
    8:  "server_shard_08_august.db",
    9:  "server_shard_09_september.db",
    10: "server_shard_10_october.db",
    11: "server_shard_11_november.db",
    12: "server_shard_12_december.db"
}
USERS = ['ivan', 'anna', 'petr', 'olga', 'maria', 'alex', 'dmitry', 'ekaterina', 'sergey', 'oleg']
ACTIONS = ['login', 'logout', 'view_page', 'edit_profile', 'create_order', 'cancel_order', 'upload_file', 'download_report', 'search', 'change_password']
RESULTS = ['success', 'failure', 'not_found', 'forbidden', 'timeout', 'partial_success']
START_DATE = datetime(2025, 1, 1)
TOTAL_DAYS = 364
print("Инициализация шардов...")
connections = {}
for shard_id, db_file in SHARD_SERVERS.items():
    if os.path.exists(db_file):
        os.remove(db_file)
        
    conn = sqlite3.connect(db_file)
    conn.execute("""
        CREATE TABLE User_Logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            user_action TEXT NOT NULL,
            action_date TEXT NOT NULL,
            action_time TEXT NOT NULL,
            action_result TEXT NOT NULL
        );
    """)
    conn.execute("PRAGMA synchronous = OFF;")
    conn.execute("PRAGMA journal_mode = MEMORY;")
    connections[shard_id] = conn
def get_shard_id(date_str):
    dt = datetime.strptime(date_str, "%Y-%m-%d")
    return dt.month
TARGET_ROWS = 1000000
BATCH_SIZE = 50000
rows_inserted = 0
print(f"Старт генерации {TARGET_ROWS} строк...")
while rows_inserted < TARGET_ROWS:
    current_batch_size = min(BATCH_SIZE, TARGET_ROWS - rows_inserted)
    shard_buckets = {m: [] for m in range(1, 13)}
    
    for _ in range(current_batch_size):
        rand_days = random.randint(0, TOTAL_DAYS)
        rand_date_obj = START_DATE + timedelta(days=rand_days)
        date_str = rand_date_obj.strftime("%Y-%m-%d")
        time_str = f"{random.randint(0,23):02d}:{random.randint(0,59):02d}:{random.randint(0,59):02d}"
        username = random.choice(USERS)
        action = random.choice(ACTIONS)
        result = random.choice(RESULTS)
        shard_id = get_shard_id(date_str)
        shard_buckets[shard_id].append((username, action, date_str, time_str, result))
        
    for shard_id, rows in shard_buckets.items():
        if rows:
            connections[shard_id].executemany("""
                INSERT INTO User_Logs (username, user_action, action_date, action_time, action_result)
                VALUES (?, ?, ?, ?, ?);
            """, rows)
            connections[shard_id].commit()
            
    rows_inserted += current_batch_size
    print(f"Записано строк: {rows_inserted}")
for conn in connections.values():
    conn.close()
print("Генерация завершена.")
print("\nСтатистика по шардам:")
for m in range(1, 13):
    db_file = f"server_shard_{m:02d}_" + [
        "january", "february", "march", "april", "may", "june", 
        "july", "august", "september", "october", "november", "december"
    ][m-1] + ".db"
    
    conn = sqlite3.connect(db_file)
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*), MIN(action_date), MAX(action_date) FROM User_Logs")
    count, min_date, max_date = cursor.fetchone()
    
    print(f"{db_file}: строк = {count}, диапазон = {min_date} - {max_date}")
    conn.close()