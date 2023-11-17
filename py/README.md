
# Python Overview
Use the code here to develop and test the Startracker. This code was ran using Python 3.11.
First, install dependencies:
```
pip3 install -r requirements.txt
```

Next, use `make_test_images.py` to create synthetic images for testing. These have been uploaded to the Google Drive (see the main repo README), but their creation should be reproducable. If this is changed, please update the Google Drive.

For documentation, `sql.py` is tracked as well. It created the `star_angles` table in the sqlite3 stars database.

When you are done, don't forget to lint using `lint.sh`
TODO: use flake8?
