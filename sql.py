import sqlite3
import math

# Establish a connection to the SQLite database
conn = sqlite3.connect('./StarryNight/Sources/Resources/stars.sqlite3')

# Create a cursor object
cursor = conn.cursor()

cursor.execute('''
    CREATE TABLE star_angles (
        star1_hr INTEGER,
        star2_hr INTEGER,
        angle REAL,
        PRIMARY KEY(star1_hr, star2_hr)
    )
''')

# Execute a SQL statement to fetch the cosine_distance from the StarCatalog table
cursor.execute('''
    SELECT
        A.hr as star1_hr,
        B.hr as star2_hr,
        A.x/A.dist * B.x/B.dist + A.y/A.dist * B.y/B.dist + A.z/A.dist * B.z/B.dist as dot_prod
    FROM stars_7 A, stars_7 B
    WHERE
        A.hr < B.hr
        AND A.hr != ""
        AND B.hr != ""
        AND A.x IS NOT NULL
        AND B.x IS NOT NULL
        AND A.y IS NOT NULL
        AND B.y IS NOT NULL
        AND A.z IS NOT NULL
        AND B.z IS NOT NULL
        AND A.dist != 0
        AND B.dist != 0
        AND A.mag < 4
        AND B.mag < 4
''')

# Fetch all rows as a list of tuples
rows = cursor.fetchall()

# Iterate over the rows and compute arccos of cosine_distance, then compute pi/2 - arccos
for row in rows:
    (star1_hr, star2_hr, dot_prod) = row
    if dot_prod > 1.0:
        assert dot_prod < 1.001  # anything higher means this is not a valid result
        dot_prod = 1.0
    elif dot_prod < -1.0:
        assert dot_prod > -1.001  # see above
        dot_prod = -1.0
    theta = math.acos(dot_prod)
    conn.execute('''
        INSERT INTO star_angles (star1_hr, star2_hr, angle)
        VALUES (?, ?, ?)
    ''', (star1_hr, star2_hr, theta))

conn.execute('''
    CREATE INDEX angle_index ON star_angles(angle);
''')

# Close the connection to the database
conn.commit()
conn.close()

