import cv2
import numpy as np
from scipy.spatial import distance as dist
import os
import json
import base64

class DocScanner:
    def __init__(self, MIN_QUAD_AREA_RATIO=0.25, MAX_QUAD_ANGLE_RANGE=40):
        self.MIN_QUAD_AREA_RATIO = MIN_QUAD_AREA_RATIO
        self.MAX_QUAD_ANGLE_RANGE = MAX_QUAD_ANGLE_RANGE

    def order_points(self, pts):
        # Sort points based on x-coordinates
        xSorted = pts[np.argsort(pts[:, 0]), :]

        # Get left-most and right-most points
        leftMost = xSorted[:2, :]
        rightMost = xSorted[2:, :]

        # Sort left-most points by y-coordinate
        leftMost = leftMost[np.argsort(leftMost[:, 1]), :]
        (tl, bl) = leftMost

        # Calculate bottom-right point using distance
        D = dist.cdist(tl[np.newaxis], rightMost, "euclidean")[0]
        (br, tr) = rightMost[np.argsort(D)[::-1], :]

        return np.array([tl, tr, br, bl], dtype="float32")

    def four_point_transform(self, image, pts):
        rect = self.order_points(pts)
        (tl, tr, br, bl) = rect

        # Compute width
        widthA = np.sqrt(((br[0] - bl[0]) ** 2) + ((br[1] - bl[1]) ** 2))
        widthB = np.sqrt(((tr[0] - tl[0]) ** 2) + ((tr[1] - tl[1]) ** 2))
        maxWidth = max(int(widthA), int(widthB))

        # Compute height
        heightA = np.sqrt(((tr[0] - br[0]) ** 2) + ((tr[1] - br[1]) ** 2))
        heightB = np.sqrt(((tl[0] - bl[0]) ** 2) + ((tl[1] - bl[1]) ** 2))
        maxHeight = max(int(heightA), int(heightB))

        dst = np.array([
            [0, 0],
            [maxWidth - 1, 0],
            [maxWidth - 1, maxHeight - 1],
            [0, maxHeight - 1]], dtype="float32")

        M = cv2.getPerspectiveTransform(rect, dst)
        warped = cv2.warpPerspective(image, M, (maxWidth, maxHeight))

        return warped

    def get_contour(self, image):
        # Get image dimensions
        height, width = image.shape[:2]

        # Convert to grayscale and apply preprocessing
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        # Apply multiple edge detection methods
        edges1 = cv2.Canny(blurred, 75, 200)
        edges2 = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 11, 2)
        edges = cv2.bitwise_or(edges1, edges2)

        # Dilate edges
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (9, 9))
        dilated = cv2.dilate(edges, kernel)

        # Find contours
        contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        if not contours:
            return self._get_default_corners(width, height)

        # Sort contours by area
        contours = sorted(contours, key=cv2.contourArea, reverse=True)[:5]

        for contour in contours:
            peri = cv2.arcLength(contour, True)
            approx = cv2.approxPolyDP(contour, 0.02 * peri, True)

            if len(approx) == 4:
                area = cv2.contourArea(approx)
                if area > (width * height * self.MIN_QUAD_AREA_RATIO):
                    return self.order_points(approx.reshape(4, 2))

        return self._get_default_corners(width, height)

    def _get_default_corners(self, width, height):
        return np.array([
            [width * 0.1, height * 0.1],
            [width * 0.9, height * 0.1],
            [width * 0.9, height * 0.9],
            [width * 0.1, height * 0.9]
        ], dtype=np.float32)

    def enhance_image(self, image):
        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Apply CLAHE (Contrast Limited Adaptive Histogram Equalization)
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)

        # Denoise
        denoised = cv2.fastNlMeansDenoising(enhanced)

        # Apply adaptive thresholding
        binary = cv2.adaptiveThreshold(
            denoised, 255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            21, 15
        )

        # Clean up noise
        kernel = np.ones((2, 2), np.uint8)
        cleaned = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)

        return cleaned

def scan_document(image_path):
    try:
        scanner = DocScanner()

        # Read image
        image = cv2.imread(image_path)
        if image is None:
            return json.dumps({"error": "Failed to load image"})

        # Get original dimensions
        original_height, original_width = image.shape[:2]

        # Resize image
        target_height = 500.0
        ratio = target_height / original_height
        resized_width = int(original_width * ratio)
        resized_height = int(target_height)
        resized = cv2.resize(image, (resized_width, resized_height), interpolation=cv2.INTER_AREA)

        # Get corners
        corners = scanner.get_contour(resized)

        # Convert image to base64
        _, buffer = cv2.imencode('.jpg', resized)
        image_base64 = base64.b64encode(buffer).decode()

        print(f"Detected corners: {corners.tolist()}")
        print(f"Preview dimensions: {resized_width}x{resized_height}")

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
        print(f"Error in scan_document: {str(e)}")
        return json.dumps({"error": str(e)})

def process_with_corners(image_path, corners):
    try:
        scanner = DocScanner()

        # Read image
        image = cv2.imread(image_path)
        if image is None:
            return "Error: Failed to load image"

        # Convert corners to numpy array
        corners_array = np.array(corners, dtype=np.float32)
        print(f"Processing corners: {corners_array.tolist()}")

        # Apply perspective transform
        warped = scanner.four_point_transform(image, corners_array)

        # Enhance image
        processed = scanner.enhance_image(warped)

        # Save result
        output_path = os.path.join(os.path.dirname(image_path), 'scanned_output.jpg')
        cv2.imwrite(output_path, processed)

        return output_path

    except Exception as e:
        print(f"Error processing image: {str(e)}")
        return f"Error: {str(e)}"

def test_scan():
    try:
        print("OpenCV Version:", cv2.__version__)
        print("NumPy Version:", np.__version__)
        return "Test successful"
    except Exception as e:
        return f"Test failed: {str(e)}"

if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1:
        result = scan_document(sys.argv[1])
        print(result)