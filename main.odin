package main

import "core:strings"
import "core:fmt"
import "core:encoding/csv"
import "core:os"
import "vendor:raylib"
import "vendor:x11/xlib"

main :: proc() {
  display := xlib.OpenDisplay(nil)
  displayHeight := xlib.DisplayHeight(display, 0)
  displayWidth := xlib.DisplayWidth(display, 0)

  defer xlib.CloseDisplay(display)

	r: csv.Reader
	r.trim_leading_space  = true
  r.reuse_record = true
  r.reuse_record_buffer = true
	defer csv.reader_destroy(&r)

  if len(os.args) < 2 {
    fmt.panicf("Must pass in the name of a csv file, e.g. ./csv_viewer foo.csv")
  }
  filename: string = os.args[1]

  handle, err := os.open(filename)

  if err != nil {
    fmt.panicf("Could not open csv file: %v", filename)
  }

  defer os.close(handle)

  csv_fields : [dynamic]cstring

  csv.reader_init(&r, os.stream_from_handle(handle))

  maxFieldLength :[dynamic]i32
  charSize :i32 = 20

  raylib.InitWindow(displayWidth, displayHeight, "CSV Viewer")

	for r, i in csv.iterator_next(&r) {
		for f, j in r {
      cloned_st := strings.clone_to_cstring(f)
      append(&csv_fields, cloned_st)

      if len(maxFieldLength) <= j {
        append(&maxFieldLength, 0)
      }

      maxFieldLength[j] = cast(i32)max(cast(int)maxFieldLength[j],
                                       cast(int)raylib.MeasureText(cloned_st, charSize))

      assert(maxFieldLength[j] > 0)
		}
	}

  fields_per_record := r.fields_per_record
  num_fields := fields_per_record * r.line_count // this might be wrong for multiline CSVs?

  baseColWidth :i32 = 10

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

      current_x_pos :i32 = 0
      for j := i; j < (i+fields_per_record); j += 1 {
        f := csv_fields[j]
        current_x_pos += cast(i32)panelRec.x + cast(i32)panelScroll.x + maxFieldLength[col_num-1] * cast(i32)col_num
        y_pos := cast(i32)panelRec.y + cast(i32)panelScroll.y + charSize + rowOffset

        raylib.DrawText(raylib.TextFormat("%s", f),
                        current_x_pos,
                        y_pos,
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
