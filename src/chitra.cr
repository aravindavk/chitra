require "./context"

module Chitra
  class_property global_context = Context.new
end

FUNCS = %w[width height enable_debug fill no_fill stroke
  stroke_width save new_drawing rect oval line
  line_dash line_cap line_join translate rotate scale
  polygon background no_stroke font font_size text text_box
  hyphenation hyphen_char text_align line_height point
  save_state restore_state fill_opacity stroke_opacity
  image new_page group_start group_end composite markup
  markup_box rainbow rainbow_box image_width image_height
  image_size font_weight
]

# Define the above global functions
# by calling equivalant context functions
{% begin %}
  {% for name, index in FUNCS %}
    def {{name.id}}(*args, **kwargs)
      Chitra.global_context.{{name.id}}(*args, **kwargs)
    end
  {% end %}
{% end %}

# Set the size and initialize the drawing surface
# ```
# #    width height
# size 1600, 900
# ```
def size(w, h = 0)
  Chitra.global_context = Chitra::Context.new(w, h)
  Chitra.global_context.enable_debug if Chitra.global_context.debug?
end

# Set the size and initialize the drawing surface
# ```
# #    paper
# size "A4"
# size "A4,landscape"
# size "A4,portrait"
# ```
def size(paper : String)
  Chitra.global_context = Chitra::Context.new(paper)
  Chitra.global_context.enable_debug if Chitra.global_context.debug?
end

# Draw with the state changes that
# don't change the Global state
# ```
# # Set Fill color Red
# ctx.fill 1, 0, 0
# ctx.saved_state do
#   # Change the fill color to Blue
#   ctx.fill 0, 0, 1
#   ctx.rect 100, 100, 200, 200
# end
# # Draw rect with the fill color set previously
# ctx.rect 200, 200, 200, 200
# ```
def saved_state(&block)
  Chitra.global_context.saved_state(&block)
end

# Create group for composite drawings.
# ```
# ctx.grouped do
#   ctx.rect 10, 10, 100, 100
#   ctx.composite "In"
#   ctx.rect 50, 50, 100, 100
# end
# ```
def grouped(&block)
  Chitra.global_context.grouped(&block)
end

# Set resolution
# Default value is 72 ppi
# ```
# resolution 300
# size 297.mm, 210.mm
# rect 10.mm, 10.mm, 500
# ```
def resolution(val)
  Chitra.resolution val
end
