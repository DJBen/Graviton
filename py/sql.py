"""
Created a table `star_angles` in the sqlite3 database with the pairwise angles between stars.
"""

import math
import pathlib
import sqlite3

import numpy as np

CURRENT_DIR = pathlib.Path(__file__).parent


def create_star_angle_table():
    conn = sqlite3.connect(CURRENT_DIR / "../StarryNight/Sources/Resources/stars.sqlite3")
    cursor = conn.cursor()

    # Helpful if you want to delete the existing table.
    # cursor.execute("DROP TABLE star_angles;")

    cursor.execute("""
        CREATE TABLE star_angles (
            star1_hr INTEGER,
            star2_hr INTEGER,
            angle REAL,
            star1_x REAL,
            star1_y REAL,
            star1_z REAL,
            star2_x REAL,
            star2_y REAL,
            star2_z REAL,
            PRIMARY KEY(star1_hr, star2_hr)
        )
        """)

    cursor.execute("""
        SELECT
            A.hr as star1_hr,
            B.hr as star2_hr,
            A.x as star1_x,
            A.y as star1_y,
            A.z as star1_z,
            B.x as star2_x,
            B.y as star2_y,
            B.z as star2_z,
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
        """)

    rows = cursor.fetchall()

    for row in rows:
        (
            star1_hr,
            star2_hr,
            star1_x,
            star1_y,
            star1_z,
            star2_x,
            star2_y,
            star2_z,
            dot_prod,
        ) = row
        if dot_prod > 1.0:
            assert dot_prod < 1.001  # anything higher means this is not a valid result
            dot_prod = 1.0
        elif dot_prod < -1.0:
            assert dot_prod > -1.001  # same as above
            dot_prod = -1.0
        theta = math.acos(dot_prod)
        # Camera FOV is <80, so exclude things over 80 degrees. This serves to reduce the size of the db.
        if theta < 80 * np.pi / 180:
            conn.execute(
                """
                INSERT INTO star_angles (star1_hr, star2_hr, angle, star1_x, star1_y, star1_z, star2_x, star2_y, star2_z)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    star1_hr,
                    star2_hr,
                    theta,
                    star1_x,
                    star1_y,
                    star1_z,
                    star2_x,
                    star2_y,
                    star2_z,
                ),
            )

    # Close the connection to the database
    conn.commit()
    conn.close()


if __name__ == "__main__":
    create_star_angle_table()
