"""
Creates a table `star_angles` in the sqlite3 database with the pairwise angles between stars.
"""

import math
import pathlib
import sqlite3


CURRENT_DIR = pathlib.Path(__file__).parent


# TODO: cap at 80 FOV
def create_star_angle_table():
    conn = sqlite3.connect(CURRENT_DIR / "../StarryNight/Sources/Resources/stars.sqlite3")
    cursor = conn.cursor()

    cursor.execute(
        """
        CREATE TABLE star_angles (
            star1_hr INTEGER,
            star2_hr INTEGER,
            angle REAL,
            PRIMARY KEY(star1_hr, star2_hr)
        )
        """
    )

    cursor.execute(
        """
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
        """
    )

    rows = cursor.fetchall()

    for row in rows:
        (star1_hr, star2_hr, dot_prod) = row
        if dot_prod > 1.0:
            assert dot_prod < 1.001  # anything higher means this is not a valid result
            dot_prod = 1.0
        elif dot_prod < -1.0:
            assert dot_prod > -1.001  # same as above
            dot_prod = -1.0
        theta = math.acos(dot_prod)
        conn.execute(
            """
            INSERT INTO star_angles (star1_hr, star2_hr, angle)
            VALUES (?, ?, ?)
            """,
            (star1_hr, star2_hr, theta),
        )

    conn.execute(
        """
        CREATE INDEX angle_index ON star_angles(angle);
        """
    )

    # Close the connection to the database
    conn.commit()
    conn.close()


if __name__ == "__main__":
    create_star_angle_table()
