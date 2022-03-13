---
title: Fix Metadata of Google Photo Takeout
date: 2022-03-13 00:12:57
updated: 2022-03-13 00:12:57
categories: Tech
tags: 
    - Google Photo
---

Google Photo sucks.

When exporting photos from Google Photo, a bunch of JSON files come with your photos. Those JSON files contain metadata which is supposed to be stored with your photo files. If you simple import those photo files into another photo manager you will most likely not get a chronological view. Obviously, Google does on purpose so that you will not leave it easily.
However, there is a workaround that is able to merge those metadata into your photos.

1. Get `exiftool`: https://github.com/exiftool/exiftool
2. Export your Google Photos and extract the downloaded compressed files into a folder
3. Save the following content to `fix-args.txt`
```
# Usage: exiftool -@ fix-args.txt <takeout_dir>
-r
-d
%s
-tagsFromFile
%d/%F.json
-ext *
--ext json
-overwrite_original
-progress
-GPSAltitude<GeoDataAltitude
-GPSLatitude<GeoDataLatitude
-GPSLongitude<GeoDataLongitude
-DateTimeOriginal<PhotoTakenTimeTimestamp
-ModifyDate<PhotoLastModifiedTimeTimestamp
-CreateDate<CreationTimeTimestamp
-GPSAltitudeRef<GeoDataAltitude
-GPSLatitudeRef<GeoDataLatitude
-GPSLongitudeRef<GeoDataLongitude
```
4. Execute `exiftool -@ fix-args.txt <takeout_dir>`
5. Delete JSON files and import your photos to somewhere else

This argument file contains the fields that are meaningful to me. If you need to merge additional fields you can append them to the last. For details, check the man page of `exiftool`.
