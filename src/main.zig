const std = @import("std");
const ui = @import("ui.zig");

const rl = @cImport({
    @cInclude("raylib.h");
});


const V2 = struct {x: c_int, y: c_int};
const HEIGHT = 1000;
const WIDTH = 1000;

const HEIGHTf = 1000.0;
const WIDTHf  = 1000.0;

// For rendering grid and moving around in it
var grid_scale : f32 = 30.0;
var camera_center = rl.Vector2 { .x = 0.0, .y = 0.0 };
var grid_offset: f32 = undefined; // ( distance between two points on grid ) / 2

// Moving with mouse stuff
var mouse_point : V2 = .{.x=0 , .y=0};
var swap_vec : V2 = .{.x=0 , .y=0};
var saved_cam_center = rl.Vector2 { .x = 0.0, .y = 0.0 };

pub fn main() anyerror!void {
    var circ_pos = rl.Vector2 { .x = 0.0, .y = 0.0 };
    rl.InitWindow(WIDTH, HEIGHT, "SANDBOX ZIGATE");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();
    defer _ = gpa.deinit();
    
    
    rl.SetTargetFPS(120);
    grid_offset = @intToFloat(f32,@divFloor(GridToScreen(1,0).x - GridToScreen(0,0).x,2));

    var panel = ui.Panel{.bound = .{.x=0,.y=0,.w=300,.h=700},.color = rl.GRAY};
    ui.changeTransparency(&panel.color,45.0);

    while (! rl.WindowShouldClose())
    {
        
        const move_val = @log10(grid_scale / 4);
        if (rl.IsKeyDown(rl.KEY_RIGHT)) camera_center.x += move_val;
        
        if (rl.IsKeyDown(rl.KEY_LEFT))  camera_center.x -= move_val;
        
        if (rl.IsKeyDown(rl.KEY_UP))    camera_center.y -= move_val;
        
        if (rl.IsKeyDown(rl.KEY_DOWN))  camera_center.y += move_val;

        if (rl.IsKeyDown(rl.KEY_TAB)){
            camera_center.x = 0;
            camera_center.y = 0;
        }
        
        const scroll = rl.GetMouseWheelMove();
        if(scroll != 0){
            grid_scale = @max(@min(grid_scale + scroll,100.0),2.0);
            grid_offset = @intToFloat(f32,@divFloor(GridToScreen(1,0).x - GridToScreen(0,0).x,2)); // calculated with each change of zoom
        }

        rl.BeginDrawing();
            rl.ClearBackground(rl.BLACK);
            const circ_screen = GridToScreen(circ_pos.x, circ_pos.y); // FIXME again problems with adding in wrong segments
            rl.DrawCircle(circ_screen.x,circ_screen.y, 7,rl.RED);


            if(rl.IsMouseButtonPressed(1)){ // Counts once and saves where we started moving mouse
                mouse_point.x = rl.GetMouseX();
                mouse_point.y = rl.GetMouseY();
                saved_cam_center = camera_center;
            }

            if(rl.IsMouseButtonDown(1)){ // Active when right button is pressed and moves camera with it
                var mouse_now = V2{.x =  rl.GetMouseX(), .y =  rl.GetMouseY()};
                const diff = V2{.x = mouse_point.x - mouse_now.x, .y = mouse_point.y - mouse_now.y};
                
                camera_center.x = saved_cam_center.x + @intToFloat(f32,diff.x) / grid_scale;
                camera_center.y = saved_cam_center.y + @intToFloat(f32,diff.y) / grid_scale;
            }
            
            if(rl.IsMouseButtonDown(0)){ // Debug stuff, puts red circle on the closest grid index to the mouse
                const mouse_x = rl.GetMouseX();
                const mouse_y = rl.GetMouseY();
                const circ = ScreenToGrid(mouse_x,mouse_y);
                circ_pos.x = @intToFloat(f32,circ.x);
                circ_pos.y = @intToFloat(f32,circ.y);
            }
            
            DrawGrid();           
            ui.draw(panel);
               
            const string = try std.fmt.allocPrint(
                alloc,
                "{d:.2} , {d:.2}",
                .{ camera_center.x, camera_center.y },
            );

            try DrawTxt(string,alloc,10,10,24,rl.WHITE);
            alloc.free(string);
        rl.EndDrawing();
    }

    rl.CloseWindow();
}

fn ScreenToGrid(x:c_int,y:c_int) V2 {
    return V2{.x = @floatToInt(c_int,(@intToFloat(f32,x) - 500.0 + (if(x < 500) -grid_offset else grid_offset)) / grid_scale + camera_center.x),.y = @floatToInt(c_int,(@intToFloat(f32,y) - 500.0 + (if(y > 500) grid_offset else -grid_offset)) / grid_scale + camera_center.y)};
}

fn GridToScreen(x:f32,y:f32) V2 {
    return V2{.x = @floatToInt(c_int,(x - camera_center.x) * grid_scale + 500.0) ,.y = @floatToInt(c_int,(y - camera_center.y) * grid_scale + 500.0) };
}

fn DrawTxt(text: []const u8, alloc:std.mem.Allocator, posx: c_int, posy: c_int, size: c_int, color: rl.Color) !void {
    const nulled = try std.cstr.addNullByte(alloc,text);
    defer alloc.free(nulled);
    rl.DrawText(nulled.ptr,posx,posy,size,color);
}

fn DrawGrid() void{
    const min_bound = ScreenToGrid(0,0);
    const max_bound = ScreenToGrid(WIDTH,HEIGHT);
    
     
    var y: c_int = min_bound.y;
    while(y < max_bound.y) : (y += 1){
        var x: c_int = min_bound.x;
         while(x < max_bound.x) : (x += 1){
            const posx = @floatToInt(c_int,(@intToFloat(f32,x) - camera_center.x)*grid_scale + 500.0);
            const posy = @floatToInt(c_int,(@intToFloat(f32,y) - camera_center.y)*grid_scale + 500.0);

            rl.DrawPixel(posx, posy, rl.RAYWHITE);
        }
    }
}
