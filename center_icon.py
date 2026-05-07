from PIL import Image

def main():
    logo = Image.open('assets/images/logo.png')
    bg = Image.new('RGBA', (1024, 1024), (255, 255, 255, 255))

    target_width = 800
    target_height = int(logo.height * (target_width / logo.width))

    logo = logo.resize((target_width, target_height), Image.Resampling.LANCZOS)

    x = (1024 - target_width) // 2
    y = (1024 - target_height) // 2

    bg.paste(logo, (x, y), logo)
    bg.convert('RGB').save('assets/images/app_icon_centered.png')
    print("Successfully generated centered app icon.")

if __name__ == '__main__':
    main()
