package main

import "core:strings"
import "core:fmt"
import "core:encoding/csv"
import "core:os"
import "vendor:raylib"
import "vendor:x11/xlib"

main :: proc() {
	r: csv.Reader
	r.trim_leading_space  = true
  r.reuse_record = true
  r.reuse_record_buffer = true
	defer csv.reader_destroy(&r)

  filename: string = "./test.csv"
  handle, err := os.open(filename)

  if err != nil {
    fmt.panicf("Could not open csv file: %v", filename)
  }

  defer os.close(handle)

  csv_fields : [dynamic]cstring

  csv.reader_init(&r, os.stream_from_handle(handle))

	for r, i in csv.iterator_next(&r) {
		for f, j in r {
      append(&csv_fields, strings.clone_to_cstring(f))
		}
	}


  display := xlib.OpenDisplay(nil)
  displayHeight := xlib.DisplayHeight(display, 0)
  displayWidth := xlib.DisplayWidth(display, 0)

  defer xlib.CloseDisplay(display)

  fields_per_record := r.fields_per_record
  num_fields := fields_per_record * r.line_count // this might be wrong for multiline CSVs?

  raylib.InitWindow(displayWidth, displayHeight, "CSV Viewer")

  baseColWidth :i32 = 10
  maxFieldLength :i32 = 0
  charSize :i32 = 20

  panelRec: raylib.Rectangle = {20, 20, cast(f32)displayWidth-100, cast(f32)displayHeight-100}
  panelContentRec :raylib.Rectangle = {0, 0, cast(f32)displayWidth, cast(f32)(charSize*4*cast(i32)r.line_count)}
  panelView :raylib.Rectangle
  panelScroll :raylib.Vector2 = {0, 0}

  for !raylib.WindowShouldClose() {
    raylib.BeginDrawing()
    raylib.ClearBackground(raylib.RAYWHITE)

    raylib.GuiScrollPanel(panelRec,
                          nil,
                          panelContentRec,
                          &panelScroll,
                          &panelView)

    raylib.BeginScissorMode(cast(i32)panelView.x,
                            cast(i32)panelView.y,
                            cast(i32)panelView.width,
                            cast(i32)panelView.height);

    for i := 0; i < (num_fields-fields_per_record); i += fields_per_record {
      col_num := 1
      rowOffset :i32 = cast(i32)i * charSize/2.0

      for j := i; j < (i+fields_per_record); j += 1 {
        f := csv_fields[j]
        maxFieldLength = cast(i32)max(cast(int)maxFieldLength,
                                      cast(int)raylib.MeasureText(f, charSize))


        raylib.DrawText(raylib.TextFormat("%s", f),
                        cast(i32)panelRec.x + cast(i32)panelScroll.x + (cast(i32)col_num) + (maxFieldLength * cast(i32)col_num*2),
                        cast(i32)panelRec.y + cast(i32)panelScroll.y + charSize + rowOffset,
                        charSize,
                        raylib.RED)
        col_num += 1
      }
    }
    raylib.EndScissorMode()

    raylib.EndDrawing()
  }
  raylib.CloseWindow()
}
