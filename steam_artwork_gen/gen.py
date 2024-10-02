import sys, argparse, numpy as np, subprocess
from PIL import Image, ImageDraw, ImageFont
from moviepy.editor import ImageSequenceClip, VideoFileClip

# MIT - 2024 koutsie
# see what the (an...) end result looks like at
# https://steamcommunity.com/id/koutsie
# this is a bit redundant as moviepy is shit but...
# i am lazy to write os.run calls to ffmpeg lol
# patches welcome to use ffmpeg instead - please
# just follow the black formatting guide when
# sending in patches
# 👍


def parseargs():
    parser = argparse.ArgumentParser(
        description="generate steam 'Artwork_Middle' for your profile with some waving text \n see https://git.sr.ht/~koutsie/scripts for more info"
    )
    parser.add_argument(
        "--bggif",
        default="Artwork_Middle.gif",
        help="background gif path (grab this from ht    tps://steam.design/ - you can download all your artwork from there but care about Artowkr_Middle.gif only)",
    )
    parser.add_argument("--text", default="koutsie", help="text animate")
    parser.add_argument("--fontsize", type=int, default=72, help="font size")
    parser.add_argument(
        "--fontpath",
        default="BungeeTint-Regular.ttf",
        help="font path (can we current folder)",
    )
    parser.add_argument(
        "--amplitude",
        type=float,
        default=6,
        help="wave amplitude (how far the wave... waves)",
    )
    parser.add_argument(
        "--wavespeed",
        type=float,
        default=1.0,
        help="wave speed (how fast that wave happens)",
    )
    parser.add_argument("--textcolor", default="white", help="text color")
    parser.add_argument(
        "--output",
        default="Artwork_Middle_Generated.gif",
        help="output gif name (default is Artwork_Middle_Generated.gif)",
    )
    parser.add_argument(
        "--compression",
        type=int,
        default=80,
        help="compression level (0-100) (default uses 80 compression if gifsicle is found on system)",
    )
    parser.add_argument(
        "--colors",
        type=int,
        default=256,
        help="number of colors in the output gif (default is 256)",
    )
    return parser.parse_args()


def gifinfo(gifpath):
    with Image.open(gifpath) as img:
        width, height = img.size
        nframes = duration = 0
        while True:
            try:
                duration += img.info["duration"]
                nframes += 1
                img.seek(img.tell() + 1)
            except EOFError:
                break
    fps = nframes / (duration / 1000)
    print(
        f"gif info: {width}x{height}, {nframes} frames, {fps:.2f} fps, {duration / 1000:.2f}s"
    )
    return width, height, nframes, fps, duration / 1000


def makeframe(t, bgframe, width, height, font, wavefunc, text, textcolor):
    img = Image.fromarray(bgframe)
    draw = ImageDraw.Draw(img)
    totalwidth = sum(draw.textbbox((0, 0), char, font=font)[2] for char in text)
    x, yoffset = (width - totalwidth) // 2, (height - font.size) // 2
    for i, char in enumerate(text):
        draw.text((x, yoffset + int(wavefunc(t, i))), char, font=font, fill=textcolor)
        x += draw.textbbox((0, 0), char, font=font)[2]
    return np.array(img)


def compressgif(inputpath, outputpath, compressionlevel, colors):
    try:
        subprocess.run(
            [
                "gifsicle",
                "-O3",
                f"--lossy={compressionlevel}",
                "-k",
                str(colors),
                "-o",
                outputpath,
                inputpath,
            ],
            check=True,
        )
        print("compression complete using gifsicle.")
    except subprocess.CalledProcessError:
        print("error occurred while compressing with gifsicle??")
    except FileNotFoundError:
        print("gifsicle not found. make sure it's installed and in your path.")


def main():
    args = parseargs()
    print("steam artwork middle is now being cooked...")
    width, height, nframes, fps, duration = gifinfo(args.bggif)
    font = ImageFont.truetype(args.fontpath, args.fontsize)
    wavefunc = lambda t, i: args.amplitude * np.sin(
        2 * np.pi * (args.wavespeed * t + i / len(args.text)) + np.pi / len(args.text)
    )

    with VideoFileClip(args.bggif) as bgclip:
        print("generating image frames...")
        frames = [
            makeframe(
                i / fps, frame, width, height, font, wavefunc, args.text, args.textcolor
            )
            for i, frame in enumerate(bgclip.iter_frames())
        ]
        print(f"generated {len(frames)} frames")

    print("packaging into a gif...")
    ImageSequenceClip(frames, fps=fps).write_gif(args.output, fps=fps)

    print("attempting to compress gif...")
    compressgif(args.output, args.output, args.compression, args.colors)

    print(f"artwork animation complete! check '{args.output}' for the result.")


if __name__ == "__main__":
    main()
