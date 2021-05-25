require "../src/crysterm"

# For reproducibility, the section near the end generating 10 widgets has been
# changed to always use fixed sizes instead of Random. The patch for Blessed's
# test file to get the same behavior is in file widget-layout.cr.blessed-patch.

module Crysterm
  include Crysterm::Widget # Just for convenience, to not have to write e.g. `Widget::Screen`

  s = Screen.new optimization: OptimizationFlag::SmartCSR #, auto_padding: true # auto padding is true in Crysterm by default

  l = layout = Layout.new(
    screen: s,
    top: "center",
    left: "center",
    width: "50%",
    height: "50%",
    border: BorderType::Line,
    layout: ARGV[0]? == "grid" ? LayoutType::Grid : LayoutType::Inline,
    overflow: Overflow::Ignore, # Setting not existing in Blessed. Controls what to do when widget is overflowina available space. Value of 'ignore' ignores the issue and renders such widgets overflown.
    style: Style.new(
      bg: "red",
      border: Style.new(
        fg: "blue"
      )
    )
  )

  box1 = Box.new(
    parent: layout,
    top: "center",
    left: "center",
    width: 20,
    height: 10,
    border: BorderType::Line,
    content: "1"
  )

  box2 = Box.new(
    parent: layout,
    top: 0,
    left: 0,
    width: 10,
    height: 5,
    border: BorderType::Line,
    content: "2"
  )

  box3 = Box.new(
    parent: layout,
    top: 0,
    left: 0,
    width: 10,
    height: 5,
    border: BorderType::Line,
    content: "3"
  )

  box4 = Box.new(
    parent: layout,
    top: 0,
    left: 0,
    width: 10,
    height: 5,
    border: BorderType::Line,
    content: "4"
  )

  box5 = Box.new(
    parent: layout,
    top: 0,
    left: 0,
    width: 10,
    height: 5,
    border: BorderType::Line,
    content: "5"
  )

  box6 = Box.new(
    parent: layout,
    top: 0,
    left: 0,
    width: 10,
    height: 5,
    border: BorderType::Line,
    content: "6"
  )

  box7 = Box.new(
    parent: layout,
    top: 0,
    left: 0,
    width: 10,
    height: 5,
    border: BorderType::Line,
    content: "7"
  )

  box8 = Box.new(
    parent: layout,
    top: "center",
    left: "center",
    width: 20,
    height: 10,
    border: BorderType::Line,
    content: "8"
  )

  box9 = Box.new(
    parent: layout,
    top: 0,
    left: 0,
    width: 10,
    height: 5,
    border: BorderType::Line,
    content: "9"
  )

  box10 = Box.new(
    parent: layout,
    top: "center",
    left: "center",
    width: 20,
    height: 10,
    border: BorderType::Line,
    content: "10"
  )

  box11 = Box.new(
    parent: layout,
    top: 0,
    left: 0,
    width: 10,
    height: 5,
    border: BorderType::Line,
    content: "11"
  )

  box12 = Box.new(
    parent: layout,
    top: "center",
    left: "center",
    width: 20,
    height: 10,
    border: BorderType::Line,
    content: "12"
  )

  if ARGV[0]? != "grid"
    sizes = [ 0.2, 1, 0.3, 0.6, 0.3, 0.9, 0.2, 0.75, 0.1, 0.99 ]
    10.times do |i|
       b = Box.new(
          parent: layout,
          width: sizes[i] > 0.5 ? 10 : 20,
          height: sizes[i] > 0.5 ? 5 : 10,
          border: Crysterm::BorderType::Line,
          content: (i + 1 + 12).to_s
       )
    end
  end

 s.on(Event::KeyPress) do |e|
   #STDERR.puts e.inspect
   if e.char == 'q'
     #e.accept!
     s.destroy
     exit
   end
 end

 s.render

 s.app.exec
end
