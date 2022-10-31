#include "raylib.h"
#include "microui.h"

static int text_width_c(mu_Font font, const char* text, int len) {
   return MeasureText(text,10);
}

static int text_height_c(mu_Font font) {
    return 10;
}
