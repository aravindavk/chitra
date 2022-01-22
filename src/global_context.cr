require "./chitra"

module Chitra
  class_property global_context = Context.new
end

FUNCS = %w[width height enable_debug]

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
def size(w, h)
  Chitra.global_context = Chitra::Context.new(w, h)
end
