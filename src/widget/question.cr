require "./node"
require "./element"
require "./box"

module Crysterm
  module Widget
    # Question element
    class Question < Box
      property text : String = ""

      @hidden = true

      # TODO Positioning is bad for buttons.
      # Use a layout for buttons.
      # Also, make unlimited number of buttons/choices possible.

      @ok = Button.new(
        left: 1,
        top: 4,
        width: 6,
        height: 1,
        resizable: true,
        content: "Okay",
        align: AlignFlag::Center,
        # bg: "black",
        # hover_bg: "blue",
        auto_focus: false,
              # mouse: true
)

      @cancel = Button.new(
        left: 8,
        top: 4,
        width: 8,
        height: 1,
        resizable: true,
        content: "Cancel",
        align: AlignFlag::Center,
        # bg: "black",
        # hover_bg: "blue",
        auto_focus: false,
              # mouse: true
)

      def initialize(**box)
        box["content"]?.try do |c|
          @text = c
        end

        super **box

        # Should not be needed when ivar exists already set
        #@hidden = box["hidden"]?.nil? ? true : box["hidden"]? || false

        append @ok
        append @cancel
      end

      def ask(text = nil, &block : String?, Bool -> Nil)
        # D O:
        # Keep above:
        # @parent.try do |p|
        #   detach
        #   p.append self
        # end

        set_content text || @text
        show

        done = uninitialized String?, Bool -> Nil

        ev_keys = @screen.on(KeyPressEvent) do |e|
          # if (e.key == 'mouse')
          #  return
          # end
          c = e.char
          k = e.key

          if (k != Tput::Key::Enter && k != Tput::Key::Escape && c != 'q' && c != 'y' && c != 'n')
            next
          end

          done.call nil, k == Tput::Key::Enter || e.char == 'y'
        end

        ev_ok = @ok.on(PressEvent) do
          done.call nil, true
        end

        ev_cancel = @cancel.on(PressEvent) do
          done.call nil, false
        end

        @screen.save_focus
        focus

        done = ->(err : String?, data : Bool) do
          hide
          @screen.restore_focus
          @screen.off KeyPressEvent, ev_keys
          @ok.off PressEvent, ev_ok
          @cancel.off PressEvent, ev_cancel
          block.call err, data
          @screen.render
        end

        @screen.render
      end
    end
  end
end
