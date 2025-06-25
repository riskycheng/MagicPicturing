import os
import json
import random
import math

# ==============================================================================
# Configuration
# ==============================================================================
OUTPUT_DIR = "CollageTemplates"
TEMPLATES_PER_COUNT = 20
IMAGE_COUNTS = range(2, 10) # For 2 to 9 images

# ==============================================================================
# Helper Functions
# ==============================================================================
def ensure_dir(directory):
    """Creates a directory if it doesn't exist."""
    if not os.path.exists(directory):
        os.makedirs(directory)

def format_points(points):
    """Formats a list of [x, y] points into the required string format."""
    return f"[{'; '.join([f'{p[0]:.3f},{p[1]:.3f}' for p in points])}]"

# ==============================================================================
# Shape Generation
# ==============================================================================
def get_shape_rectangle(corner_radius=0.0):
    shape = {"type": "rectangle"}
    if corner_radius > 0:
        shape["parameters"] = {"cornerRadius": f"{corner_radius:.2f}"}
    return shape

def get_shape_polygon(points):
    return {"type": "polygon", "parameters": {"points": format_points(points)}}

def get_shape_parallelogram(slant=0.3):
    """Creates a right-leaning parallelogram."""
    return get_shape_polygon([[slant, 0], [1, 0], [1 - slant, 1], [0, 1]])

def get_shape_trapezoid(inset=0.2):
    """Creates a trapezoid inset at the top."""
    return get_shape_polygon([[inset, 0], [1 - inset, 0], [1, 1], [0, 1]])

def get_random_shape():
    """Returns a random, simple shape definition."""
    shape_type = random.choice(["rectangle", "circle", "ellipse", "parallelogram", "trapezoid"])
    if shape_type == "rectangle":
        return get_shape_rectangle(corner_radius=random.uniform(0, 0.3))
    if shape_type == "circle":
        return {"type": "circle"}
    if shape_type == "ellipse":
        return {"type": "ellipse"}
    if shape_type == "parallelogram":
        return get_shape_parallelogram(slant=random.uniform(0.1, 0.4))
    if shape_type == "trapezoid":
        return get_shape_trapezoid(inset=random.uniform(0.1, 0.3))
    return get_shape_rectangle() # Fallback

# ==============================================================================
# Layout Generation Strategies
# ==============================================================================
def strategy_grid(image_count):
    """Generates a grid layout, allowing for random empty cells."""
    factors = [(i, image_count // i) for i in range(1, int(math.sqrt(image_count)) + 1) if image_count % i == 0]
    if not factors:
        rows, cols = 1, image_count
    else:
        rows, cols = random.choice(factors)
    if random.random() < 0.5:
        rows, cols = cols, rows

    w, h = 1.0 / cols, 1.0 / rows
    frames = []
    
    use_same_shape = random.random() > 0.5
    base_shape = get_random_shape()

    for i in range(rows):
        for j in range(cols):
            if len(frames) >= image_count: continue
            
            frame_w = w * random.uniform(0.85, 1.0)
            frame_h = h * random.uniform(0.85, 1.0)
            x = (j * w) + (w - frame_w) / 2
            y = (i * h) + (h - frame_h) / 2

            frames.append({
                "x": f"{x:.3f}", "y": f"{y:.3f}",
                "width": f"{frame_w:.3f}", "height": f"{frame_h:.3f}",
                "rotation": f"{random.uniform(-5, 5):.1f}",
                "shape": base_shape if use_same_shape else get_random_shape()
            })
    random.shuffle(frames)
    return frames, float(cols) / float(rows)

def strategy_overlap(image_count):
    """Generates a layout of overlapping shapes, like a pile of photos."""
    frames = []
    center_x, center_y = random.uniform(0.4, 0.6), random.uniform(0.4, 0.6)
    base_shape = random.choice([get_shape_rectangle(0.1), {"type": "circle"}])
    
    for i in range(image_count):
        w = random.uniform(0.4, 0.7)
        h = w * random.uniform(0.8, 1.2)
        x = center_x - w/2 + random.uniform(-0.15, 0.15)
        y = center_y - h/2 + random.uniform(-0.15, 0.15)

        frames.append({
            "x": f"{x:.3f}", "y": f"{y:.3f}",
            "width": f"{w:.3f}", "height": f"{h:.3f}",
            "rotation": f"{random.uniform(-25, 25):.1f}",
            "shape": base_shape
        })
    return frames, 1.0

def strategy_v_strips(image_count):
    """Generates a series of vertical strips with various shapes."""
    frames = []
    w = 1.0 / image_count
    use_same_shape = random.random() > 0.5
    base_shape = get_random_shape()

    for i in range(image_count):
        frames.append({
            "x": f"{i * w:.3f}", "y": "0.0",
            "width": f"{w:.3f}", "height": "1.0",
            "rotation": "0.0",
            "shape": base_shape if use_same_shape else get_random_shape()
        })
    return frames, 0.75
    
def strategy_h_strips(image_count):
    """Generates a series of horizontal strips."""
    frames = []
    h = 1.0 / image_count
    use_same_shape = random.random() > 0.5
    base_shape = get_random_shape()

    for i in range(image_count):
        frames.append({
            "x": "0.0", "y": f"{i * h:.3f}",
            "width": "1.0", "height": f"{h:.3f}",
            "rotation": "0.0",
            "shape": base_shape if use_same_shape else get_random_shape()
        })
    return frames, 1.33

def strategy_central_item(image_count):
    """One large item in the center with smaller items around it."""
    if image_count < 2: return strategy_grid(image_count)
    frames = []
    
    # Central item
    w, h = random.uniform(0.5, 0.7), random.uniform(0.5, 0.7)
    x, y = (1-w)/2, (1-h)/2
    frames.append({
        "x": f"{x:.3f}", "y": f"{y:.3f}",
        "width": f"{w:.3f}", "height": f"{h:.3f}",
        "rotation": f"{random.uniform(-5, 5):.1f}",
        "shape": get_random_shape()
    })
    
    # Surrounding items
    remaining_count = image_count - 1
    for i in range(remaining_count):
        angle = (i / remaining_count) * 2 * math.pi
        dist = random.uniform(0.3, 0.45)
        item_w, item_h = random.uniform(0.15, 0.3), random.uniform(0.15, 0.3)
        item_x = 0.5 + dist * math.cos(angle) - item_w / 2
        item_y = 0.5 + dist * math.sin(angle) - item_h / 2
        frames.append({
            "x": f"{item_x:.3f}", "y": f"{item_y:.3f}",
            "width": f"{item_w:.3f}", "height": f"{item_h:.3f}",
            "rotation": f"{random.uniform(-20, 20):.1f}",
            "shape": get_random_shape()
        })
    return frames, 1.0
    
# ==============================================================================
# Main Generation Logic
# ==============================================================================
def generate_template(image_count, index):
    """Selects a strategy and generates a single template."""
    strategies = [strategy_grid, strategy_overlap, strategy_v_strips, strategy_h_strips]
    if image_count > 2:
        strategies.append(strategy_central_item)
    
    strategy = random.choice(strategies)
    frames, aspect_ratio = strategy(image_count)
    
    # Post-processing to ensure frames are valid
    for frame in frames:
        for key in ['x', 'y', 'width', 'height']:
            frame[key] = f"{max(0, float(frame[key])):.3f}"
        if float(frame['x']) + float(frame['width']) > 1.0:
            frame['x'] = f"{1.0 - float(frame['width']):.3f}"
        if float(frame['y']) + float(frame['height']) > 1.0:
            frame['y'] = f"{1.0 - float(frame['height']):.3f}"
            
    template = {
        "name": f"{strategy.__name__.replace('strategy_', '')}_{index}",
        "imageCount": image_count,
        "aspectRatio": round(aspect_ratio, 2),
        "frameDefinitions": frames
    }
    return template

def main():
    if not os.path.exists("MagicPicturing.xcodeproj"):
        print("Error: This script should be run from the project root directory.")
        return

    print(f"Clearing old templates from '{OUTPUT_DIR}'...")
    if os.path.exists(OUTPUT_DIR):
        for root, dirs, files in os.walk(OUTPUT_DIR, topdown=False):
            for name in files:
                os.remove(os.path.join(root, name))
            for name in dirs:
                os.rmdir(os.path.join(root, name))

    print("Generating new creative templates...")
    for count in IMAGE_COUNTS:
        folder_path = os.path.join(OUTPUT_DIR, f"{count}_images")
        ensure_dir(folder_path)
        for i in range(1, TEMPLATES_PER_COUNT + 1):
            template_data = generate_template(count, i)
            file_path = os.path.join(folder_path, f"template_{i}.json")
            with open(file_path, 'w') as f:
                json.dump(template_data, f, indent=4)
    
    print("-" * 30)
    print(f"Successfully generated {TEMPLATES_PER_COUNT * len(IMAGE_COUNTS)} templates.")
    print("You may need to re-add the 'CollageTemplates' folder to your Xcode project.")
    print("Make sure 'Create folder references' is selected.")
    print("-" * 30)

if __name__ == "__main__":
    main() 