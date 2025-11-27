import cv2
import numpy as np
import os

input_dir = "dataset/images"
output_dir = "dataset/masks"
os.makedirs(output_dir, exist_ok=True)

for file in os.listdir(input_dir):
    if not file.lower().endswith(('.png', '.jpg', '.jpeg', '.tif')):
        continue

    path = os.path.join(input_dir, file)
    img = cv2.imread(path)

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)

    _, mask = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

    white_ratio = np.mean(mask) / 255
    if white_ratio < 0.5:
        mask = cv2.bitwise_not(mask)

    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3,3))
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=2)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)

    out_path = os.path.join(output_dir, file)
    cv2.imwrite(out_path, mask)

    print(f"Máscara generada: {out_path}")
