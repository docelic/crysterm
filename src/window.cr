require "./app"
require "./macros"
require "./widget"

module Crysterm
  # Represents a window. `Window` and `Element` are two lowest-level classes after `EventEmitter` and `Node`.
  class Window
    module Angles
      @angles = {
        '\u2518' => true, # '┘'
        '\u2510' => true, # '┐'
        '\u250c' => true, # '┌'
        '\u2514' => true, # '└'
        '\u253c' => true, # '┼'
        '\u251c' => true, # '├'
        '\u2524' => true, # '┤'
        '\u2534' => true, # '┴'
        '\u252c' => true, # '┬'
        '\u2502' => true, # '│'
        '\u2500' => true, # '─'
      }

      @langles = {
        '\u250c' => true, # '┌'
        '\u2514' => true, # '└'
        '\u253c' => true, # '┼'
        '\u251c' => true, # '├'
        '\u2534' => true, # '┴'
        '\u252c' => true, # '┬'
        '\u2500' => true, # '─'
      }

      @uangles = {
        '\u2510' => true, # '┐'
        '\u250c' => true, # '┌'
        '\u253c' => true, # '┼'
        '\u251c' => true, # '├'
        '\u2524' => true, # '┤'
        '\u252c' => true, # '┬'
        '\u2502' => true, # '│'
      }

      @rangles = {
        '\u2518' => true, # '┘'
        '\u2510' => true, # '┐'
        '\u253c' => true, # '┼'
        '\u2524' => true, # '┤'
        '\u2534' => true, # '┴'
        '\u252c' => true, # '┬'
        '\u2500' => true, # '─'
      }

      @dangles = {
        '\u2518' => true, # '┘'
        '\u2514' => true, # '└'
        '\u253c' => true, # '┼'
        '\u251c' => true, # '├'
        '\u2524' => true, # '┤'
        '\u2534' => true, # '┴'
        '\u2502' => true, # '│'
      }

      # Every ACS angle character can be
      # represented by 4 bits ordered like this:
      # [langle][uangle][rangle][dangle]
      @angle_table = {
         0 => ' ',      # ?               "0000"
         1 => '\u2502', # '│' # ?   '0001'
         2 => '\u2500', # '─' # ??  '0010'
         3 => '\u250c', # '┌'       '0011'
         4 => '\u2502', # '│' # ?   '0100'
         5 => '\u2502', # '│'       '0101'
         6 => '\u2514', # '└'       '0110'
         7 => '\u251c', # '├'       '0111'
         8 => '\u2500', # '─' # ??  '1000'
         9 => '\u2510', # '┐'       '1001'
        10 => '\u2500', # '─' # ??  '1010'
        11 => '\u252c', # '┬'       '1011'
        12 => '\u2518', # '┘'       '1100'
        13 => '\u2524', # '┤'       '1101'
        14 => '\u2534', # '┴'       '1110'
        15 => '\u253c', # '┼'       '1111'
      }

      def _get_angle(lines, x, y)
        angle = 0
        attr = lines[y][x].attr
        ch = lines[y][x].char

        if (lines[y][x - 1]? && @langles[lines[y][x - 1].char]?)
          if (!@ignore_dock_contrast)
            if (lines[y][x - 1].attr != attr)
              return ch
            end
          end
          angle |= 1 << 3
        end

        if (lines[y - 1]? && @uangles[lines[y - 1][x].char]?)
          if (!@ignore_dock_contrast)
            if (lines[y - 1][x].attr != attr)
              return ch
            end
          end
          angle |= 1 << 2
        end

        if (lines[y][x + 1]? && @rangles[lines[y][x + 1].char]?)
          if (!@ignore_dock_contrast)
            if (lines[y][x + 1].attr != attr)
              return ch
            end
          end
          angle |= 1 << 1
        end

        if (lines[y + 1]? && @dangles[lines[y + 1][x].char]?)
          if (!@ignore_dock_contrast)
            if (lines[y + 1][x].attr != attr)
              return ch
            end
          end
          angle |= 1 << 0
        end

        # Experimental: fixes this situation:
        # +----------+
        #            | <-- empty space here, should be a T angle
        # +-------+  |
        # |       |  |
        # +-------+  |
        # |          |
        # +----------+
        # if (uangles[lines[y][x][1]])
        #   if (lines[y + 1] && cdangles[lines[y + 1][x][1]])
        #     if (!@options.ignoreDockContrast)
        #       if (lines[y + 1][x][0] != attr) return ch
        #     }
        #     angle |= 1 << 0
        #   }
        # }

        @angle_table[angle]? || ch
      end
    end

    module Attributes
      # Convert an SGR string to our own attribute format.
      def attr_code(code, cur, dfl)
        flags = (cur >> 18) & 0x1ff
        fg = (cur >> 9) & 0x1ff
        bg = cur & 0x1ff
        # c
        # i

        code = code[2...-1].split(';')
        if (!code[0]? || code[0].empty?)
          code[0] = "0"
        end

        (0..code.size).each do |i|
          c = !code[i].empty? ? code[i].to_i : 0
          case c
          when 0 # normal
            bg = dfl & 0x1ff
            fg = (dfl >> 9) & 0x1ff
            flags = (dfl >> 18) & 0x1ff
            break
          when 1 # bold
            flags |= 1
            break
          when 22
            flags = (dfl >> 18) & 0x1ff
            break
          when 4 # underline
            flags |= 2
            break
          when 24
            flags = (dfl >> 18) & 0x1ff
            break
          when 5 # blink
            flags |= 4
            break
          when 25
            flags = (dfl >> 18) & 0x1ff
            break
          when 7 # inverse
            flags |= 8
            break
          when 27
            flags = (dfl >> 18) & 0x1ff
            break
          when 8 # invisible
            flags |= 16
            break
          when 28
            flags = (dfl >> 18) & 0x1ff
            break
          when 39 # default fg
            fg = (dfl >> 9) & 0x1ff
            break
          when 49 # default bg
            bg = dfl & 0x1ff
            break
          when 100 # default fg/bg
            fg = (dfl >> 9) & 0x1ff
            bg = dfl & 0x1ff
            break
          else # color
            if (c == 48 && code[i + 1].to_i == 5)
              i += 2
              bg = code[i].to_i
              break
            elsif (c == 48 && code[i + 1].to_i == 2)
              i += 2
              bg = Colors.match(code[i].to_i, code[i + 1].to_i, code[i + 2].to_i)
              if (bg == -1)
                bg = dfl & 0x1ff
              end
              i += 2
              break
            elsif (c == 38 && code[i + 1].to_i == 5)
              i += 2
              fg = code[i].to_i
              break
            elsif (c == 38 && code[i + 1].to_i == 2)
              i += 2
              fg = Colors.match(code[i].to_i, code[i + 1].to_i, code[i + 2].to_i)
              if (fg == -1)
                fg = (dfl >> 9) & 0x1ff
              end
              i += 2
              break
            end
            if (c >= 40 && c <= 47)
              bg = c - 40
            elsif (c >= 100 && c <= 107)
              bg = c - 100
              bg += 8
            elsif (c == 49)
              bg = dfl & 0x1ff
            elsif (c >= 30 && c <= 37)
              fg = c - 30
            elsif (c >= 90 && c <= 97)
              fg = c - 90
              fg += 8
            elsif (c == 39)
              fg = (dfl >> 9) & 0x1ff
            elsif (c == 100)
              fg = (dfl >> 9) & 0x1ff
              bg = dfl & 0x1ff
            end
            break
          end
        end

        (flags << 18) | (fg << 9) | bg
      end

      # Convert our own attribute format to an SGR string.
      def code_attr(code)
        flags = (code >> 18) & 0x1ff
        fg = (code >> 9) & 0x1ff
        bg = code & 0x1ff
        outbuf = ""

        # bold
        if ((flags & 1) != 0)
          outbuf += "1;"
        end

        # underline
        if ((flags & 2) != 0)
          outbuf += "4;"
        end

        # blink
        if ((flags & 4) != 0)
          outbuf += "5;"
        end

        # inverse
        if ((flags & 8) != 0)
          outbuf += "7;"
        end

        # invisible
        if ((flags & 16) != 0)
          outbuf += "8;"
        end

        if (bg != 0x1ff)
          bg = _reduce_color(bg)
          if (bg < 16)
            if (bg < 8)
              bg += 40
            else # elsif (bg < 16)
              bg -= 8
              bg += 100
            end
            outbuf += "#{bg};"
          else
            outbuf += "48;5;#{bg};"
          end
        end

        if (fg != 0x1ff)
          fg = _reduce_color(fg)
          if (fg < 16)
            if (fg < 8)
              fg += 30
            else # elsif (fg < 16)
              fg -= 8
              fg += 90
            end
            outbuf += "#{fg};"
          else
            outbuf += "38;5;#{fg};"
          end
        end

        if (outbuf[-1] == ";")
          outbuf = outbuf[0...-1]
        end

        "\x1b[#{outbuf}m"
      end
    end

    class Cell
      include Comparable(self)
      # Same as @dattr
      property attr : Int32 = ((0 << 18) | (0x1ff << 9)) | 0x1ff
      property char : Char = ' '

      def initialize(@attr, @char)
      end

      def initialize(@char)
      end

      def initialize
      end

      def <=>(other : Cell)
        if (d = @attr <=> other.attr) == 0
          @char <=> other.char
        else
          d
        end
      end

      def <=>(other : Tuple(Int32, Char))
        if (d = @attr <=> other[0]) == 0
          @char <=> other[1]
        else
          d
        end
      end
    end

    class Row < Array(Cell)
      property dirty = false

      def initialize
        super
      end

      def initialize(width, cell : Cell | Tuple(Int32, Char) = {@attr, @char})
        super width
      end
    end

    module Cursor
      include Macros
      getter cursor = Tput::Namespace::Cursor.new

      def cursor_shape(shape : Tput::CursorShape = Tput::CursorShape::Block, blink : Bool = false)
        @cursor.shape = shape
        @cursor.blink = blink
        @cursor._set = true

        if @cursor.artificial
          raise "Not supported yet"
          # if !app.hide_cursor_old
          #  hide_cursor = app.hide_cursor
          #  app.tput.hide_cursor_old = app.hide_cursor
          #  app.tput.hide_cursor = ->{
          #    hide_cursor.call(application)
          #    @cursor._hidden = true
          #    if (@renders > 0)
          #      render
          #    end
          #  }
          # end
          # if (!app.showCursor_old)
          #  var showCursor = app.showCursor
          #  app.showCursor_old = app.showCursor
          #  app.showCursor = function()
          #    self.cursor._hidden = false
          #    if (app._exiting) showCursor.call(application)
          #    if (self.renders) self.render()
          #  }
          # end
          # if (!@_cursorBlink)
          #  @_cursorBlink = setInterval(function()
          #    if (!self.cursor.blink) return
          #    self.cursor._state ^= 1
          #    if (self.renders) self.render()
          #  }, 500)
          #  if (@_cursorBlink.unref)
          #    @_cursorBlink.unref()
          #  end
          # end
          return true
        end

        app.tput.cursor_shape @cursor.shape, @cursor.blink
      end

      def cursor_color(color : Tput::Color? = nil)
        @cursor.color = color.try do |c|
          Tput::Color.new Colors.convert(c.value)
        end
        @cursor._set = true

        if (@cursor.artificial)
          return true
        end

        # TODO probably this isn't fully right
        app.tput.cursor_color(@cursor.color.to_s.downcase)
      end

      def cursor_reset
        @cursor = Tput::Namespace::Cursor.new
        # TODO if artificial cursor

        app.tput.cursor_reset
      end

      alias_previous reset_cursor

      def _cursor_attr(cursor, dattr = nil)
        attr = dattr || @dattr
        # cattr
        # ch
        if (cursor.shape == Tput::CursorShape::Line)
          attr &= ~(0x1ff << 9)
          attr |= 7 << 9
          ch = '\u2502'
        elsif (cursor.shape == Tput::CursorShape::Underline)
          attr &= ~(0x1ff << 9)
          attr |= 7 << 9
          attr |= 2 << 18
        elsif (cursor.shape == Tput::CursorShape::Block)
          attr &= ~(0x1ff << 9)
          attr |= 7 << 9
          attr |= 8 << 18
        elsif (cursor.shape)
          # TODO
          # cattr = Element.sattr(cursor, cursor.shape)
          # if (cursor.shape.bold || cursor.shape.underline ||
          #    cursor.shape.blink || cursor.shape.inverse ||
          #    cursor.shape.invisible)
          #  attr &= ~(0x1ff << 18)
          #  attr |= ((cattr >> 18) & 0x1ff) << 18
          # end
          # if (cursor.shape.fg)
          #  attr &= ~(0x1ff << 9)
          #  attr |= ((cattr >> 9) & 0x1ff) << 9
          # end
          # if (cursor.shape.bg)
          #  attr &= ~(0x1ff << 0)
          #  attr |= cattr & 0x1ff
          # end
          # if (cursor.shape.ch)
          #  ch = cursor.shape.ch
          # end
        end

        unless (cursor.color.nil?)
          attr &= ~(0x1ff << 9)
          attr |= cursor.color.value << 9
        end

        return Cell.new \
          attr: attr,
          char: ch || ' '
      end

      def _reduce_color(col)
        Colors.reduce(col, app.tput.features.number_of_colors)
      end
    end

    module Focus
      include Crystallabs::Helpers::Alias_Methods

      # Send focus events after mouse is enabled?
      property send_focus = false

      property _saved_focus : Widget?

      @history = [] of Widget
      @clickable = [] of Widget
      @keyable = [] of Widget

      # Focuses an element by an offset in the list of focusable elements.
      def focus_offset(offset)
        shown = @keyable.select { |el| !el.detached? && el.visible? }.size

        if (shown == 0 || offset == 0)
          return
        end

        i = @keyable.index(focused) || return

        if (offset > 0)
          while offset > 0
            offset -= 1
            i += 1
            if (i > @keyable.size - 1)
              i = 0
            end
            if (@keyable[i].detached? || !@keyable[i].visible?)
              offset += 1
            end
          end
        else
          offset = -offset
          while offset > 0
            offset -= 1
            i -= 1
            if (i < 0)
              i = @keyable.size - 1
            end
            if (@keyable[i].detached? || !@keyable[i].visible?)
              offset += 1
            end
          end
        end

        @keyable[i].focus
      end

      # Focuses previous element in the list of focusable elements.
      def focus_previous
        focus_offset -1
      end

      alias_previous focus_prev

      # Focuses next element in the list of focusable elements.
      def focus_next
        focus_offset 1
      end

      # Focuses element `el`. Equivalent to `@window.focused = el`.
      def focus_push(el)
        old = @history[-1]?
        while @history.size >= 10 # XXX non-configurable at the moment
          @history.shift
        end
        @history.push el
        _focus el, old
      end

      # Removes focus from the current element and focuses the element that was previously in focus.
      def focus_pop
        old = @history.pop
        if el = @history[-1]?
          _focus el, old
        end
        return old
      end

      # Saves/remembers the currently focused element.
      def save_focus
        @_saved_focus = focused
      end

      # Restores focus to the previously saved focused element.
      def restore_focus
        return unless sf = @_saved_focus
        sf.focus
        @_saved_focus = nil
        focused
      end

      # "Rewinds" focus to the most recent visible and attached element.
      #
      # As a side-effect, prunes the focus history list.
      def rewind_focus
        old = @history.pop

        while @history.size > 0
          el = @history.pop
          if !el.detached? && el.visible?
            @history.push el
            _focus el, old
            return el
          end
        end

        if old
          old.emit Crysterm::Event::Blur
        end
      end

      def _focus(cur : Widget, old : Widget? = nil)
        # Find a scrollable ancestor if we have one.
        el = cur
        while el = el.parent
          if el.scrollable?
            break
          end
        end

        # TODO is it valid that this isn't Widget?
        # unless el.is_a? Widget
        #  raise "Unexpected"
        # end

        # If we're in a scrollable element,
        # automatically scroll to the focused element.
        if (el && !el.detached?)
          # NOTE: This is different from the other "visible" values - it needs the
          # visible height of the scrolling element itself, not the element within it.
          # NOTE why a/i values can be nil?
          visible = cur.window.height - el.atop.not_nil! - el.itop.not_nil! - el.abottom.not_nil! - el.ibottom.not_nil!
          if cur.rtop < el.child_base
            # XXX remove 'if' when Window is no longer parent of elements
            if el.is_a? Widget
              el.scroll_to cur.rtop
            end
            cur.window.render
          elsif (cur.rtop + cur.height - cur.ibottom) > (el.child_base + visible)
            # Explanation for el.itop here: takes into account scrollable elements
            # with borders otherwise the element gets covered by the bottom border:
            # XXX remove 'if' when Window is no longer parent of elements
            if el.is_a? Widget
              el.scroll_to cur.rtop - (el.height - cur.height) + el.itop, true
            end
            cur.window.render
          end
        end

        if old
          old.emit Crysterm::Event::Blur, cur
        end

        cur.emit Crysterm::Event::Focus, old
      end

      # Returns the current/top element from the focus history list.
      def focused
        @history[-1]?
      end

      # Makes `el` become the current/top element in the focus history list.
      def focused=(el)
        focus_push el
      end
    end

    module Rendering
      class BorderStop
        property? yes = false
        property xi : Int32?
        property xl : Int32?
      end

      class BorderStops < Hash(Int32, BorderStop)
        def []=(idx : Int32, arg)
          self[idx]? || (self[idx] = BorderStop.new)
          case arg
          when Bool
            self[idx].yes = arg
          else
            self[idx].xi = arg.xi
            self[idx].xl = arg.xl
          end
        end
      end

      @render_flag : Atomic(UInt8) = Atomic.new 0u8
      @render_channel : Channel(Bool) = Channel(Bool).new
      @interval : Float64 = 1/29

      def schedule_render
        _old, succeeded = @render_flag.compare_and_set 0, 1
        if succeeded
          @render_channel.send true
        end
      end

      class Average < Deque(Int32)
        def avg(value)
          shift if size == @capacity
          push value
          sum // size
        end
      end

      @rps = Average.new 30
      @dps = Average.new 30
      @fps = Average.new 30

      def render_loop
        loop do
          if @render_channel.receive
            sleep @interval
          end
          _render
          if @render_flag.lazy_get == 2
            break
          else
            @render_flag.swap 0
          end
        end
      end

      #class_property auto_draw = false

      @_buf = IO::Memory.new
      property _ci = -1

      property _border_stops = {} of Int32 => Bool

      ## Attempt to perform CSR optimization on all possible elements,
      ## and not just on full-width ones, i.e. those with uniform cells to their sides.
      ## This is known to cause flickering with elements that are not full-width, but
      ## it is more optimal for terminal rendering.
      #property smart_csr : Bool = false

      ## Enable CSR on any element within 20 columns of the window edges on either side.
      ## It is faster than smart_csr, but may cause flickering depending on what is on
      ## each side of the element.
      #property fast_csr : Bool = false

      ## Attempt to perform back_color_erase optimizations for terminals that support it.
      ## It will also work with terminals that don't support it, but only on lines with
      ## the default background color. As it stands with the current implementation,
      ## it's uncertain how much terminal performance this adds at the cost of code overhead.
      #property use_bce : Bool = false

      property optimization : OptimizationFlag = OptimizationFlag::None

      # XXX move somewhere else?
      # Default cell attribute
      property dattr : Int32 = ((0 << 18) | (0x1ff << 9)) | 0x1ff

      property padding = Padding.new

      # Automatically position child elements with border and padding in mind.
      property auto_padding = true

      # Automatically "dock" borders with other elements instead of overlapping,
      # depending on position.
      #     These border-overlapped elements:
      #     ┌─────────┌─────────┐
      #     │ box1    │ box2    │
      #     └─────────└─────────┘
      #     Become:
      #     ┌─────────┬─────────┐
      #     │ box1    │ box2    │
      #     └─────────┴─────────┘
      property? dock_borders

      # Dockable borders will not dock if the colors or attributes are different.
      # This option will allow docking regardless. It may produce odd looking
      # multi-colored borders.
      @ignore_dock_contrast = false

      property lines = Array(Row).new
      property olines = Array(Row).new

      # Width of tabs in elements' content.
      property tab_size : Int32

      getter! tabc : String

      def _dock_borders
        lines = @lines
        stops = @_border_stops
        # i
        # y
        # x
        # ch

        # D O:
        # keys, stop
        # keys = Object.keys(this._borderStops)
        #   .map(function(k) { return +k; })
        #   .sort(function(a, b) { return a - b; })
        #
        # for (i = 0; i < keys.length; i++)
        #   y = keys[i]
        #   if (!lines[y]) continue
        #   stop = this._borderStops[y]
        #   for (x = stop.xi; x < stop.xl; x++)

        stops = stops.keys.map(&.to_i).sort { |a, b| a - b }

        stops.each do |y|
          if (!lines[y]?)
            next
          end
          width.times do |x|
            ch = lines[y][x].char
            if @angles[ch]?
              lines[y][x].char = _get_angle lines, x, y
              lines[y].dirty = true
            end
          end
        end
      end

      # Delayed render (user render)
      def render
        schedule_render
      end

      # Real render
      def _render #(draw = true) #@@auto_draw)
        t1 = Time.monotonic

        return if destroyed?

        emit Crysterm::Event::PreRender

        @_border_stops.clear

        # TODO: Possibly get rid of .dirty altogether.
        # TODO: Could possibly drop .dirty and just clear the `lines` buffer every
        # time before a window.render. This way clearRegion doesn't have to be
        # called in arbitrary places for the sake of clearing a spot where an
        # element used to be (e.g. when an element moves or is hidden). There could
        # be some overhead though.
        # window.clearRegion(0, this.cols, 0, this.rows);
        @_ci = 0
        @children.each do |el|
          el.index = @_ci
          @_ci += 1
          # D O:
          # el._rendering = true
          el.render
          # D O:
          # el._rendering = false
        end
        @_ci = -1

        # if (@window.dock_borders?) # XXX why we do @window here? Can we do without?
        if @dock_borders
          _dock_borders
        end

        t2 = Time.monotonic

        #draw 0, @lines.size - 1 if draw
        #self.draw if draw
        draw

        # Workaround to deal with cursor pos before the window
        # has rendered and lpos is not reliable (stale).
        # Only some element have this functions; for others it's a noop.
        focused.try &._update_cursor(true)

        @renders += 1

        emit Crysterm::Event::Render

        t3 = Time.monotonic

        if pos = @show_fps
          #{ rps, dps, fps }
          ps = { 1//(t2 - t1).total_seconds, 1//(t3 - t2).total_seconds, 1//(t3 - t1).total_seconds }

          app.tput.save_cursor
          app.tput.pos pos
          app.tput._print { |io| io << "R/D/FPS: " << ps[0] << '/' << ps[1] << '/' << ps[2] }
          if @show_avg
            app.tput._print { |io| io << " (" << @rps.avg(ps[0]) << '/' << @dps.avg(ps[1]) << '/' << @fps.avg(ps[2]) << ')' }
          end
          app.tput.restore_cursor
        end
      end
    end

    module Drawing

      @outbuf : IO::Memory = IO::Memory.new 10240
      @main : IO::Memory = IO::Memory.new 10240

      @pre = IO::Memory.new 1024
      @post = IO::Memory.new 1024

      # Draws the window based on the contents of the output buffer.
      def draw(start = 0, stop = @lines.size - 1)
        # D O:
        # emit Event::PreDraw
        # x , y , line , out , ch , data , attr , fg , bg , flags
        # pre , post
        # clr , neq , xx
        # acs
        @main.clear
        @outbuf.clear
        lx = -1
        ly = -1
        acs = false
        s = app.tput.shim.not_nil!

        if @_buf.size > 0
          @main.print @_buf
          @_buf.clear
        end

        Log.trace { "Drawing #{start}..#{stop}" }

        (start..stop).each do |y|
          line = @lines[y]
          o = @olines[y]
          # Log.trace { line } if line.any? &.char.!=(' ')

          if (!line.dirty && !(cursor.artificial && (y == app.tput.cursor.y)))
            next
          end
          line.dirty = false

          # Assume line is dirty by continuing: (XXX need to optimize)

          @outbuf.clear

          attr = @dattr

          line.size.times do |x|
            data = line[x].attr
            ch = line[x].char

            c = cursor
            # Render the artificial cursor.
            if (c.artificial && !c._hidden && (c._state != 0) && (x == app.tput.cursor.x) && (y == app.tput.cursor.y))
              cattr = _cursor_attr(c, data)
              if (cattr.char) # XXX Can cattr.char even not be truthy?
                ch = cattr.char
              end
              data = cattr.attr
            end

            # Take advantage of xterm's back_color_erase feature by using a
            # lookahead. Stop spitting out so many damn spaces. NOTE: Is checking
            # the bg for non BCE terminals worth the overhead?
            if (@optimization.bce? && (ch == ' ') &&
               (app.tput.has?(&.back_color_erase?) || (data & 0x1ff) == (@dattr & 0x1ff)) &&
               (((data >> 18) & 8) == ((@dattr >> 18) & 8)))
              clr = true
              neq = false

              (x...line.size).each do |xx|
                if line[xx] != {data, ' '}
                  clr = false
                  break
                end
                if line[xx] != o[xx]
                  neq = true
                end
              end

              if (clr && neq)
                lx = -1
                ly = -1
                if (data != attr)
                  @outbuf.print code_attr(data)
                  attr = data
                end

                # ### Temporarily diverts output. ####
                # XXX See if it causes problems when multithreaded or something?
                (app.tput.ret = IO::Memory.new).try do |ret|
                  app.tput.cup(y, x)
                  app.tput.el
                  @outbuf .print ret.rewind.gets_to_end
                  app.tput.ret = nil
                end
                #### #### ####

                (x...line.size).each do |xx|
                  o[xx].attr = data
                  o[xx].char = ' '
                end
                break
              end

              # D O:
              # If there's more than 10 spaces, use EL regardless
              # and start over drawing the rest of line. Might
              # not be worth it. Try to use ECH if the terminal
              # supports it. Maybe only try to use ECH here.
              # #if (app.tput.strings.erase_chars)
              # if (!clr && neq && (xx - x) > 10)
              #   lx = -1; ly = -1
              #   if (data != attr)
              #     @outbuf.print code_attr(data)
              #     attr = data
              #   end
              #   @outbuf.print app.tput.cup(y, x)
              #   if (app.tput.strings.erase_chars)
              #     # Use erase_chars to avoid erasing the whole line.
              #     @outbuf.print app.tput.ech(xx - x)
              #   else
              #     @outbuf.print app.tput.el()
              #   end
              #   if (app.tput.strings.parm_right_cursor)
              #     @outbuf.print app.tput.cuf(xx - x)
              #   else
              #     @outbuf.print app.tput.cup(y, xx)
              #   end
              #   fill_region(data, ' ', x, app.tput.strings.erase_chars ? xx : line.length, y, y + 1)
              #   x = xx - 1
              #   next
              # end
              # Skip to the next line if the rest of the line is already drawn.
              # if (!neq)
              #   for (; xx < line.length; xx++)
              #     if (line[xx][0] != o[xx][0] || line[xx][1] != o[xx][1])
              #       neq = true
              #       break
              #     end
              #   end
              #   if !neq
              #     attr = data
              #     break
              #   end
              # end
            end

            # Optimize by comparing the real output
            # buffer to the pending output buffer.
            # TODO Avoid using Strings
            if o[x] == {data, ch}
              if (lx == -1)
                lx = x
                ly = y
              end
              next
            elsif (lx != -1)
              if (s.parm_right_cursor?)
                @outbuf.write ((y == ly) ? s.cuf(x - lx) : s.cup(y, x))
              else
                @outbuf.write s.cup(y, x)
              end
              lx = -1
              ly = -1
            end
            o[x].attr = data
            o[x].char = ch


            if (data != attr)
              if (attr != @dattr)
                @outbuf.print "\x1b[m"
              end
              if (data != @dattr)
                @outbuf.print "\x1b["

                # This will keep track whether any of the attrs were
                # written into the buffer. If they were, then we'll seek
                # to (current_pos)-1 to delete the last ';'
                outbuf_size = @outbuf.size

                bg = data & 0x1ff
                fg = (data >> 9) & 0x1ff
                flags = data >> 18
                # bold
                if ((flags & 1) != 0)
                  @outbuf.print "1;"
                end

                # underline
                if ((flags & 2) != 0)
                  @outbuf.print "4;"
                end

                # blink
                if ((flags & 4) != 0)
                  @outbuf.print "5;"
                end

                # inverse
                if ((flags & 8) != 0)
                  @outbuf.print "7;"
                end

                # invisible
                if ((flags & 16) != 0)
                  @outbuf.print "8;"
                end

                if (bg != 0x1ff)
                  bg = _reduce_color(bg)
                  if (bg < 16)
                    if (bg < 8)
                      bg += 40
                    else # elsif (bg < 16)
                      bg -= 8
                      bg += 100
                    end
                    @outbuf << bg << ';'
                  else
                    @outbuf << "48;5;" << bg << ';'
                  end
                end

                if (fg != 0x1ff)
                  fg = _reduce_color(fg)
                  if (fg < 16)
                    if (fg < 8)
                      fg += 30
                    else # elsif (fg < 16)
                      fg -= 8
                      fg += 90
                    end
                    @outbuf << fg << ';'
                  else
                    @outbuf << "38;5;" << fg << ';'
                  end
                end

                if @outbuf.size != outbuf_size
                  # Something was written to the buffer during the code above,
                  # and it surely contains a ';' at the end. Conveniently remove it.
                  @outbuf.seek -1, IO::Seek::Current
                end

                @outbuf.print 'm'
                #Log.trace { @outbuf.inspect }
              end
            end

            # TODO Enable this
            # # If we find a double-width char, eat the next character which should be
            # # a space due to parseContent's behavior.
            # if (@fullUnicode)
            #  # If this is a surrogate pair double-width char, we can ignore it
            #  # because parseContent already counted it as length=2.
            #  if (unicode.charWidth(line[x].char) == 2)
            #    # NOTE: At cols=44, the bug that is avoided
            #    # by the angles check occurs in widget-unicode:
            #    # Might also need: `line[x + 1].attr != line[x].attr`
            #    # for borderless boxes?
            #    if (x == line.length - 1 || angles[line[x + 1].char])
            #      # If we're at the end, we don't have enough space for a
            #      # double-width. Overwrite it with a space and ignore.
            #      ch = ' '
            #      o[x].char = '\0'
            #    else
            #      # ALWAYS refresh double-width chars because this special cursor
            #      # behavior is needed. There may be a more efficient way of doing
            #      # @ See above.
            #      o[x].char = '\0'
            #      # Eat the next character by moving forward and marking as a
            #      # space (which it is).
            #      o[++x].char = '\0'
            #    end
            #  end
            # end

            # Attempt to use ACS for supported characters.
            # This is not ideal, but it's how ncurses works.
            # There are a lot of terminals that support ACS
            # *and UTF8, but do not declare U8. So ACS ends
            # up being used (slower than utf8). Terminals
            # that do not support ACS and do not explicitly
            # support UTF8 get their unicode characters
            # replaced with really ugly ascii characters.
            # It is possible there is a terminal out there
            # somewhere that does not support ACS, but
            # supports UTF8, but I imagine it's unlikely.
            # Maybe remove !app.tput.unicode check, however,
            # this seems to be the way ncurses does it.
            #
            # Note the behavior of this IF/ELSE block. It may decide to
            # print to @outbuf certain prefix data, but after the IF/ELSE block
            # the 'ch' is always written. This logic is taken for speed. In the
            # case that the contents of the IF/ELSE block change in incompatible
            # way, this should be had in mind.
            if s
              if (s.enter_alt_charset_mode? && !app.tput.features.broken_acs? && (app.tput.features.acscr[ch]? || acs))
                # Fun fact: even if app.tput.brokenACS wasn't checked here,
                # the linux console would still work fine because the acs
                # table would fail the check of: app.tput.features.acscr[ch]
                # TODO This is nasty. Char gets changed to string
                # when sm/rm is added to the stream.
                if (app.tput.features.acscr[ch]?)
                  if (acs)
                    ch = app.tput.features.acscr[ch]
                  else
                    #sm = String.new s.smacs
                    #ch = sm + app.tput.features.acscr[ch]
                    # Instead, just print prefix and set new char:
                    @outbuf.write s.smacs
                    ch = app.tput.features.acscr[ch]

                    acs = true
                  end
                elsif acs
                  #rm = String.new s.rmacs
                  #ch = rm + ch
                  # Instead, similar as above:
                  @outbuf.write s.rmacs
                  acs = false
                end
              end
            else
              # U8 is not consistently correct. Some terminfo's
              # terminals that do not declare it may actually
              # support utf8 (e.g. urxvt), but if the terminal
              # does not declare support for ACS (and U8), chances
              # are it does not support UTF8. This is probably
              # the "safest" way to do @ Should fix things
              # like sun-color.
              # NOTE: It could be the case that the $LANG
              # is all that matters in some cases:
              # if (!app.tput.unicode && ch > '~') {
              if (!app.tput.features.unicode? && (app.tput.terminfo.try(&.extensions.get_num?("U8")) != 1) && (ch > '~'))
                # Reduction of ACS into ASCII chars.
                ch = Tput::ACSC::Data[ch]?.try(&.[2]) || '?'
              end
            end

            # Now print the char itself.
            @outbuf.print ch

            attr = data
          end

          if (attr != @dattr)
            @outbuf.print "\x1b[m"
          end

          unless @outbuf.empty?
            #STDERR.puts @outbuf.size
            @main.write s.cup(y, 0) #.to_slice)
            @main.print @outbuf.rewind.gets_to_end
          end
        end

        if (acs)
          @main.write s.rmacs
          acs = false
        end

        unless @main.size == 0
          @pre.clear
          @post.clear
          hidden = app.tput.cursor_hidden?

          (app.tput.ret = IO::Memory.new).try do |ret|
            app.tput.save_cursor
            if !hidden
              app.tput.hide_cursor
            end

            @pre << ret.rewind.gets_to_end
            app.tput.ret = nil
          end

          (app.tput.ret = IO::Memory.new).try do |ret|
            app.tput.restore_cursor
            if !hidden
              app.tput.show_cursor
            end

            @post << ret.rewind.gets_to_end
            app.tput.ret = nil
          end

          # D O:
          # app.flush()
          # app._owrite(@pre + @main + @post)
          app.tput._print { |io| io << @pre << @main.rewind.gets_to_end << @post }
        end

        # D O:
        #emit Event::Draw
      end

      def blank_line(ch = ' ', dirty = false)
        o = Row.new width, {@dattr, ch}
        o.dirty = dirty
        o
      end

      # Inserts lines into the window. (If CSR is used, it bypasses the output buffer.)
      def insert_line(n, y, top, bottom)
        # D O:
        # if (y == top)
        #  return insert_line_nc(n, y, top, bottom)
        # end

        if (!app.tput.has?(&.change_scroll_region?) ||
           !app.tput.has?(&.delete_line?) ||
           !app.tput.has?(&.insert_line?))
          STDERR.puts "Missing needed terminfo capabilities"
          return
        end

        (app.tput.ret = IO::Memory.new).try do |ret|
          app.tput.set_scroll_region(top, bottom)
          app.tput.cup(y, 0)
          app.tput.il(n)
          app.tput.set_scroll_region(0, height - 1)

          @_buf.print ret.rewind.gets_to_end
          app.tput.ret = nil
        end

        j = bottom + 1

        n.times do
          @lines.insert y, blank_line
          @lines.delete_at j
          @olines.insert y, blank_line
          @olines.delete_at j
        end
      end

      # Inserts lines into the window using ncurses-compatible method. (If CSR is used, it bypasses the output buffer.)
      #
      # This is how ncurses does it.
      # Scroll down (up cursor-wise).
      # This will only work for top line deletion as opposed to arbitrary lines.
      def insert_line_nc(n, y, top, bottom)
        if (!app.tput.has?(&.change_scroll_region?) ||
           !app.tput.has?(&.delete_line?))
          STDERR.puts "Missing needed terminfo capabilities"
          return
        end

        (app.tput.ret = IO::Memory.new).try do |ret|
          app.tput.set_scroll_region(top, bottom)
          app.tput.cup(top, 0)
          app.tput.dl(n)
          app.tput.set_scroll_region(0, height - 1)

          @_buf.print ret.rewind.gets_to_end
          app.tput.ret = nil
        end

        j = bottom + 1

        n.times do
          @lines.insert y, blank_line
          @lines.delete_at j
          @olines.insert y, blank_line
          @olines.delete_at j
        end
      end

      # Deletes lines from the window. (If CSR is used, it bypasses the output buffer.)
      def delete_line(n, y, top, bottom)
        # D O:
        # if (y == top)
        #   return delete_line_nc(n, y, top, bottom)
        # end

        if (!app.tput.has?(&.change_scroll_region?) ||
           !app.tput.has?(&.delete_line?) ||
           !app.tput.has?(&.insert_line?))
          STDERR.puts "Missing needed terminfo capabilities"
          return
        end

        # XXX temporarily diverts output
        (app.tput.ret = IO::Memory.new).try do |ret|
          app.tput.set_scroll_region(top, bottom)
          app.tput.cup(y, 0)
          app.tput.dl(n)
          app.tput.set_scroll_region(0, height - 1) # XXX @height should be used?

          @_buf.print ret.rewind.gets_to_end
          app.tput.ret = nil
        end

        j = bottom + 1
        while n > 0
          n -= 1
          @lines.insert y, blank_line
          @lines.delete_at y
          @olines.insert y, blank_line
          @olines.delete_at y
        end
      end

      # Deletes lines from the window using ncurses-compatible method. (If CSR is used, it bypasses the output buffer.)
      #
      # This is how ncurses does it.
      # Scroll down (up cursor-wise).
      # This will only work for top line deletion as opposed to arbitrary lines.
      def delete_line_nc(n, y, top, bottom)
        if (!app.tput.has?(&.change_scroll_region?) ||
           !app.tput.has?(&.delete_line?))
          STDERR.puts "Missing needed terminfo capabilities"
          return
        end

        # XXX temporarily diverts output
        (app.tput.ret = IO::Memory.new).try do |ret|
          app.tput.set_scroll_region(top, bottom)
          app.tput.cup(bottom, 0)
          ret.print "\n" * n
          app.tput.set_scroll_region(0, height - 1)

          @_buf.print ret.rewind.gets_to_end
          app.tput.ret = nil
        end

        j = bottom + 1

        n.times do
          @lines.insert j, blank_line
          @lines.delete_at y
          @olines.insert j, blank_line
          @olines.delete_at y
        end
      end

      # Inserts line at bottom of window.
      def insert_bottom(top, bottom)
        delete_line(1, top, top, bottom)
      end

      # Inserts line at top of window.
      def insert_top(top, bottom)
        insert_line(1, top, top, bottom)
      end

      # Deletes line at bottom of window.
      def delete_bottom(top, bottom)
        clear_region(0, width, bottom, bottom)
      end

      # Deletes line at top of window.
      def delete_top(top, bottom)
        # Same as: insert_bottom(top, bottom)
        delete_line(1, top, top, bottom)
      end

      # Parse the sides of an element to determine
      # whether an element has uniform cells on
      # both sides. If it does, we can use CSR to
      # optimize scrolling on a scrollable element.
      # Not exactly sure how worthwile this is.
      # This will cause a performance/cpu-usage hit,
      # but will it be less or greater than the
      # performance hit of slow-rendering scrollable
      # boxes with clean sides?
      def clean_sides(el)
        pos = el.lpos

        if (!pos)
          return false
        end

        unless (pos._clean_sides.nil?)
          return pos._clean_sides
        end

        if (pos.xi <= 0 && (pos.xl >= width))
          return pos._clean_sides = true
        end

        if @optimization.fast_csr?
          # Maybe just do this instead of parsing.
          if (pos.yi < 0)
            return pos._clean_sides = false
          end
          if (pos.yl > height)
            return pos._clean_sides = false
          end
          if ((width - (pos.xl - pos.xi)) < 40)
            return pos._clean_sides = true
          end
          return pos._clean_sides = false
        end

        unless @optimization.smart_csr?
          return false
        end

        # D O:
        # The scrollbar can't update properly, and there's also a
        # chance that the scrollbar may get moved around senselessly.
        # NOTE: In pratice, this doesn't seem to be the case.
        # if (@scrollbar)
        #  return pos._clean_sides = false
        # end
        # Doesn't matter if we're only a height of 1.
        # if ((pos.yl - el.ibottom) - (pos.yi + el.itop) <= 1)
        #   return pos._clean_sides = false
        # end

        yi = pos.yi + el.itop
        yl = pos.yl - el.ibottom
        # first
        # ch
        # x
        # y

        if (pos.yi < 0)
          return pos._clean_sides = false
        end
        if (pos.yl > height)
          return pos._clean_sides = false
        end
        if ((pos.xi - 1) < 0)
          return pos._clean_sides = true
        end
        if (pos.xl > width)
          return pos._clean_sides = true
        end

        x = pos.xi - 1
        while x >= 0
          if (!@olines[yi]?)
            break
          end
          first = @olines[yi][x]
          (yi...yl).each do |y|
            if (!@olines[y]? || !@olines[y][x]?)
              break
            end
            ch = @olines[y][x]
            if ch != first
              return pos._clean_sides = false
            end
          end
          x -= 1
        end

        (pos.xl...width).each do |x|
          if (!@olines[yi]?)
            break
          end
          first = @olines[yi][x]
          (yi...yl).each do |y|
            if (!@olines[y] || !@olines[y][x])
              break
            end
            ch = @olines[y][x]
            if ch != first
              return pos._clean_sides = false
            end
          end
          x += 1
        end

        pos._clean_sides = true
      end

      # Clears any chosen region on the window.
      def clear_region(xi, xl, yi, yl, override)
        fill_region @dattr, ' ', xi, xl, yi, yl, override
      end

      # Fills any chosen region on the window with chosen character and attributes.
      def fill_region(attr, ch, xi, xl, yi, yl, override = false)
        lines = @lines

        if (xi < 0)
          xi = 0
        end
        if (yi < 0)
          yi = 0
        end

        while yi < yl
          break unless @lines[yi]?

          xx = xi
          while xx < xl
            cell = lines[yi][xx]?
            break unless cell

            if override || cell != {attr, ch}
              lines[yi][xx].attr = attr
              lines[yi][xx].char = ch
              lines[yi].dirty = true
            end

            xx += 1
          end
          yi += 1
        end
      end
    end
  end
end

module Crysterm
  # Represents a window. `Window` and `Widget` are two lowest-level classes after `EventEmitter` and `Widget`.
  class Window
    include EventHandler

    include Focus
    include Attributes
    include Angles
    include Rendering
    include Drawing
    include Cursor
    include Widget::Pos

    class_getter instances = [] of self

    @@global : Crysterm::Window?

    def self.total
      @@instances.size
    end

    def self.global(create : Bool = true)
      (instances[0]? || (create ? new : nil)).not_nil!
    end

    @@_bound = false

    def bind
      @@global = self unless @@global

      @@instances << self # unless @@instances.includes? self

      return if @@_bound
      @@_bound = true

      # TODO Enable
      # ['SIGTERM', 'SIGINT', 'SIGQUIT'].each do |signal|
      #  name = '_' + signal.toLowerCase() + 'Handler'
      #  Signal::<>.trap do
      #    if listeners(signal).size > 1
      #      return;
      #    end
      #    process.exit(0);
      #  end
      # end
    end

    # Destroys self and removes it from the global list of `Window`s.
    # Also remove all global events relevant to the object.
    # If no windows remain, the app is essentially reset to its initial state.
    def destroy
      leave

      @render_flag.set 2

      if @@instances.delete self
        if @@instances.any?
          @@global = @@instances[0]
        else
          #@@global = nil # XXX
          # TODO remove all signal handlers set up on the app's process
          @@_bound = false
        end

        @destroyed = true
        emit Crysterm::Event::Destroy

        #super # No longer exists since we're not subclass of Node any more
      end

      app.destroy
    end

    ######### COMMON WITH NODE

    # Widget's children `Widget`s.
    property children = [] of Widget

    property? destroyed = false

    # Is this `Window` detached?
    #
    # Window is a self-sufficient element, so by default it is always considered 'attached'.
    # This value could in the future be used to maybe hide/deactivate windows temporarily etc.
    property? detached = false

    def append(element)
      insert element
    end

    def append(*elements)
      elements.each do |el|
        insert el
      end
    end

    def insert(element, i = -1)

      # XXX Never triggers. But needs to be here for type safety.
      # Hopefully can be removed when Window is no longer parent of any Widgets.
      if element.is_a? Window
        raise "Unexpected"
      end

      element.detach

      element.window = self

      # if i == -1
      #  @children.push element
      # elsif i == 0
      #  @children.unshift element
      # else
      @children.insert i, element
      # end

      emt = uninitialized Widget -> Nil
      emt = ->(el : Widget) {
        n = el.detached? != @detached
        el.detached = @detached
        el.emit Crysterm::Event::Attach if n
        el.children.each do |c|
          emt.call c
        end
      }
      emt.call element

      unless self.focused
        self.focused = element
      end
    end

    # Removes node from its parent.
    # This is identical to calling `#remove` on the parent object.
    def detach
      @parent.try { |p| p.remove self }
    end

    def remove(element)
      return if element.parent != self

      return unless i = @children.index(element)

      element.clear_pos

      element.parent = nil
      @children.delete_at i

      # TODO Enable
      # if i = @window.clickable.index(element)
      #  @window.clickable.delete_at i
      # end
      # if i = @window.keyable.index(element)
      #  @window.keyable.delete_at i
      # end

      element.emit(Crysterm::Event::Reparent, nil)
      emit(Crysterm::Event::Remove, element)
      # s= @window
      # raise Exception.new() unless s
      # window_clickable= s.clickable
      # window_keyable= s.keyable

      emt = ->(el : Widget) {
        n = el.detached? != @detached
        el.detached = true
        # TODO Enable
        # el.emit(Event::Detach) if n
        # el.children.each do |c| c.emt end # wt
      }
      emt.call element

      if focused == element
        rewind_focus
      end
    end

    # Prepends node to the list of children
    def prepend(element)
      insert element, 0
    end

    # Adds node to the list of children before the specified `other` element
    def insert_before(element, other)
      if i = @children.index other
        insert element, i
      end
    end

    # Adds node to the list of children after the specified `other` element
    def insert_after(element, other)
      if i = @children.index other
        insert element, i + 1
      end
    end

    ######### END OF COMMON WITH SCREEN

    # Associated `Crysterm` instance. The default app object
    # will be created/used if it is not provided explicitly.
    property! app : App

    # Is focused element grabbing and receiving all keypresses?
    property grab_keys = false

    # Are keypresses prevented from being sent to any element?
    property lock_keys = false

    # Array of keys to ignore when keys are locked or grabbed. Useful for defining
    # keys that will always execute their action (e.g. exit a program) regardless of
    # whether keys are locked.
    property ignore_locked = Array(Tput::Key).new

    # Currently hovered element. Best set only if mouse events are enabled.
    @hover : Widget? = nil

    property show_fps : Tput::Point? = Tput::Point[-1,0]
    property? show_avg = true

    property optimization : OptimizationFlag = OptimizationFlag::None

    def initialize(
      @app = App.global(true),
      @auto_padding = true,
      @tab_size = 4,
      @dock_borders = false,
      ignore_locked : Array(Tput::Key)? = nil,
      @lock_keys = false,
      title = nil,
      @cursor = Tput::Namespace::Cursor.new,
      optimization = nil
    )
      bind

      ignore_locked.try { |v| @ignore_locked += v }
      optimization.try { |v| @optimization = v }

      #@app = app || App.global true
      # ensure tput.zero_based = true, use_bufer=true
      # set resizeTimeout

      # Tput is accessed via app.tput

      #super() No longer calling super, we are not subclass of Widget any more

      @tabc = " " * @tab_size

      # _unicode is app.tput.features.unicode
      # full_unicode? is option full_unicode? + _unicode

      # Events:
      # addhander,

      self.title = title if title

      app.on(Crysterm::Event::Resize) do
        alloc
        render

        # XXX Can we replace this with each_descendant?
        f = uninitialized Widget | Window -> Nil
        f = ->(el : Widget | Window ) {
          el.emit Crysterm::Event::Resize
          el.children.each { |c| f.call c }
        }
        f.call self
      end

      # TODO Originally, these exist. See about reenabling them.
      #app.on(Crysterm::Event::Focus) do
      #  emit Crysterm::Event::Focus
      #end
      #app.on(Crysterm::Event::Blur) do
      #  emit Crysterm::Event::Blur
      #end
      #app.on(Crysterm::Event::Warning) do |e|
      #  emit e
      #end

      _listen_keys
      # _listen_mouse # XXX

      enter
      post_enter

      spawn render_loop
    end

    # This is for the bottom-up approach where the keys are
    # passed onto the focused widget, and from there eventually
    # propagated to the top.
    # def _listen_keys
    #  app.on(Crysterm::Event::KeyPress) do |e|
    #    el = focused || self
    #    while !e.accepted? && el
    #      # XXX emit only if widget enabled?
    #      el.emit e
    #      el = el.parent
    #    end
    #  end
    # end

    # And this is for the other/alternative method where the window
    # first gets the keys, then potentially passes onto children
    # elements.
    def _listen_keys(el : Widget? = nil)
      if (el && !@keyable.includes? el)
        el.keyable = true
        @keyable.push el
      end

      return if @_listenedKeys
      @_listenedKeys = true

      # NOTE: The event emissions used to be reversed:
      # element + window
      # They are now:
      # window, element and el's parents until one #accept!s it.
      # After the first keypress emitted, the handler
      # checks to make sure grab_keys, lock_keys, and focused
      # weren't changed, and handles those situations appropriately.
      app.on(Crysterm::Event::KeyPress) do |e|
        if @lock_keys && !@ignore_locked.includes?(e.key)
          next
        end

        grab_keys = @grab_keys
        if !grab_keys || @ignore_locked.includes?(e.key)
          emit_key self, e
        end

        # If something changed from the window key handler, stop.
        if (@grab_keys != grab_keys) || @lock_keys || e.accepted?
          next
        end

        # Here we pass the key press onto the focused widget. Then
        # we keep passing it through the parent tree until someone
        # `#accept!`s the key. If it reaches the toplevel Widget
        # and it isn't handled, we drop/ignore it.
        focused.try do |el|
          while el && el.is_a? Widget
            if el.keyable?
              emit_key el, e
            end

            if e.accepted?
              break
            end

            el = el.parent
          end
        end
      end
    end

    # Emits a Event::KeyPress as usual and also emits an event for
    # the individual key, if any.
    #
    # This allows listeners to not only listen for a generic
    # `Event::KeyPress` and then check for `#key`, but they can
    # directly listen for e.g. `Event::KeyPress::CtrlP`.
    @[AlwaysInline]
    def emit_key(el, e : Event)
      if el.handlers(e.class).any?
        el.emit e
      end
      if e.key
        Crysterm::Event::KeyPress::Key_events[e.key]?.try do |keycls|
          if el.handlers(keycls).any?
            el.emit keycls.new e.char, e.key, e.sequence
          end
        end
      end
    end

    def enable_keys(el = nil)
      _listen_keys(el)
    end

    def enable_input(el = nil)
      # _listen_mouse(el)
      _listen_keys(el)
    end

    # TODO Empty for now
    def key(key, handler)
    end

    def once_key(key, handler)
    end

    def remove_key(key, wrapper)
    end

    def enter
      # TODO make it possible to work without switching the whole
      # app to alt buffer.
      return if app.tput.is_alt

      if !cursor._set
        if cursor.shape
          cursor_shape cursor.shape, cursor.blink
        end
        if cursor.color
          cursor_color cursor.color
        end
      end

      # XXX Livable, but boy no.
      {% if flag? :windows %}
        `cls`
      {% end %}

      at = app.tput
      app.tput.alternate_buffer
      app.tput.put(&.keypad_xmit?) # enter_keyboard_transmit_mode
      app.tput.put(&.change_scroll_region?(0, height - 1))
      app.tput.hide_cursor
      app.tput.cursor_pos 0, 0
      app.tput.put(&.ena_acs?) # enable_acs

      alloc
    end

    # Allocates window buffers (a new pending/staging buffer and a new output buffer).
    def alloc(dirty = false)
      # Initialize @lines better than this.
      rows.times do |i|
        col = Row.new
        columns.times do
          col.push Cell.new
        end
        @lines.push col
        @lines[-1].dirty = dirty
      end

      # Initialize @lines better than this.
      rows.times do |i|
        col = Row.new
        columns.times do
          col.push Cell.new
        end
        @olines.push col
        @olines[-1].dirty = dirty
      end

      app.tput.clear
    end

    # Reallocates window buffers and clear the window.
    def realloc
      alloc dirty: true
    end

    def leave
      # TODO make it possible to work without switching the whole
      # app to alt buffer. (Same note as in `enter`).
      return unless app.tput.is_alt

      app.tput.put(&.keypad_local?)

      if (app.tput.scroll_top != 0) || (app.tput.scroll_bottom != height - 1)
        app.tput.set_scroll_region(0, app.tput.screen.height - 1)
      end

      # XXX For some reason if alloc/clear() is before this
      # line, it doesn't work on linux console.
      app.tput.show_cursor
      alloc

      # TODO Enable all in this function
      # if (this._listened_mouse)
      #  app.disable_mouse
      # end

      app.tput.normal_buffer
      if cursor._set
        app.tput.cursor_reset
      end

      app.tput.flush

      # :-)
      {% if flag? :windows %}
        `cls`
      {% end %}
    end

    # Debug helpers/setup
    def post_enter
    end

    # Returns current window width.
    # XXX Remove in favor of other ways to retrieve it.
    def columns
      # XXX replace with a per-window method
      app.tput.screen.width
    end

    # Returns current window height.
    # XXX Remove in favor of other ways to retrieve it.
    def rows
      # XXX replace with a per-window method
      app.tput.screen.height
    end

    # Returns current window width.
    # XXX Remove in favor of other ways to retrieve it.
    def width
      columns
    end

    # Returns current window height.
    # XXX Remove in favor of other ways to retrieve it.
    def height
      rows
    end

    def _get_pos
      self
    end

    ##### Unused parts: just compatibility with `Widget` interface.
    def clear_pos
    end

    property border : Border?

    # Inner/content positions:
    # XXX Remove when possible
    property ileft = 0
    property itop = 0
    property iright = 0
    property ibottom = 0
    #property iwidth = 0
    #property iheight = 0

    # Relative positions are the default and are aliased to the
    # left/top/right/bottom methods.
    getter rleft = 0
    getter rtop = 0
    getter rright = 0
    getter rbottom = 0
    # And these are the absolute ones; they're also 0.
    getter aleft = 0
    getter atop = 0
    getter aright = 0
    getter abottom = 0

    property overflow = Overflow::Ignore

    ##### End of unused parts.

    def hidden?
      false
    end

    def child_base
      0
    end

    # XXX for now, this just forwards to parent. But in reality,
    # it should be able to have its own title, and when it goes
    # in/out of focus, that title should be set/restored.
    def title
      @app.title
    end

    def title=(arg)
      @app.title = arg
    end

    def sigtstp(callback)
      app.sigtstp {
        alloc
        render
        app.lrestore_cursor :pause, true
        callback.call if callback
      }
    end
  end
end