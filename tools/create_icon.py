"""
Simple script to create a checkmark icon for the app.
Requires: pip install pillow
"""
from PIL import Image, ImageDraw

def create_checkmark_icon(size=1024):
    """Create a green checkmark icon on a white background with rounded corners."""
    # Create image with white background
    img = Image.new('RGBA', (size, size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Draw rounded rectangle background (light blue/green gradient effect)
    # For simplicity, we'll use a solid color
    background_color = (76, 175, 80, 255)  # Material Green
    
    # Draw rounded rectangle
    corner_radius = size // 8
    draw.rounded_rectangle(
        [(0, 0), (size, size)],
        radius=corner_radius,
        fill=background_color
    )
    
    # Draw checkmark
    # Checkmark is drawn as a thick polyline
    stroke_width = size // 12
    checkmark_color = (255, 255, 255, 255)  # White
    
    # Calculate checkmark coordinates (centered)
    padding = size // 4
    
    # Checkmark points (as percentage of size)
    points = [
        (0.25, 0.5),   # Left point
        (0.42, 0.68),  # Bottom point
        (0.75, 0.32),  # Top right point
    ]
    
    # Convert to actual coordinates
    coords = [(int(size * x), int(size * y)) for x, y in points]
    
    # Draw the checkmark with thick lines
    for i in range(len(coords) - 1):
        draw.line([coords[i], coords[i + 1]], fill=checkmark_color, width=stroke_width)
    
    return img

if __name__ == '__main__':
    # Create the icon
    icon = create_checkmark_icon(1024)
    
    # Save it
    icon.save('assets/icon/app_icon.png')
    print('Icon created successfully at assets/icon/app_icon.png')
    print('  Run: flutter pub get')
    print('  Then: dart run flutter_launcher_icons')
