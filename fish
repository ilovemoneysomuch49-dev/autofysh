import argparse
import sys
import time
from dataclasses import dataclass
from typing import Optional, Tuple

import cv2
import mss
import numpy as np
import pyautogui

try:
    import pygetwindow as gw
except Exception:  # pragma: no cover
    gw = None


pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0.01


@dataclass
class BotConfig:
    max_fish: int = 15
    fps: float = 20.0
    min_green_area: int = 1600
    min_red_area: int = 700
    min_button_area: int = 20000
    click_cooldown: float = 0.07
    fullscreen_key: str = "f11"


class AutoFyshBot:
    def __init__(self, config: BotConfig):
        self.config = config
        self.fish_caught = 0
        self.last_click = 0.0

    @staticmethod
    def _center(contour: np.ndarray) -> Tuple[int, int]:
        x, y, w, h = cv2.boundingRect(contour)
        return x + w // 2, y + h // 2

    @staticmethod
    def _largest_contour(mask: np.ndarray, min_area: int) -> Optional[np.ndarray]:
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        valid = [c for c in contours if cv2.contourArea(c) >= min_area]
        if not valid:
            return None
        return max(valid, key=cv2.contourArea)

    @staticmethod
    def _make_mask(hsv: np.ndarray, low: Tuple[int, int, int], high: Tuple[int, int, int]) -> np.ndarray:
        return cv2.inRange(hsv, np.array(low, dtype=np.uint8), np.array(high, dtype=np.uint8))

    def _find_green_target(self, hsv: np.ndarray) -> Optional[Tuple[int, int, int]]:
        green_mask = self._make_mask(hsv, (40, 90, 80), (90, 255, 255))

        kernel = np.ones((5, 5), np.uint8)
        green_mask = cv2.morphologyEx(green_mask, cv2.MORPH_OPEN, kernel)
        green_mask = cv2.morphologyEx(green_mask, cv2.MORPH_CLOSE, kernel)

        contour = self._largest_contour(green_mask, self.config.min_green_area)
        if contour is None:
            return None

        x, y, w, h = cv2.boundingRect(contour)
        area = w * h
        return x + w // 2, y + h // 2, area

    def _find_red_hook(self, hsv: np.ndarray) -> Optional[Tuple[int, int]]:
        red1 = self._make_mask(hsv, (0, 120, 70), (10, 255, 255))
        red2 = self._make_mask(hsv, (165, 120, 70), (179, 255, 255))
        red_mask = cv2.bitwise_or(red1, red2)

        contour = self._largest_contour(red_mask, self.config.min_red_area)
        if contour is None:
            return None

        return self._center(contour)

    def _click(self, x: int, y: int):
        now = time.time()
        if now - self.last_click < self.config.click_cooldown:
            return
        pyautogui.click(x, y)
        self.last_click = now

    def _focus_roblox(self):
        if gw is None:
            print("[AVISO] pygetwindow indisponível. Abra o Roblox manualmente em tela cheia.")
            return

        matches = [w for w in gw.getAllWindows() if w.title and "roblox" in w.title.lower()]
        if not matches:
            print("[AVISO] Janela do Roblox não encontrada. Continuando mesmo assim.")
            return

        roblox = matches[0]
        try:
            roblox.activate()
            time.sleep(0.2)
            pyautogui.press(self.config.fullscreen_key)
            print("[INFO] Janela do Roblox focada e comando de tela cheia enviado.")
        except Exception as exc:
            print(f"[AVISO] Não foi possível focar o Roblox automaticamente: {exc}")

    def run(self):
        self._focus_roblox()

        frame_delay = 1.0 / self.config.fps
        print("[INFO] Bot iniciado. Mova o mouse para o canto superior esquerdo para parar (failsafe).")

        with mss.mss() as sct:
            monitor = sct.monitors[1]

            while self.fish_caught < self.config.max_fish:
                start = time.time()
                raw = np.array(sct.grab(monitor))
                frame = cv2.cvtColor(raw, cv2.COLOR_BGRA2BGR)
                hsv = cv2.cvtColor(frame, cv2.COLOR_BGR2HSV)

                green = self._find_green_target(hsv)
                if green is not None:
                    gx, gy, area = green
                    self._click(gx, gy)

                    if area >= self.config.min_button_area and gy > int(frame.shape[0] * 0.6):
                        self.fish_caught += 1
                        print(f"[OK] Peixe capturado: {self.fish_caught}/{self.config.max_fish}")
                        time.sleep(0.35)
                else:
                    hook = self._find_red_hook(hsv)
                    if hook is not None:
                        hx, hy = hook
                        self._click(hx, hy)

                elapsed = time.time() - start
                if elapsed < frame_delay:
                    time.sleep(frame_delay - elapsed)

        print("[INFO] Limite atingido. Bot finalizado.")


def parse_args() -> BotConfig:
    parser = argparse.ArgumentParser(description="AutoFysh bot para Roblox (pesca automatizada).")
    parser.add_argument("--max-fish", type=int, default=15, help="Quantidade máxima de peixes.")
    parser.add_argument("--fps", type=float, default=20.0, help="Taxa de captura da tela.")
    args = parser.parse_args()

    return BotConfig(max_fish=max(1, args.max_fish), fps=max(5.0, args.fps))


if __name__ == "__main__":
    try:
        cfg = parse_args()
        bot = AutoFyshBot(cfg)
        bot.run()
    except pyautogui.FailSafeException:
        print("\n[INFO] FailSafe ativado. Bot encerrado.")
        sys.exit(0)
