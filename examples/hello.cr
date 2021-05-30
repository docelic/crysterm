require "../src/crysterm"

class MyProg
  include Crysterm

  # `Screen` is a phyiscal device (terminal screen).
  # It can be instantiated manually as shown, or for quick coding it can be
  # skipped and it will be created automatically when needed.
  s = Screen.new

  # `Window` is a full-screen surface which contains visual elements (Widgets),
  # on which graphics is rendered, and which is then drawn onto the terminal.
  # An app can have multiple screens, but only one can be showing at a time.
  w = Window.new screen: s

  # `Box` is one of the available widgets. It is a read-only space for
  # displaying text etc. In Qt terms, this is a Label.
  b = Widget::Box.new \
    name: "helloworld box", # Symbolic name
    top: "center",          # Can also be 10, "50%", or "50%-10"
    left: "center",         # Same as above
    width: 20,              # ditto
    height: 5,              # ditto
    content: "{center}'Hello {bold}world{/bold}!'\nPress q to quit.{/center}",
    parse_tags: true, # Parse {} tags within content (default already is true)
    style: Style.new(fg: "yellow", bg: "blue"),
    border: true # Can be styled, or 'true' for default look

    # Add box to the Window, because it is a top-level widget without a parent.
    # If there is a parent, you would call `Widget#append` on the parent object,
    # not on the window.
  w.append b

  b.focus

  # # Just for show, display the cursor, and later move its position along with
  # # the position of the created box.
  # s.tput.show_cursor
  # s.tput.cursor_shape Tput::CursorShape::Block, blink: true
  # s.tput.cursor_color Tput::Color::Goldenrod1

  # When q is pressed, exit the demo.
  s.on(Event::KeyPress) do |e|
    if e.char == 'q'
      exit
    end
  end

  spawn do
    loop do
      sleep 2
      b.rtop = rand(w.height - b.height - 1) + 1
      b.rleft = rand(w.width - b.width)

      # s.tput.cursor_pos b.top, b.left + b.width//2

      w.render
    end
  end

  s.exec
end