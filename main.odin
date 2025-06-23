package main

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
  //r.multiline_fields = true
  //r.lazy_quotes = true
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

  CSVField :: struct {
    size: int,
    offset: int
  }

  csv_fields : #soa[dynamic]CSVField
  csv_field_strings : [dynamic]u8

  csv.reader_init(&r, os.stream_from_handle(handle))

  maxFieldLength :[dynamic]i32
  charSize :i32 = 32

  raylib.InitWindow(displayWidth, displayHeight, "CSV Viewer")

  append(&maxFieldLength, 0)
  for r, i in csv.iterator_next(&r) {
    for f, j in r {
      offset := len(csv_field_strings)
      append(&csv_field_strings, f)
      append(&csv_field_strings, 0)

      if len(maxFieldLength) <= j+1 {
        append(&maxFieldLength, 0)
      }

      if (j >= 0) {
        measured := cast(int)raylib.MeasureText(cast(cstring)(&csv_field_strings[offset]), charSize)
        maxFieldLength[j+1] = cast(i32)max(cast(int)maxFieldLength[j+1], measured)
      }
      append(&csv_fields, CSVField{len(f) + 1, offset})
    }
  }

  totalWidth :i32 = 0
  for m in maxFieldLength {
    totalWidth += m
  }

  grid_spacing := charSize
  fields_per_record := r.fields_per_record
  num_records := fields_per_record * r.line_count // this might be wrong for multiline CSVs?

  panelRec: raylib.Rectangle = {20, 20, cast(f32)displayWidth-100, cast(f32)displayHeight-100}
  panelContentRec :raylib.Rectangle = {
    0,
    0,
    cast(f32)totalWidth + cast(f32)(r.fields_per_record * cast(int)charSize * 3),
    cast(f32)(charSize*2*cast(i32)r.line_count)
  }
  panelView :raylib.Rectangle
  gridRect :raylib.Rectangle
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


    current_x_pos :i32 = cast(i32)panelRec.x + cast(i32)panelScroll.x

    for m in maxFieldLength[1:] {
      raylib.DrawRectangle(current_x_pos - 5,
                           cast(i32)panelRec.y + cast(i32)panelScroll.y,
                           3,
                           charSize * cast(i32)num_records,
                           raylib.BLACK)

      current_x_pos += cast(i32)panelRec.x + m + charSize*2
    }

    for i := 0; i < (num_records-fields_per_record); i += fields_per_record {
      col_num := 1
      rowOffset :i32 = cast(i32)i * charSize/2.0
      y_pos :i32 = 0

      current_x_pos :i32 = cast(i32)panelRec.x + cast(i32)panelScroll.x

      for j := i; j < (i+fields_per_record); j += 1 {
        csv_field : CSVField = csv_fields[j]

        f := cstring(&csv_field_strings[csv_field.offset])

        y_pos = cast(i32)panelRec.y + cast(i32)panelScroll.y + charSize + rowOffset


        raylib.DrawText(raylib.TextFormat("%s", f),
                        current_x_pos,
                        y_pos,
                        charSize,
                        raylib.RED)

        current_x_pos += cast(i32)panelRec.x + maxFieldLength[col_num] + charSize*2
        col_num += 1
      }

      raylib.DrawRectangle(cast(i32)panelRec.x,
                           y_pos + charSize + 1,
                           cast(i32)current_x_pos,
                           3,
                           raylib.BLACK)


    }
    raylib.EndScissorMode()

    raylib.EndDrawing()
  }
  raylib.CloseWindow()
}
