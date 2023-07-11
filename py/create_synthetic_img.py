"""
Creates synthetic images of the stars for testing.
"""

import argparse
from enum import Enum
import pathlib
import sqlite3
from typing import Tuple
import click

from matplotlib import pyplot as plt
from scipy.spatial.transform import Rotation
import numpy as np


CURRENT_DIR = pathlib.Path(__file__).parent


class DrawStarException(Exception):
    pass


class ImageType(Enum):
    # An image with a simple star pattern and no noise
    EASY = 0
    # Adds some noise to the star location
    # TODO: consider adding different star patterns as well as fake stars
    HARD = 1

    def draw_star_onto_image(self, img: np.ndarray, u: int, v: int) -> Tuple[int, int]:
        """
        Draws a star onto the img. If HARD type, (u, v) might be modified slightly
        to avoid creating a perfect image.

        Returns the (u,v) where the star was drawn.
        """

        def draw_simple_star(img, star_size, u, v):
            su = u - star_size // 2
            lu = u + star_size // 2 + 1
            sv = v - star_size // 2
            lv = v + star_size // 2 + 1
            assert su >= 0
            assert lu < img.shape[1]
            assert sv >= 0
            assert lv < img.shape[0]
            slc = img[sv:lv, su:lu]
            if (slc > 250).any():
                raise DrawStarException
            img[sv:lv, su:lu] = 255

        star_size = 5
        if self == ImageType.EASY:
            draw_simple_star(img, star_size, u, v)
        elif self == ImageType.HARD:
            du = None
            dv = None
            delta = 5
            if u - star_size // 2 >= delta and u + star_size // 2 < img.shape[1] - delta:
                du = (-delta, delta)
            if v - star_size // 2 >= delta and v + star_size // 2 < img.shape[0] - delta:
                dv = (-delta, delta)

            if du is not None:
                du = np.random.choice(np.arange(*du), size=1)[0]
                u += du
            if dv is not None:
                dv = np.random.choice(np.arange(*dv), size=1)[0]
                u += dv
            draw_simple_star(img, star_size, u, v)
        else:
            raise ValueError(f"Unhandled image type {self}")

        return u, v


def get_star_vecs():
    conn = sqlite3.connect(CURRENT_DIR / "../StarryNight/Sources/Resources/stars.sqlite3")

    cursor = conn.cursor()

    cursor.execute(
        """
        SELECT hr,x,y,z,dist FROM stars_7 WHERE hr!='' AND mag<4;
        """
    )

    rows = cursor.fetchall()
    conn.close()
    return rows


def create_synthetic_img(image_type: ImageType):
    """
    Creates a synthetic image using stars from the catalog
    """
    rows = get_star_vecs()

    # Transformation from Catalog Camera (Cc) to Synthetic Camera (Sc)
    if image_type == ImageType.EASY:
        np.random.seed(7)
        T_Sc_Cc = Rotation.from_euler("xyz", [20, -30, 40], degrees=True).as_matrix()
    elif image_type == ImageType.HARD:
        np.random.seed(13)
        T_Sc_Cc = Rotation.from_euler("xyz", [-70, 120, 70], degrees=True).as_matrix()
    else:
        raise ValueError(f"Unknown image type {image_type}")

    # TODO: make these command-line args?
    img_width = 960
    img_height = 540
    focal_length = 600  # in pixels

    intrinsics_mtx = np.array([[focal_length, 0, img_width // 2], [0, focal_length, img_height // 2], [0, 0, 1]])

    def can_project_star_onto_cam(star_ray):
        cam_ray = T_Sc_Cc @ star_ray
        if cam_ray[-1] < 0:
            # must have +z
            return False
        cam_ray = cam_ray / cam_ray[-1]
        tol = 0.02  # make sure star is sufficiently in-frame and not on the edge
        return (
            img_width / 2 / focal_length - abs(cam_ray[0]) > tol
            and img_height / 2 / focal_length - abs(cam_ray[1]) > tol
        )

    def project_star_onto_cam(star_ray):
        cam_ray = T_Sc_Cc @ star_ray
        cam_ray = cam_ray / cam_ray[-1]
        pix_ray = intrinsics_mtx @ cam_ray
        return round(pix_ray[0]), round(pix_ray[1])

    projectable_stars = []
    # Transformation from Catalog (C) to Camera Catalog (Cc)
    # The catalog follows the Equatorial coordinate system. Cameras
    # should have +x being horizontal to the right, +y being vertical
    # and downwards, and +z point out of the camera to the scene.
    # This matrix makes it possible to operate in camera spaces
    # starting with a camera placed at the same origin/orientation
    # as the catalog.
    T_Cc_C = np.array([[0, -1, 0], [0, 0, -1], [1, 0, 0]])
    assert np.linalg.det(T_Cc_C) == 1
    for row in rows:
        hr, x, y, z, dist = row
        star_ray = np.array([x, y, z]) / dist
        star_ray = T_Cc_C @ star_ray
        cp = can_project_star_onto_cam(star_ray)
        if cp:
            projectable_stars.append((hr, star_ray))

    stars_to_pick = 20
    print(f"Can project {len(projectable_stars)} stars out of {len(rows)}. Choosing at most {stars_to_pick}.")

    np.random.shuffle(projectable_stars)

    chosen_stars = []
    for ps_hr, ps_star_ray in projectable_stars:
        is_apart = True
        for cs_hr, cs_star_ray in chosen_stars:
            dp = np.dot(ps_star_ray, cs_star_ray)
            theta = np.arccos(dp)
            if theta < 5 * np.pi / 180:  # check 5 degrees apart
                is_apart = False
                break
        if is_apart:
            chosen_stars.append((ps_hr, ps_star_ray))
        if len(chosen_stars) == stars_to_pick:
            break

    assert len(chosen_stars) == stars_to_pick

    img = np.zeros((img_height, img_width, 3), dtype=np.uint8)
    all_star_locs = []
    for hr, star_ray in chosen_stars:
        u, v = project_star_onto_cam(star_ray)
        u, v = image_type.draw_star_onto_image(img, u, v)
        all_star_locs.append((hr, u, v))

    savepath = "synthetic_img.png"
    print(f"Saving image to {savepath}")
    plt.imsave(savepath, img)

    # Sort these in line-scan order
    all_star_locs.sort(key=lambda x: x[2] * img_width + x[1])

    # Use the following in any Swift unit-test
    print("Star locations (hr, u, v):\n", all_star_locs)

    print("Camera attitude:\n", T_Sc_Cc @ T_Cc_C)


@click.command
@click.argument("image_type", type=click.Choice([e.name for e in ImageType], case_sensitive=False))
def main(image_type: str):
    image_type = ImageType[image_type.upper()]
    create_synthetic_img(image_type)


if __name__ == "__main__":
    main()
