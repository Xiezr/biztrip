"""
生成 biztrip APP 图标：白色背景 + 圆润日历飞机图标
输出到 android/app/src/main/res/mipmap-*/ic_launcher.png
"""
import os
from PIL import Image, ImageDraw

# 各级分辨率配置
SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES_DIR = os.path.join(BASE_DIR, "android", "app", "src", "main", "res")

PRIMARY = (26, 86, 219)       # #1A56DB 主色
WHITE = (255, 255, 255)
LIGHT_BLUE = (219, 234, 254)  # #DBEAFE 浅蓝背景

def draw_icon(draw, size, scale):
    """在 draw 对象上绘制图标"""
    r = size / 2
    cx, cy = size / 2, size / 2
    
    # 1. 白色圆形背景
    margin = scale * 2
    draw.ellipse(
        [margin, margin, size - margin, size - margin],
        fill=WHITE,
        outline=LIGHT_BLUE,
        width=max(1, int(scale * 2))
    )
    
    # 2. 日历主体（圆角矩形）
    pad_x = size * 0.22
    pad_y = size * 0.18
    cal_w = size - 2 * pad_x
    cal_h = size - 2 * pad_y
    cal_top = pad_y
    
    # 日历圆角半径
    cal_radius = int(scale * 5)
    draw.rounded_rectangle(
        [pad_x, cal_top, pad_x + cal_w, cal_top + cal_h],
        radius=cal_radius,
        fill=LIGHT_BLUE
    )
    
    # 3. 日历头部（深色横条）
    header_h = cal_h * 0.22
    # 只画上半部分圆角（用两个矩形拼合）
    draw.rounded_rectangle(
        [pad_x, cal_top, pad_x + cal_w, cal_top + header_h + cal_radius],
        radius=cal_radius,
        fill=PRIMARY
    )
    # 覆盖下半部分让它变成直角
    draw.rectangle(
        [pad_x, cal_top + header_h, pad_x + cal_w, cal_top + header_h + cal_radius],
        fill=PRIMARY
    )
    
    # 4. 日历日期数字
    num_size = int(scale * 8)
    num_x = pad_x + cal_w * 0.35
    num_y = cal_top + header_h + cal_h * 0.15
    try:
        from PIL import ImageFont
        font_paths = [
            "C:\\Windows\\Fonts\\arialbd.ttf",
            "C:\\Windows\\Fonts\\arial.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
        ]
        font = None
        for fp in font_paths:
            if os.path.exists(fp):
                font = ImageFont.truetype(fp, num_size)
                break
        if font:
            draw.text((num_x, num_y), "17", fill=PRIMARY, font=font)
        else:
            draw.text((num_x, num_y), "17", fill=PRIMARY)
    except Exception:
        draw.text((num_x, num_y), "17", fill=PRIMARY)
    
    # 5. 飞机小图标（右下角）
    plane_x = pad_x + cal_w * 0.5
    plane_y = cal_top + header_h + cal_h * 0.42
    plane_s = scale * 10
    
    # 简化飞机形状：用线条
    pw = plane_s
    draw.line(
        [plane_x, plane_y + plane_s * 0.5, plane_x + pw, plane_y + plane_s * 0.5],
        fill=PRIMARY, width=max(1, int(scale * 1.5))
    )
    # 机翼
    draw.line(
        [plane_x + pw * 0.3, plane_y + plane_s * 0.5, plane_x + pw * 0.45, plane_y],
        fill=PRIMARY, width=max(1, int(scale * 1.2))
    )
    draw.line(
        [plane_x + pw * 0.3, plane_y + plane_s * 0.5, plane_x + pw * 0.45, plane_y + plane_s],
        fill=PRIMARY, width=max(1, int(scale * 1.2))
    )
    # 尾翼
    draw.line(
        [plane_x + pw * 0.8, plane_y + plane_s * 0.5, plane_x + pw, plane_y + plane_s * 0.2],
        fill=PRIMARY, width=max(1, int(scale * 1.2))
    )
    draw.line(
        [plane_x + pw * 0.8, plane_y + plane_s * 0.5, plane_x + pw, plane_y + plane_s * 0.8],
        fill=PRIMARY, width=max(1, int(scale * 1.2))
    )


def generate():
    for folder, size_px in SIZES.items():
        folder_path = os.path.join(RES_DIR, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        # 创建高清画布（2x 渲染后缩放到目标尺寸，抗锯齿）
        render_scale = 4
        render_size = size_px * render_scale
        img = Image.new("RGBA", (render_size, render_size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        draw_icon(draw, render_size, render_size / 48.0)
        
        # 缩放到目标尺寸
        img = img.resize((size_px, size_px), Image.LANCZOS)
        
        output_path = os.path.join(folder_path, "ic_launcher.png")
        img.save(output_path, "PNG")
        print(f"  {folder}: {size_px}x{size_px} -> {output_path}")


if __name__ == "__main__":
    print("生成 biztrip APP 图标...")
    generate()
    print("完成！")
