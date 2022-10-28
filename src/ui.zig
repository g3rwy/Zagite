const std = @import("std");

const rl = @cImport({
    @cInclude("raylib.h");
});

const Bound = struct { x: c_int, y: c_int, w:c_int, h:c_int  };

pub const Panel = struct {
    bound: Bound,
    color: rl.Color,
    parent: ?*anyopaque = null
};

pub fn draw(ui: anytype) void {
    switch (@TypeOf(ui)) {
        Panel => {
            rl.DrawRectangle(ui.bound.x, ui.bound.y, ui.bound.w, ui.bound.h, ui.color);   
        },
        
        else => {
            @compileError("Incorrect type used in drawing function\n");
        }        
    }
}

pub fn changeTransparency(color: *rl.Color, alpha:c_int) void {
    color.* = rl.ColorAlpha(color.*,@intToFloat(f32,alpha) / 255.0);
}