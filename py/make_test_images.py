import logging
import pathlib

import create_synthetic_img
from config import configure_logger

CURRENT_DIR = pathlib.Path(__file__).parent
TEST_IMG_DIR = (CURRENT_DIR / "../StarryNight/Tests/Resources/").absolute()

logger = configure_logger(logging.INFO)


for img_type in [
    create_synthetic_img.ImageType.EASY,
    create_synthetic_img.ImageType.HARD,
]:
    name = None
    n = None
    if img_type == create_synthetic_img.ImageType.EASY:
        name = "easy"
        n = 0
    elif img_type == create_synthetic_img.ImageType.HARD:
        name = "hard"
        n = 20
    assert name is not None
    for i, seed in enumerate(range(19, 22)):
        savepath = TEST_IMG_DIR / f"img_syn_{name}_{i}.png"
        create_synthetic_img.create_synthetic_img(img_type, seed, 20, True, savepath=savepath)
        logger.info(
            "Setup the test case in Swift using the printed star locations and camera orientation quaternion, then"
            " press enter to continue:"
        )
        input()
