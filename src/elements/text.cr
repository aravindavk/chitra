require "../pangocairo"

module Chitra
  struct Text < Element
    include ShapeProperties
    include TextProperties

    # :nodoc:
    def initialize(@txt : String, @x : Float64, @y : Float64)
    end

    # :nodoc:
    def draw(cairo_ctx)
      cairo_ctx.antialias = Cairo::Antialias::Best
      cairo_ctx.move_to(@x, @y)
      layout = LibPangoCairo.pango_cairo_create_layout(cairo_ctx)
      LibPangoCairo.pango_layout_set_text(layout, @txt, -1)
      desc = LibPangoCairo.pango_font_description_from_string("#{@font.family}, Bold #{@font.height}")
      LibPangoCairo.pango_layout_set_font_description(layout, desc)
      LibPangoCairo.pango_font_description_free(desc)
      LibPangoCairo.pango_cairo_update_layout(cairo_ctx, layout)
      LibPangoCairo.pango_cairo_show_layout(cairo_ctx, layout)
      LibPangoCairo.pango_cairo_layout_path(cairo_ctx, layout)
      draw_shape_properties(cairo_ctx)
    end

    # :nodoc:
    def to_s
      debug_text "text(#{@txt[0..6]}#{@txt.size > 7 ? ".." : ""}, #{@x}, #{@y})"
    end
  end

  struct TextBox < Element
    include ShapeProperties
    include TextProperties

    # :nodoc:
    def initialize(@txt : String, @x : Float64, @y : Float64, @w : Float64, @h : Float64)
    end

    # :nodoc:
    def draw(cairo_ctx)
      cairo_ctx.move_to(@x, @y)
      cairo_ctx.antialias = Cairo::Antialias::Best
      layout = LibPangoCairo.pango_cairo_create_layout(cairo_ctx)
      LibPangoCairo.pango_layout_set_width(layout, @w*LibPangoCairo::SCALE)
      LibPangoCairo.pango_layout_set_height(layout, @h*LibPangoCairo::SCALE)
      desc = LibPangoCairo.pango_font_description_from_string("#{@font.family}, #{@font.slant} #{@font.weight} #{@font.height}")
      LibPangoCairo.pango_layout_set_font_description(layout, desc)
      LibPangoCairo.pango_font_description_free(desc)
      LibPangoCairo.pango_layout_set_line_spacing(layout, @line_height)
      LibPangoCairo.pango_layout_set_wrap(layout, LibPangoCairo::WrapMode::WordChar)
      case @align
      when "justify" then LibPangoCairo.pango_layout_set_justify(layout, true)
      when "center"  then LibPangoCairo.pango_layout_set_alignment(layout, LibPangoCairo::Alignment::Center)
      when "right"   then LibPangoCairo.pango_layout_set_alignment(layout, LibPangoCairo::Alignment::Right)
      else
        LibPangoCairo.pango_layout_set_alignment(layout, LibPangoCairo::Alignment::Left)
      end

      txt = ""
      overflow_text = ""
      overflow = false
      @txt.each_grapheme do |letter|
        unless overflow
          LibPangoCairo.pango_layout_set_text(layout, txt + letter.to_s, -1)
          LibPangoCairo.pango_layout_get_size(layout, out w, out h)

          if h/LibPangoCairo::SCALE > @h
            overflow = true
          end
        end

        if overflow
          overflow_text += letter.to_s
        else
          txt += letter.to_s
        end
      end

      LibPangoCairo.pango_layout_set_text(layout, txt, -1)

      LibPangoCairo.pango_cairo_update_layout(cairo_ctx, layout)
      LibPangoCairo.pango_cairo_show_layout(cairo_ctx, layout)
      LibPangoCairo.pango_cairo_layout_path(cairo_ctx, layout)
      draw_shape_properties(cairo_ctx)

      overflow_text
    end

    # :nodoc:
    def to_s
      debug_text "text_box(#{@txt[0..6]}#{@txt.size > 7 ? ".." : ""}, #{@x}, #{@y}, #{@w}, #{@h})"
    end
  end

  class Context
    # Draw text for given x and y values.
    # ```
    # text "Hello World", 100, 100
    # ```
    def text(txt, x, y)
      t = Text.new(txt, x, y)
      idx = add_shape_properties(t)
      draw_on_default_surface(@elements[idx])
    end

    def text_box(txt, x, y, w, h)
      t = TextBox.new(txt, x, y, w, h)
      idx = add_shape_properties(t)

      overflow = draw_on_default_surface(@elements[idx])
      overflow.is_a?(String) ? overflow : ""
    end
  end
end
