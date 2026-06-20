import os
from PIL import Image

sprites_dir = "assets/sprites"
jpgs = [f for f in os.listdir(sprites_dir) if f.endswith(".jpg")]

for jpg in jpgs:
    path = os.path.join(sprites_dir, jpg)
    img = Image.open(path).convert("RGBA")
    data = img.getdata()
    
    new_data = []
    for item in data:
        # Change all dark pixels to transparent
        # If it's close to black (e.g., r,g,b < 40)
        if item[0] < 50 and item[1] < 50 and item[2] < 50:
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    
    png_name = jpg.replace(".jpg", ".png")
    img.save(os.path.join(sprites_dir, png_name), "PNG")
    print(f"Converted {jpg} to {png_name}")
