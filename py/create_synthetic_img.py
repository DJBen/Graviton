"""
Creates synthetic images of the stars for testing.
"""

from enum import Enum
import pathlib
import sqlite3
from typing import Tuple
import click

from matplotlib import pyplot as plt
from scipy.spatial.transform import Rotation
import numpy as np
from PIL import Image, ImageDraw

CURRENT_DIR = pathlib.Path(__file__).parent

# See ImageType.Hard
MAX_STAR_ANGLE_NOISE = 1 * np.pi / 180


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
            # TODO: bring back
            if (slc >= STAR_PIX_VALUE).any():
                raise DrawStarException
            img[sv:lv, su:lu] = STAR_PIX_VALUE

        star_size = 10
        draw_simple_star(img, star_size, u, v)


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


def create_synthetic_img(image_type: ImageType, seed: int, n: int, annotate: bool):
    """
    Creates a synthetic image using stars from the catalog.

    Args:
        image_type: The type of image to create
        seed: The random seed to generate images with
        n: The number of stars to create. -1 for every possible star.
        annotate: Also create an annotated image.
    """
    np.random.seed(seed)
    rows = get_star_vecs()

    # TOOD: doc better
    # Transformation from Ref0 (C) to Camera Catalog (Cc)
    # The catalog follows the Equatorial coordinate system. Cameras
    # should have +x being horizontal to the right, +y being vertical
    # and downwards, and +z point out of the camera to the scene.
    # This matrix makes it possible to operate in camera spaces
    # starting with a camera placed at the same origin/orientation
    # as the catalog.
    T_Cam0_Ref0 = np.array(
        [[0, -1, 0], [0, 0, -1], [1, 0, 0]],
    )
    assert abs(np.linalg.det(T_Cam0_Ref0) - 1) < 1e-4

    # Transformation from Synthetic Camera (SCam) to Catalog Camera (Cam)
    # T_SCam_Cam = generate_rmtx()
    # T_total = (
    #     np.array(
    #         [
    #             0.019485976463295918,
    #             0.11912072276943125,
    #             0.99268854638711567,
    #             -0.61402311514330277,
    #             -0.78215011115343214,
    #             0.10590947876555012,
    #             0.78904747055610469,
    #             -0.61159746323015818,
    #             0.05790191861630798,
    #         ]
    #     )
    #     .reshape(3, 3)
    #     .T
    # )
    # T_total = (
    #     np.array(
    #         [
    #             -0.46787028772970113,
    #             -0.56094838084966769,
    #             -0.68295996067255771,
    #             -0.18252965072077579,
    #             -0.69476571291924316,
    #             0.69568924870200954,
    #             -0.86474292160588317,
    #             0.45015277203850562,
    #             0.22267052197938247,
    #         ]
    #     )
    #     .reshape(3, 3)
    #     .T
    # )
    T_total = (
        T_Cam0_Ref0.T
        @ np.array(
            [
                [0.5623346203242522, 0.6826382003753101, -0.46667425702853865],
                [0.6945968872874663, -0.6961652156778432, -0.18135367834920305],
                [-0.44868133341531236, -0.2221690344503091, -0.8656361713653581],
            ]
        ).T
    )
    print("TT", T_total)

    # # T_total = Rotation.from_quat([-0.0, 0.15701063, 0.09142743, 0.9833558]).as_matrix().T
    T_SCam_Cam = T_Cam0_Ref0 @ T_total @ T_Cam0_Ref0.T

    # TODO: make these command-line args?
    # FOV matches the camera in app and the hardware camera
    vfov = 70.29109 * np.pi / 180
    # focal_length = 2863.6363
    # img_height = np.tan(vfov / 2) * focal_length * 2
    # img_width = img_height / 2
    img_height = 4032
    img_width = 3024
    focal_length = 1.0 / np.tan(vfov / 2) * img_height / 2
    print("Focal length:", focal_length)

    img_height = int(img_height)
    img_width = int(img_width)
    print(f"Creating image of size {img_width}x{img_height}")

    intrinsics_mtx = np.array([[focal_length, 0, img_width // 2], [0, focal_length, img_height // 2], [0, 0, 1]])

    def can_project_star_onto_cam(star_ray):
        cam_ray = T_SCam_Cam @ T_Cam0_Ref0 @ star_ray
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
        print("NET", T_SCam_Cam @ T_Cam0_Ref0)
        print("INT", intrinsics_mtx)
        print("STAR RAY", star_ray)
        cam_ray = T_SCam_Cam @ T_Cam0_Ref0 @ star_ray
        if image_type == ImageType.HARD:
            # TODO: make sure noise vec does not make it go out of range for the image...
            cam_ray = cam_ray / np.linalg.norm(cam_ray)
            noise_vector = np.random.randn(3)  # random direction
            noise_vector = noise_vector / np.linalg.norm(noise_vector)  # normalize to length 1
            noise_vector = noise_vector * np.tan(MAX_STAR_ANGLE_NOISE)  # scale to desired angle
            cam_ray_new = cam_ray + noise_vector
            assert np.arccos(np.dot(cam_ray_new, cam_ray) <= MAX_STAR_ANGLE_NOISE)
            cam_ray = cam_ray / cam_ray[-1]
            pix_ray = intrinsics_mtx @ cam_ray

            cam_ray = cam_ray_new / cam_ray_new[-1]
            pix_ray_new = intrinsics_mtx @ cam_ray

            print("DELTA PIX", pix_ray_new - pix_ray)

            cam_ray = cam_ray_new

        cam_ray = cam_ray / cam_ray[-1]
        pix_ray = intrinsics_mtx @ cam_ray
        print("PIX RAY", pix_ray)
        return round(pix_ray[0]), round(pix_ray[1])

    projectable_stars = []
    for row in rows:
        hr, x, y, z, dist = row
        star_ray = np.array([x, y, z]) / dist
        cp = can_project_star_onto_cam(star_ray)
        if cp:
            projectable_stars.append((hr, star_ray))

        # if hr == 188:
        #     arr = np.array([x, y, z]) / dist
        #     arr2 = T_SCam_Cam @ T_Cam0_Ref0 @ arr
        #     print("Hr188", cp, arr, arr2)
        # if hr == 4554:
        #     print("HR 4554 CP", cp)

    if n == 0:
        n = len(projectable_stars)
    assert n >= 1
    n = min(n, len(projectable_stars))
    print(f"Can project {len(projectable_stars)} stars out of {len(rows)}. Choosing {n}.")

    np.random.shuffle(projectable_stars)

    chosen_stars = projectable_stars[:n]
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
            print(f"Skipping drawing star {hr} at ({u}, {v}) cause it would overlap an existing drawn star")
        all_star_locs.append((hr, u, v))

    savepath = "synthetic_img.png"
    print(f"Saving image to {savepath}")
    plt.imsave(savepath, img)

    if annotate:
        pil_img = Image.fromarray(img)
        draw = ImageDraw.Draw(pil_img)
        for hr, u, v in all_star_locs:
            draw.text((u, v), f"HR {hr}", fill="red")
        savepath = "annotated_synthetic_img.png"
        print(f"Saving annotated image to {savepath}")
        pil_img.save(savepath)

    # Sort these in line-scan order
    all_star_locs.sort(key=lambda x: x[2] * img_width + x[1])

    # Use the following in any Swift unit-test
    print("Star locations (hr, u, v):\n", all_star_locs)

    # Convert the rotation into the orientation that one can plug into the
    # camera node orientation in Swift.
    # This defines the full rotation in the reference catalog coordinate system
    # of the camera
    cmtx = T_Cam0_Ref0.T @ T_SCam_Cam @ T_Cam0_Ref0
    # We invert the matrix here because Swift seems to want use to provide
    # the transform T_R_C (go from camera to reference)
    swift_mtx = Rotation.from_matrix(cmtx.T)
    swift_rmtx = swift_mtx.as_matrix()
    swift_quat = swift_mtx.as_quat()
    print("Camera orientation in Swift:")
    print("Quat:", swift_quat)
    print("Rotation Matrix:\nMatrix([")
    for row in swift_rmtx:
        row = np.round(row, decimals=4)
        print(f"Vector([{row[0]}, {row[1]}, {row[2]}]),")
    print("])")


def generate_rmtx():
    random_matrix = np.random.normal(size=(3, 3))
    Q, R = np.linalg.qr(random_matrix)
    if np.linalg.det(Q) < 0:  # If the determinant is -1, we flip the sign of last column of Q
        Q[:, 2] *= -1
    return Q


@click.command
@click.argument("image_type", type=click.Choice([e.name for e in ImageType], case_sensitive=False))
@click.argument("seed", type=int)
@click.argument("n", type=int)
def main(image_type: str, seed: int, n: int):
    image_type = ImageType[image_type.upper()]
    create_synthetic_img(image_type, seed, n, True)


if __name__ == "__main__":
    main()
