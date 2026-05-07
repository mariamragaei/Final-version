from PIL import Image

input_path = "assets/images/app_icon.png"
output_path = "assets/images/app_icon_transparent.png"

img = Image.open(input_path).convert("RGBA")
pixels = img.load()
width, height = img.size

threshold = 230


for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[x, y]
        if r > threshold and g > threshold and b > threshold:
            pixels[x, y] = (0, 0, 0, 0)


img.save(output_path)
print("Done! Saved LARGE transparent icon to: " + output_path)
