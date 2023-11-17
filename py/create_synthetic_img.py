"""
Creates synthetic images of the stars for testing.
"""

import logging
import pathlib
import sqlite3
from enum import Enum
from typing import Optional, Tuple

import click
import numpy as np
from matplotlib import pyplot as plt
from PIL import Image, ImageDraw
from scipy.spatial.transform import Rotation

from config import configure_logger, get_logger

CURRENT_DIR = pathlib.Path(__file__).parent

# See ImageType.HARD
MAX_STAR_ANGLE_NOISE = 1 * np.pi / 180


_LOGGER = get_logger()


class DrawStarException(Exception):
    pass


class ImageType(Enum):
    # An image with a simple star pattern and no noise
    EASY = 0
    # Adds up to MAX_STAR_ANGLE_NOISE angle noise to the star location
    # TODO: consider adding different star patterns as well as fake stars
    HARD = 1

    def draw_star_onto_image(self, img: np.ndarray, u: int, v: int) -> Tuple[int, int]:
        """
        Draws a star onto the img.
        """

        STAR_PIX_VALUE = 200

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
            if (slc >= STAR_PIX_VALUE).any():
                raise DrawStarException
            img[sv:lv, su:lu] = STAR_PIX_VALUE

        star_size = 10
        draw_simple_star(img, star_size, u, v)


def get_star_vecs():
    conn = sqlite3.connect(CURRENT_DIR / "../StarryNight/Sources/Resources/stars.sqlite3")

    cursor = conn.cursor()

    cursor.execute("""
        SELECT hr,x,y,z,dist FROM stars_7 WHERE hr!='' AND mag<4;
        """)

    rows = cursor.fetchall()
    conn.close()
    return rows


def create_synthetic_img(
    image_type: ImageType,
    seed: int,
    n: int,
    annotate: bool,
    savepath: Optional[pathlib.Path] = None,
):
    """
    Creates a synthetic image using stars from the catalog.

    Args:
        image_type: The type of image to create
        seed: The random seed to generate images with
        n: The number of stars to create. 0 means project every possible star.
        annotate: Also create an annotated image.
        savepath: Where to save the image.
    """
    if savepath is None:
        savepath = pathlib.Path("synthetic_img.png")

    rand_gen = np.random.RandomState(seed)
    rows = get_star_vecs()

    T_Cc_Ceq = np.array(
        [[0, -1, 0], [0, 0, -1], [1, 0, 0]],
    )
    assert abs(np.linalg.det(T_Cc_Ceq) - 1) < 1e-4

    T_Mc_Cc = generate_rmtx(rand_gen)

    # TODO: make these command-line args?
    # FOV matches the camera in app and the hardware camera
    vfov = 70.29109 * np.pi / 180
    # Based on what iOS gives me for iPhone 12 photos. This is
    # seemingly configurable on iOS side.
    img_height = 4032
    img_width = 3024
    focal_length = 1.0 / np.tan(vfov / 2) * img_height / 2
    _LOGGER.info(f"Focal length: {focal_length}")

    img_height = int(img_height)
    img_width = int(img_width)
    _LOGGER.info(f"Creating image of size {img_width}x{img_height}")

    intrinsics_mtx = np.array([
        [focal_length, 0, img_width // 2],
        [0, focal_length, img_height // 2],
        [0, 0, 1],
    ])

    def can_project_star_onto_cam(star_ray):
        # Transforms the star_ray from the Catalog equatorial system to the Mobile camera system
        cam_ray = T_Mc_Cc @ T_Cc_Ceq @ star_ray
        if cam_ray[-1] < 0:
            # must have +z
            return False
        cam_ray = cam_ray / cam_ray[-1]
        tol = 0.02  # make sure star is sufficiently in-frame and not on the edge
        return (
            img_width / 2 / focal_length - abs(cam_ray[0]) > tol
            and img_height / 2 / focal_length - abs(cam_ray[1]) > tol
        )

    def project_star_onto_cam(image_type: ImageType, star_ray):
        _LOGGER.debug("Star ray", star_ray)
        cam_ray = T_Mc_Cc @ T_Cc_Ceq @ star_ray
        if image_type == ImageType.HARD:
            # TODO: make sure noise vec does not make it go out of projection for the image
            cam_ray = cam_ray / np.linalg.norm(cam_ray)
            noise_vector = rand_gen.randn(3)  # random direction
            noise_vector = noise_vector / np.linalg.norm(noise_vector)  # normalize to length 1
            noise_vector = noise_vector * np.tan(MAX_STAR_ANGLE_NOISE)  # scale to desired angle
            cam_ray_new = cam_ray + noise_vector
            assert np.arccos(np.dot(cam_ray_new, cam_ray) <= MAX_STAR_ANGLE_NOISE)
            cam_ray = cam_ray / cam_ray[-1]
            pix_ray = intrinsics_mtx @ cam_ray

            cam_ray = cam_ray_new / cam_ray_new[-1]
            pix_ray_new = intrinsics_mtx @ cam_ray

            _LOGGER.debug("DELTA PIX", pix_ray_new - pix_ray)

            cam_ray = cam_ray_new

        cam_ray = cam_ray / cam_ray[-1]
        pix_ray = intrinsics_mtx @ cam_ray
        _LOGGER.debug("PIX RAY", pix_ray)
        return round(pix_ray[0]), round(pix_ray[1])

    projectable_stars = []
    for row in rows:
        hr, x, y, z, dist = row
        star_ray = np.array([x, y, z]) / dist
        cp = can_project_star_onto_cam(star_ray)
        if cp:
            projectable_stars.append((hr, star_ray))
    if n == 0:
        n = len(projectable_stars)
    assert n >= 1
    n = min(n, len(projectable_stars))
    _LOGGER.info(f"Can project {len(projectable_stars)} stars out of {len(rows)}. Choosing {n}.")

    rand_gen.shuffle(projectable_stars)

    chosen_stars = projectable_stars[:n]
    # TODO: this might be needed to prevent two stars from being drawn too closely. The code
    # currently checks for overlap when drawing stars, but perhaps we should check closeness?
    # For now, this is commented out because "close" stars are presumably imagable, and hence
    # the algorithm should handle them properly.
    # chosen_stars = []
    # for ps_hr, ps_star_ray in projectable_stars:
    #     is_apart = True
    #     for cs_hr, cs_star_ray in chosen_stars:
    #         dp = np.dot(ps_star_ray, cs_star_ray)
    #         theta = np.arccos(dp)
    #         # if theta < 5 * np.pi / 180:  # check 5 degrees apart
    #         #     is_apart = False
    #         #     break
    #     if is_apart:
    #         chosen_stars.append((ps_hr, ps_star_ray))
    #     if len(chosen_stars) == n:
    #         break

    assert len(chosen_stars) == n

    img = np.zeros((img_height, img_width, 3), dtype=np.uint8)
    all_star_locs = []
    for hr, star_ray in chosen_stars:
        u, v = project_star_onto_cam(image_type, star_ray)
        try:
            image_type.draw_star_onto_image(img, u, v)
        except DrawStarException:
            _LOGGER.error(f"Skipping drawing star {hr} at ({u}, {v}) cause it would overlap an existing drawn star")
        all_star_locs.append((hr, u, v))

    _LOGGER.info(f"Saving image to: {savepath}")
    plt.imsave(savepath, img)

    if annotate:
        pil_img = Image.fromarray(img)
        draw = ImageDraw.Draw(pil_img)
        for hr, u, v in all_star_locs:
            draw.text((u, v), f"HR {hr}", fill="red")
        annot_savepath = savepath.parent / ("annotated_" + savepath.name)
        _LOGGER.info(f"Saving annotated image to: {annot_savepath}")
        pil_img.save(annot_savepath)

    # Sort these in line-scan order
    all_star_locs.sort(key=lambda x: x[2] * img_width + x[1])

    # Use the following in any Swift unit-test
    _LOGGER.info(f"Star locations (hr, u, v):\n{all_star_locs}")

    # These ultimately computes `T_Ceq_Meq`, which defines how to go from
    # the mobile to catalog in Equatorial coordinate system
    # This could be set as the virtual camera node orientation in Swift.
    T_Meq_Ceq = T_Cc_Ceq.T @ T_Mc_Cc @ T_Cc_Ceq
    T_Ceq_Meq = T_Meq_Ceq.T
    
    swift_mtx = Rotation.from_matrix(T_Ceq_Meq)
    swift_rmtx = swift_mtx.as_matrix()
    swift_quat = swift_mtx.as_quat()
    _LOGGER.info(f"Camera orientation in Swift:\nQuat: {swift_quat}")
    rotation_mtx_print_str = "Rotation Matrix:\nMatrix([\n"
    for row in swift_rmtx:
        row = np.round(row, decimals=4)
        rotation_mtx_print_str += f"Vector([{row[0]}, {row[1]}, {row[2]}]),\n"
    rotation_mtx_print_str += "])"
    _LOGGER.info(rotation_mtx_print_str)


def generate_rmtx(rand_gen):
    random_matrix = rand_gen.normal(size=(3, 3))
    Q, R = np.linalg.qr(random_matrix)
    if np.linalg.det(Q) < 0:  # If the determinant is -1, we flip the sign of last column of Q
        Q[:, 2] *= -1
    return Q


@click.command
@click.argument("image_type", type=click.Choice([e.name for e in ImageType], case_sensitive=False))
@click.argument("seed", type=int)
@click.argument("n", type=int)
def main(image_type: str, seed: int, n: int):
    configure_logger(logging.DEBUG)
    image_type = ImageType[image_type.upper()]
    create_synthetic_img(image_type, seed, n, True)


if __name__ == "__main__":
    main()
