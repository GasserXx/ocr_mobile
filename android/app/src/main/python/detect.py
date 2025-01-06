import cv2
import numpy as np
import json
import base64
from scipy.spatial import distance as dist

class DocumentDetector:
    def __init__(self, MIN_QUAD_AREA_RATIO=0.25):
        self.MIN_QUAD_AREA_RATIO = MIN_QUAD_AREA_RATIO

    def order_points(self, pts):
        xSorted = pts[np.argsort(pts[:, 0]), :]
        leftMost = xSorted[:2, :]
        rightMost = xSorted[2:, :]
        leftMost = leftMost[np.argsort(leftMost[:, 1]), :]
        (tl, bl) = leftMost
        D = dist.cdist(tl[np.newaxis], rightMost, "euclidean")[0]
        (br, tr) = rightMost[np.argsort(D)[::-1], :]
        return np.array([tl, tr, br, bl], dtype="float32")

    def detect_edges(self, image):
        height, width = image.shape[:2]

        # Convert to grayscale for edge detection only
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        # Edge detection
        edges = cv2.Canny(blurred, 75, 200)

        # Dilate edges
        kernel = np.ones((5,5), np.uint8)
        dilated = cv2.dilate(edges, kernel, iterations=1)

        # Find contours
        contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        # Default corners
        default_corners = np.array([
            [width * 0.1, height * 0.1],
            [width * 0.9, height * 0.1],
            [width * 0.9, height * 0.9],
            [width * 0.1, height * 0.9]
        ], dtype=np.float32)

        if not contours:
            return default_corners

        # Find the largest contour
        largest_contour = max(contours, key=cv2.contourArea)

        # Approximate the contour
        peri = cv2.arcLength(largest_contour, True)
        approx = cv2.approxPolyDP(largest_contour, 0.02 * peri, True)

        # If we found a contour with 4 points, use it
        if len(approx) == 4:
            corners = approx.reshape(4, 2).astype(np.float32)
            return self.order_points(corners)

        # If no suitable 4-point contour found, use the minimum area rectangle
        rect = cv2.minAreaRect(largest_contour)
        box = cv2.boxPoints(rect)
        return self.order_points(np.array(box, dtype="float32"))

    def crop_to_edges(self, image, corners):
        # Calculate width and height for the output image
        width = int(max(
            np.linalg.norm(corners[0] - corners[1]),
            np.linalg.norm(corners[2] - corners[3])
        ))
        height = int(max(
            np.linalg.norm(corners[1] - corners[2]),
            np.linalg.norm(corners[3] - corners[0])
        ))

        dst_points = np.array([
            [0, 0],
            [width - 1, 0],
            [width - 1, height - 1],
            [0, height - 1]
        ], dtype="float32")

        # Get perspective transform
        matrix = cv2.getPerspectiveTransform(corners, dst_points)

        # Apply perspective transform
        # Use INTER_LINEAR for better quality
        warped = cv2.warpPerspective(image, matrix, (width, height),
                                     flags=cv2.INTER_LINEAR,
                                     borderMode=cv2.BORDER_CONSTANT,
                                     borderValue=(255,255,255))

        return warped

def detect_document(image_path):
    try:
        detector = DocumentDetector()

        # Read image
        image = cv2.imread(image_path)
        if image is None:
            return json.dumps({"error": "Failed to load image"})

        # Get original dimensions
        original_height, original_width = image.shape[:2]

        # Resize image for processing
        target_height = 500.0
        ratio = target_height / original_height
        resized_width = int(original_width * ratio)
        resized_height = int(target_height)
        resized = cv2.resize(image, (resized_width, resized_height))

        # Detect corners
        corners = detector.detect_edges(resized)

        # Convert image to base64 for preview
        _, buffer = cv2.imencode('.jpg', resized)
        image_base64 = base64.b64encode(buffer).decode()

        return json.dumps({
            "image": image_base64,
            "corners": corners.tolist(),
            "ratio": float(ratio),
            "preview_size": {
                "width": resized_width,
                "height": resized_height
            }
        })

    except Exception as e:
        print(f"Error in detect_document: {str(e)}")
        return json.dumps({"error": str(e)})

def crop_document(image_path, corners):
    try:
        detector = DocumentDetector()

        # Read image
        image = cv2.imread(image_path)
        if image is None:
            return "Error: Failed to load image"

        # Convert corners to numpy array
        corners_array = np.array(corners, dtype=np.float32)

        # Crop image to corners
        cropped = detector.crop_to_edges(image, corners_array)

        # Save result with high quality
        output_path = image_path.replace('.jpg', '_cropped.jpg')
        cv2.imwrite(output_path, cropped, [cv2.IMWRITE_JPEG_QUALITY, 100])

        return output_path

    except Exception as e:
        print(f"Error cropping document: {str(e)}")
        return f"Error: {str(e)}"