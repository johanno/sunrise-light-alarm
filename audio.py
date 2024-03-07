import sys

from pydub import AudioSegment
from pydub.playback import play


def play_audio(file_path: str):
    audio = AudioSegment.from_file(file_path)
    play(audio)


if __name__ == "__main__":
    play_audio(sys.argv[1])
