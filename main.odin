package main

import "core:strings"
import "core:fmt"
import "core:encoding/csv"
import "core:os"
import "vendor:raylib"

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

  for f in csv_fields {
		fmt.printfln("field: %v", f)
  }

  fields_per_record := r.fields_per_record
  num_fields := fields_per_record * r.line_count // this might be wrong for multiline CSVs?

  screenWidth :i32 = 800
  screenHeight :i32 = 800
  raylib.InitWindow(screenWidth, screenHeight, "CSV Viewer")

  baseColWidth :i32 = 100
  maxFieldLength :i32 = 0
  charSize :i32 = 20

  for !raylib.WindowShouldClose() {
    raylib.BeginDrawing()
    raylib.ClearBackground(raylib.RAYWHITE)


    for i := 0; i < (num_fields-fields_per_record); i += (fields_per_record) {
      col_num := 1
      for j := i; j < (i+fields_per_record); j += 1 {
        f := csv_fields[j]
        maxFieldLength = cast(i32)max(cast(int)maxFieldLength,
                                      cast(int)raylib.MeasureText(f, charSize))

        raylib.DrawText(raylib.TextFormat("%s", f),
                        (baseColWidth)*(cast(i32)col_num) + (maxFieldLength * cast(i32)col_num),
                        (cast(i32)i+1)*charSize,
                        charSize,
                        raylib.RED)
        col_num += 1
      }
    }

    raylib.EndDrawing()
  }
  raylib.CloseWindow()
}
