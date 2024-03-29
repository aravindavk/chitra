require "./helpers"
require "./surfaces/*"
require "./elements/*"
require "./paper_sizes"

module Chitra
  class Context
    include ShapeProperties
    include TextProperties

    property size = Size.new
    property? debug = false

    # Get width of the canvas
    # ```
    # #                         width height
    # ctx = Chitra.new 1600, 900
    # puts ctx.width # 1600
    # ```
    def width
      @size.width
    end

    # Get height of the canvas
    # ```
    # #                         width height
    # ctx = Chitra.new 1600, 900
    # puts ctx.height # 900
    # ```
    def height
      @size.height
    end

    def elements
      @elements
    end

    # :nodoc:
    def initialize
      @output_file = ""
      @out_ext = ""
      @output_type = ""
      @elements = [] of Element
      surface = LibCairo.cairo_image_surface_create(LibCairo::FormatT::ARGB32, @size.width, @size.height)
      @default_cairo_ctx = LibCairo.cairo_create surface
      @current_saved_context = State.new(@size.width, @size.height)
    end

    # :nodoc:
    def initialize(w : Number, h : Number = 0)
      h = w if h == 0

      @size.width = w.round_even.to_i
      @size.height = h.round_even.to_i
      initialize
    end

    # :nodoc:
    def initialize(paper : String)
      paper_name, _sep, mode = paper.downcase.partition(",")
      paper_name = paper_name.strip
      mode = mode.strip

      unless PAPER_SIZES[paper_name]?
        raise Exception.new("Invalid paper size specified")
      end

      w, h = PAPER_SIZES[paper_name]
      if mode.starts_with?("land") || mode.starts_with?("port")
        if mode.starts_with?("land") && h > w
          w, h = h, w
        end
      end

      @size.width = w.mm.round_even.to_i
      @size.height = h.mm.round_even.to_i
      initialize
    end

    # Enable debug messages to verify if any
    # property applied to an element is not maching
    # ```
    # ctx = Chitra.new
    # ctx.enable_debug
    # ```
    def enable_debug
      @debug = true
    end

    private def get_surface(out_ext)
      # Macro to add switch cases for each available surfaces
      {% begin %}
        case "Chitra::#{out_ext.titleize}Surface"
            {% for name in Surface.subclasses %}
            when {{ name.stringify }}
              {{ name }}.new(@output_file, @size.width, @size.height)
            {% end %}
        else
          nil
        end
      {% end %}
    end

    private def available_surfaces
      surfaces = [] of String
      {% begin %}
        {% for name in Surface.subclasses %}
          surfaces << {{ name.stringify.underscore.split("_")[0].downcase.gsub(/chitra::/, "") }}
        {% end %}
      {% end %}

      surfaces
    end

    # Save the output to a file.
    # ```
    # ctx = Chitra.new
    # #        filename
    # ctx.save "hello.png"
    # ```
    def save(file)
      @output_file = file
      return if @output_file == ""

      _base, _sep, out_ext = @output_file.rpartition(".")

      surface = get_surface(out_ext.downcase)
      if surface.nil?
        raise Exception.new("Unknown output file format. Supported formats: #{available_surfaces.join(",")}")
      end

      cairo_ctx = LibCairo.cairo_create surface.surface

      @elements.each do |ele|
        puts ele.to_s if @debug
        ele.draw(cairo_ctx)
      end

      surface.draw
    end

    # Reset the drawing to clean and empty canvas
    # ```
    # ctx = Chitra.new
    # ctx.fill 0
    # ctx.rect 0, 0, width, height
    # ctx.save "slide1.png"
    # ctx.new_drawing
    # ctx.fill 0, 0, 1
    # ctx.rect 0, 0, width, height
    # ctx.save "slide2.png"
    # ```
    def new_drawing
      @elements = [] of Element
      surface = LibCairo.cairo_image_surface_create(LibCairo::FormatT::ARGB32, @size.width, @size.height)
      @default_cairo_ctx = LibCairo.cairo_create surface
      reset_text_properties
      reset_shape_properties
    end
  end

  # Initialize the Chitra drawing Context with default surface size
  # ```
  # ctx = Chitra.new
  # ```
  def self.new
    Context.new
  end

  # Initialize the Chitra drawing Context
  # ```
  # #                width height
  # ctx = Chitra.new 1600, 900
  # ```
  def self.new(w, h = 0)
    Context.new(w, h)
  end
end
