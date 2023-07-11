import sqlite3
import math
from matplotlib import pyplot as plt
import numpy as np
from scipy.spatial.transform import Rotation

np.random.seed(7)

conn = sqlite3.connect('./StarryNight/Sources/Resources/stars.sqlite3')

cursor = conn.cursor()

cursor.execute('''
    SELECT hr,x,y,z,dist FROM stars_7 WHERE hr!='' AND mag<4;
''')

rows = cursor.fetchall()

# Transformation from synthetic camera (S) to camera (C) 
T_SC = Rotation.from_euler('xyz', [20, -30, 40], degrees=True).as_matrix()

img_width = 960
img_height = 540
focal_length = 600  # in pixels

intrinsics_mtx = np.array([
    [focal_length, 0, img_width//2],
    [0, focal_length, img_height//2],
    [0, 0, 1]
])
intrinsics_inv = np.linalg.inv(intrinsics_mtx)


def can_project_star_onto_cam(star_ray):
    cam_ray = T_SC @ star_ray
    if cam_ray[-1] < 0:
        # must have +z
        return False
    cam_ray = cam_ray / cam_ray[-1]
    tol = 0.02  # make sure star is sufficiently in-frame
    return tol < img_width / 2 / focal_length - abs(cam_ray[0]) and tol < img_height / 2 / focal_length - abs(cam_ray[1])


# TODO: make images look diff
# TODO: bounds check
def project_star_onto_cam(star_ray):
    cam_ray = T_SC @ star_ray
    cam_ray = cam_ray / cam_ray[-1]
    pix_ray = intrinsics_mtx @ cam_ray
    return int(pix_ray[0]), int(pix_ray[1])


projectable_stars = []
T_CR = np.array([
    [0, -1, 0],
    [0, 0, -1],
    [1, 0, 0]
])
assert np.linalg.det(T_CR) == 1
for row in rows:
    hr, x, y, z, dist = row
    star_ray = np.array([x, y, z]) / dist
    star_ray = T_CR @ star_ray
    cp = can_project_star_onto_cam(star_ray)
    if cp:
        projectable_stars.append((hr, star_ray))

stars_to_pick = 20
print(f"Can project {len(projectable_stars)} stars out of {len(rows)}. Choosing at most {stars_to_pick}")

np.random.shuffle(projectable_stars)

chosen_stars = []
for (ps_hr, ps_star_ray) in projectable_stars:
    is_apart = True
    for (cs_hr, cs_star_ray) in chosen_stars:
        dp = np.dot(ps_star_ray, cs_star_ray)
        theta = np.arccos(dp)
        if theta < 0.087266:  # check 5 degrees apart
            is_apart = False
            break
    if is_apart:
        chosen_stars.append((ps_hr, ps_star_ray))
    if len(chosen_stars) == stars_to_pick:
        break

assert len(chosen_stars) == stars_to_pick

img = np.zeros((img_height, img_width, 3), dtype=np.uint8)
all_star_locs = []
star_size = 5
for (hr, star_ray) in chosen_stars:
    u, v = project_star_onto_cam(star_ray)
    su = u-star_size//2
    lu = u+star_size//2 + 1
    sv = v-star_size//2
    lv = v+star_size//2 + 1
    assert su >= 0, f"Failed for {hr} at {u} {v}"
    assert lu < img_width
    assert sv >= 0
    assert lv < img_height, f"Failed for {hr} at {u} {v}"
    img[sv:lv, su:lu] = 255
    all_star_locs.append((hr, u, v))

plt.imsave('synthetic_img.png', img)
conn.close()

# sort these in line-scan order
all_star_locs.sort(key=lambda x: x[2] * img_width + x[1])

print(all_star_locs)

for i in range(3):
    x = all_star_locs[i]
    arr = np.array([x[1], x[2], 1])

    arr = intrinsics_inv @ arr
    print(arr / np.linalg.norm(arr))

print("NET ROTATION:\n", T_SC @ T_CR)
